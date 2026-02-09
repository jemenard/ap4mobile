import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/festival.dart';
import '../models/manifestation.dart';
import '../models/ticket.dart';
import '../models/news.dart';
import '../models/comment.dart';
import '../config.dart';

/// Service central gérant les communications avec l'API backend.
/// Utilise le design pattern Singleton pour assurer une instance unique dans toute l'app.
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();

  factory DatabaseService() => _instance;

  DatabaseService._internal();
  
  // État de l'authentification
  bool isLoggedIn = false;
  bool isAdmin = false;

  // Données de l'utilisateur connecté
  int? userId;
  String? userNom;
  String? userPrenom;
  String? userEmail;
  String? _token;

  /// Récupère la liste des festivals actifs/futurs.
  /// Si l'utilisateur est Staff, on ne récupère que ceux qui lui sont assignés.
  Future<List<Festival>> getFestivals() async {
    print('DatabaseService.getFestivals: START (isLoggedIn=$isLoggedIn, isAdmin=$isAdmin, userId=$userId)');
    try {
      String url = Config.apiUrlFestivals;
      bool useStaffEndpoint = false;
      
      // Si Staff connecté, on utilise EXCLUSIVEMENT l'endpoint staff
      if (isAdmin) {
        if (userId == null) {
          print('DatabaseService.getFestivals: isAdmin=true mais userId=null -> retour []');
          return []; 
        }
        url = "${Config.apiUrlStaff}/$userId/festivals";
        useStaffEndpoint = true;
      }

      print('DatabaseService.getFestivals: Requesting URL=$url');
      final response = await http.get(Uri.parse(url));
      print('DatabaseService.getFestivals: URL=$url, StatusCode=${response.statusCode}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        // print('DatabaseService.getFestivals: ResponseBody=${response.body}');
        
        // La structure peut varier : json['data'], json['festivals'], ou json directement
        dynamic rawData = jsonResponse['data'] ?? jsonResponse['festivals'] ?? jsonResponse;
        
        List<dynamic> body = [];
        if (rawData is List) {
          body = rawData;
        } else if (rawData is Map && rawData.containsKey('festivals') && rawData['festivals'] is List) {
          body = rawData['festivals'];
        } else if (rawData is Map && rawData.containsKey('data') && rawData['data'] is List) {
          body = rawData['data'];
        }

        final festivals = body.map((item) {
          // Si Laravel renvoie une relation Many-to-Many, le festival peut être dans item['festival']
          if (item is Map) {
            final Map<String, dynamic> data = Map<String, dynamic>.from(
              item.containsKey('festival') ? item['festival'] : item
            );
            return Festival.fromMap(data);
          }
          return null;
        }).whereType<Festival>().toList();
        
        print('DatabaseService.getFestivals: Found ${festivals.length} festivals before temporal filtering');

        // Filtrage temporel
        final today = DateTime.now();
        final startOfToday = DateTime(today.year, today.month, today.day);
        
        final filtered = festivals.where((f) => 
          f.endDate.isAfter(startOfToday) || f.endDate.isAtSameMomentAs(startOfToday)
        ).toList();
        
        print('DatabaseService.getFestivals: Returning ${filtered.length} festivals');
        return filtered;
      } else if (useStaffEndpoint && (response.statusCode == 404 || response.statusCode == 200)) {
        print('DatabaseService.getFestivals: Staff endpoint returned empty (404/200)');
        return [];
      } else {
        throw "Erreur serveur (${response.statusCode}) pour l'URL: $url";
      }
    } catch (e) {
      print('DatabaseService.getFestivals: ERROR: $e');
      if (isAdmin) return [];
      rethrow;
    }
  }

  /// Vérifie si un festival se déroule actuellement.
  Future<bool> isFestivalActive() async {
    try {
      final festivals = await getFestivals();
      final now = DateTime.now();
      
      return festivals.any((f) => 
        (f.startDate.isBefore(now) || f.startDate.isAtSameMomentAs(now)) && 
        (f.endDate.isAfter(now) || f.endDate.isAtSameMomentAs(now))
      );
    } catch (e) {
      return false;
    }
  }

  /// Récupère les manifestations liées à un festival spécifique.
  Future<List<Manifestation>> getManifestations(int festivalId) async {
    final url = "${Config.apiUrlManifestations}/$festivalId/manifestations";
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final List<dynamic> body = jsonResponse['data'];
        
        // Structure API attendue : {"data": [{"manifestation": {...}}, ...]}
        return body.map((item) => Manifestation.fromMap(item['manifestation'])).toList();
      } else {
        throw "Erreur serveur : ${response.statusCode}";
      }
    } catch (e) {
      print('DatabaseService.getManifestations Error: $e');
      rethrow;
    }
  }

  /// Récupère le détail complet d'une manifestation (sessions, lieux, etc).
  Future<Manifestation> getManifestationDetails(int manifestationId) async {
    final url = "${Config.apiUrlDetailManifestations}/$manifestationId";
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        return Manifestation.fromDetailMap(jsonResponse['data']);
      } else {
        throw "Erreur serveur : ${response.statusCode}";
      }
    } catch (e) {
      print('DatabaseService.getManifestationDetails Error: $e');
      rethrow;
    }
  }

  /// Tente de trouver un identifiant (Staff ou Utilisateur) dans une Map, récursivement.
  int? _findId(dynamic data) {
    if (data == null) return null;
    if (data is Map) {
      // Priorité aux clés Staff
      final rawId = data['Id_Staff'] ?? data['id_staff'] ?? 
                    data['Id_Utilisateur'] ?? data['id_utilisateur'] ?? 
                    data['id'];
      if (rawId != null) return int.tryParse(rawId.toString());
      
      // Sinon on cherche dans les sous-objets (ex: 'user', 'data', 'staff')
      for (var value in data.values) {
        final found = _findId(value);
        if (found != null) return found;
      }
    } else if (data is List) {
      for (var item in data) {
        final found = _findId(item);
        if (found != null) return found;
      }
    }
    return null;
  }

  /// Authentification de l'utilisateur.
  /// NOTE: En production, utilisez impérativement HTTPS pour protéger les identifiants.
  Future<bool> connexion(String email, String mdp) async {
    try {
      final response = await http.post(
        Uri.parse(Config.apiUrlConnexion),
        headers: {'Accept': 'application/json'},
        body: {'email': email, 'password': mdp},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        print('DatabaseService: Connexion (User) ResponseBody=${response.body}');
        
        userId = _findId(jsonResponse);
        
        // Récupération du Bearer Token
        if (jsonResponse.containsKey('token')) {
          _token = jsonResponse['token'].toString();
        }

        if (userId != null) {
          final userData = jsonResponse['user'] ?? jsonResponse['data'] ?? jsonResponse;
          userNom = userData['nom']?.toString() ?? userData['Nom']?.toString();
          userPrenom = userData['prenom']?.toString() ?? userData['Prenom']?.toString();
          userEmail = userData['email']?.toString() ?? userData['Email']?.toString() ?? email;
          
          isLoggedIn = true;
          
          // Détection automatique du rôle Staff/Admin
          final roleVal = userData['role'] ?? userData['Role'];
          if (roleVal != null) {
            int? role = int.tryParse(roleVal.toString());
            isAdmin = (role == 1 || role == 3);
          } else {
            isAdmin = false;
          }
          print('DatabaseService: Connexion réussie, userId=$userId, isAdmin=$isAdmin');
          return true;
        }
        return false;
      } else {
        throw _handleApiError(response);
      }
    } catch (e) {
      print('DatabaseService.connexion Error: $e');
      rethrow;
    }
  }

  /// Inscription d'un nouvel utilisateur.
  Future<bool> inscription({
    required String nom,
    required String prenom,
    required String email,
    required String telephone,
    required String mdp,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(Config.apiUrlInscription),
        headers: {'Accept': 'application/json'},
        body: {
          'nom': nom,
          'prenom': prenom,
          'email': email,
          'telephone': telephone,
          'mdp': mdp,
        },
      );

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body);
        
        // Tentative d'auto-connexion après inscription
        if (json.containsKey('data') && json['data']['Id_Utilisateur'] != null) {
          userId = int.tryParse(json['data']['Id_Utilisateur'].toString());
        }

        userNom = nom;
        userPrenom = prenom;
        userEmail = email;
        isLoggedIn = true;
        isAdmin = false;
        return true;
      } else {
        throw _handleApiError(response);
      }
    } catch (e) {
      print('DatabaseService.inscription Error: $e');
      rethrow;
    }
  }

  /// Authentification pour le personnel (Staff/Admin).
  Future<bool> connexionStaff(String email, String mdp) async {
    try {
      final response = await http.post(
        Uri.parse(Config.apiUrlConnexionStaff),
        headers: {'Accept': 'application/json'},
        body: {'email': email, 'password': mdp},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        
        isAdmin = true; // Forcé dès le début du succès
        isLoggedIn = true;
        userId = _findId(jsonResponse);
        
        print('DatabaseService: Connexion Staff réussie, userId=$userId, isAdmin=$isAdmin');
        
        // On cherche les données utilisateur pour le nom/prenom/email
        final userData = jsonResponse['user'] ?? jsonResponse['data'] ?? jsonResponse['staff'] ?? jsonResponse;
        
        // Récupération du token si présent
        if (jsonResponse.containsKey('token')) {
          _token = jsonResponse['token'].toString();
        }

        userNom = userData['nom']?.toString() ?? userData['Nom']?.toString();
        userPrenom = userData['prenom']?.toString() ?? userData['Prenom']?.toString();
        userEmail = userData['email']?.toString() ?? userData['Email']?.toString() ?? email;

        return true;
      } else {
        throw _handleApiError(response);
      }
    } catch (e) {
      print('DatabaseService.connexionStaff Error: $e');
      rethrow;
    }
  }

  /// Déconnexion : réinitialise l'état local.
  void deconnexion() {
    isLoggedIn = false;
    isAdmin = false;
    userId = null;
    userNom = null;
    userPrenom = null;
    userEmail = null;
    _token = null;
  }

  /// Récupère toutes les réservations de l'utilisateur connecté.
  /// NOTE: Le backend devrait vérifier que le token fourni correspond au userId demandé.
  Future<List<Ticket>> getUserTickets() async {
    if (userId == null) return [];
    
    final url = "${Config.apiUrlReservations}/$userId";
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final List<dynamic> reservations = jsonResponse['data'] ?? [];
        return reservations.map((res) => Ticket.fromMap(res)).toList();
      } else if (response.statusCode == 404) {
        return []; // Pas de billets trouvés
      } else {
        throw "Erreur récupération tickets (${response.statusCode})";
      }
    } catch (e) {
      print('DatabaseService.getUserTickets Error: $e');
      return [];
    }
  }

  /// Crée une nouvelle réservation sur le serveur.
  /// Retourne l'ID de la réservation si succès, null sinon.
  Future<int?> reserverTicket({
    required int festivalId,
    int? manifestationId,
    required String type,
    required double prix,
  }) async {
    if (userId == null) return null;

    try {
      final bodyData = {
        'Id_Utilisateur': userId,
        'id_festival': manifestationId == null ? festivalId : null,
        'Id_Manifestation': manifestationId,
        'mode_obtention': 'en_ligne',
        'type_billet': type,
        'prix_paye': prix,
      };

      final response = await http.post(
        Uri.parse(Config.apiUrlReserver),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
        body: jsonEncode(bodyData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final json = jsonDecode(response.body);
        // Extraction de l'ID selon la structure retournée (data.id ou Id_Reservation)
        final data = json['data'] ?? json;
        return int.tryParse((data['Id_Reservation'] ?? data['id']).toString());
      }
      return null;
    } catch (e) {
      print('DatabaseService.reserverTicket Error: $e');
      return null;
    }
  }

  /// Récupère les données du QR Code pour une réservation spécifique.
  Future<String?> getQrCode(int reservationId) async {
    final url = "${Config.apiUrlQrCode}/$reservationId/qrcode";
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        return jsonResponse['qr_code']?.toString();
      }
      return null;
    } catch (e) {
      print('DatabaseService.getQrCode Error: $e');
      return null;
    }
  }

  /// Annule une réservation existante.
  Future<bool> annulerReservation(int reservationId) async {
    final url = "${Config.apiUrlQrCode}/$reservationId";
    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
      );

      return (response.statusCode == 200);
    } catch (e) {
      print('DatabaseService.annulerReservation Error: $e');
      return false;
    }
  }

  /// Compte le nombre de billets déjà réservés par l'utilisateur pour un festival ou une manifestation.
  /// Utile pour vérifier la limite de 4 billets par événement.
  Future<int> getTicketsCount(int festivalId, {int? manifestationId}) async {
    final tickets = await getUserTickets();
    
    // On ne compte que les tickets qui ne sont pas annulés
    final activeTickets = tickets.where((t) => !t.isCancelled);

    if (manifestationId != null) {
      // Filtrage par manifestation spécifique
      return activeTickets.where((t) => t.manifestationId == manifestationId).length;
    } else {
      // Filtrage par festival (Pass Festival uniquement, donc manifestationId doit être null dans le ticket)
      return activeTickets.where((t) => 
        t.festivalId == festivalId && t.manifestationId == null
      ).length;
    }
  }

  /// Envoie un e-mail de confirmation pour une réservation réussie.
  Future<bool> sendConfirmationEmail(int reservationId) async {
    if (userEmail == null) return false;

    try {
      final response = await http.post(
        Uri.parse(Config.apiUrlSendEmail),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          'reservation_id': reservationId,
          'email': userEmail,
          'nom': userNom,
          'prenom': userPrenom,
        }),
      );

      return (response.statusCode == 200 || response.statusCode == 201);
    } catch (e) {
      print('DatabaseService.sendConfirmationEmail Error: $e');
      return false;
    }
  }

  /// Récupère la liste des actualités.
  Future<List<News>> getNews() async {
    try {
      final response = await http.get(Uri.parse(Config.apiUrlNews));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final List<dynamic> body = jsonResponse['data'];
        return body.map((item) => News.fromMap(item)).toList();
      } else {
        throw "Erreur récupération actualités (${response.statusCode})";
      }
    } catch (e) {
      print('DatabaseService.getNews Error: $e');
      return [];
    }
  }

  /// Récupère le détail d'une actualité spécifique.
  Future<News?> getNewsDetail(int newsId) async {
    final url = "${Config.apiUrlNewsDetail}/$newsId";
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        return News.fromMap(jsonResponse['data']);
      }
      return null;
    } catch (e) {
      print('DatabaseService.getNewsDetail Error: $e');
      return null;
    }
  }

  /// Récupère la liste des commentaires pour une manifestation.
  Future<List<Comment>> getCommentaires(int manifestationId) async {
    final url = "${Config.apiUrlCommentaires}/$manifestationId/commentaires";
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final List<dynamic> body = jsonResponse['data'];
        return body.map((item) => Comment.fromMap(item)).toList();
      } else if (response.statusCode == 404) {
        return []; // Pas de commentaires trouvés
      } else {
        throw "Erreur récupération commentaires (${response.statusCode})";
      }
    } catch (e) {
      print('DatabaseService.getCommentaires Error: $e');
      return [];
    }
  }

  /// Extrait le message d'erreur d'une réponse API si possible.
  String _handleApiError(http.Response response) {
    try {
      final json = jsonDecode(response.body);
      // Différents formats d'erreur possibles selon l'API
      return json['message']?.toString() ?? 
             json['error']?.toString() ?? 
             "Erreur serveur (${response.statusCode})";
    } catch (_) {
      return "Erreur réseau ou serveur (${response.statusCode})";
    }
  }
}
