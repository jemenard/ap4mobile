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
    print('🚀 [API] getFestivals: START (isLoggedIn=$isLoggedIn, isAdmin=$isAdmin, userId=$userId)');
    try {
      String url = Config.apiUrlFestivals;
      bool useStaffEndpoint = false;
      
      if (isAdmin) {
        if (userId == null) {
          print('🛑 [API] getFestivals: isAdmin=true mais userId=null');
          return []; 
        }
        url = "${Config.apiUrlStaff}/$userId/festivals";
        useStaffEndpoint = true;
      }

      print('🚀 [API] getFestivals: Requesting URL=$url');
      final headers = {
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };
      print('🚀 [API] getFestivals: Headers=$headers');
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      print('🚀 [API] getFestivals: StatusCode=${response.statusCode}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        print('✅ [API] getFestivals: SUCCESS');
        
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
        print('DatabaseService.getFestivals: FAILED (StatusCode=${response.statusCode}, Body=${response.body})');
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

  /// Récupère le festival actuellement en cours.
  Future<Festival?> getActiveFestival() async {
    try {
      final festivals = await getFestivals();
      final now = DateTime.now();
      
      // On cherche un festival dont les dates englobent 'maintenant'
      for (var f in festivals) {
        if ((f.startDate.isBefore(now) || f.startDate.isAtSameMomentAs(now)) && 
            (f.endDate.isAfter(now) || f.endDate.isAtSameMomentAs(now))) {
          return f;
        }
      }
      // Si aucun en cours, on prend le plus proche à venir
      if (festivals.isNotEmpty) return festivals.first;
      return null;
    } catch (e) {
      print('DatabaseService.getActiveFestival Error: $e');
      return null;
    }
  }

  /// Calcule les statistiques de remplissage pour un festival.
  /// Retourne une Map { 'validated': int, 'total': int }
  Future<Map<String, int>> getFestivalStats(int festivalId) async {
    try {
      // 1. Récupérer les manifestations pour la jauge totale
      final manifs = await getManifestations(festivalId);
      int totalCapacity = 0;
      for (var m in manifs) {
        totalCapacity += int.tryParse(m.jaugeMax) ?? 0;
      }

      // 2. Récupérer toutes les réservations du festival pour compter les validés
      // On utilise l'endpoint existant si possible ou on filtre
      // Ici on va charger les manifestations détaillées pour avoir leurs réservations
      int validatedCount = 0;
      
      // Note: Idéalement le backend devrait fournir un endpoint /stats/{festivalId}
      // En attendant, on itère sur les manifestations (attention aux perfs)
      for (var m in manifs) {
        try {
          print('📈 [Stats] Chargement détails pour manifestation ID: ${m.id}');
          final detail = await getManifestationDetails(m.id);
          if (detail.reservations != null) {
            print('📈 [Stats] ${detail.reservations!.length} réservations trouvées pour manif ID: ${m.id}');
            for (var res in detail.reservations!) {
              // On accepte '2' ou 2 (string ou int) pour la validation
              final status = res['Id_Statut']?.toString();
              if (status == '2') {
                 validatedCount++;
              }
            }
          }
        } catch (e) {
          print('⚠️ [Stats] Impossible de charger les détails de la manif ${m.id}: $e');
          // On continue pour les autres manifestations
        }
      }

      return {
        'validated': validatedCount,
        'total': totalCapacity,
      };
    } catch (e) {
      print('DatabaseService.getFestivalStats Error: $e');
      return {'validated': 0, 'total': 0};
    }
  }

  /// Récupère les manifestations liées à un festival spécifique.
  Future<List<Manifestation>> getManifestations(int festivalId) async {
    print('🚀 [API] getManifestations: START (festivalId=$festivalId)');
    final url = "${Config.apiUrlManifestations}/$festivalId/manifestations";
    try {
      print('🚀 [API] getManifestations: Requesting URL=$url');
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
      );
      print('🚀 [API] getManifestations: StatusCode=${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final List<dynamic> body = jsonResponse['data'];
        print('✅ [API] getManifestations: SUCCESS');
        
        // Structure API attendue : {"data": [{"manifestation": {...}}, ...]}
        return body.map((item) => Manifestation.fromMap(item['manifestation'])).toList();
      } else if (response.statusCode == 404) {
        print('⚠️ [API] getManifestations: No manifestations found (404)');
        return [];
      } else {
        print('🛑 [API] getManifestations: FAILED (StatusCode=${response.statusCode}, Body=${response.body})');
        throw "Erreur serveur : ${response.statusCode}";
      }
    } catch (e) {
      print('DatabaseService.getManifestations Error: $e');
      rethrow;
    }
  }

  /// Récupère le détail complet d'une manifestation (sessions, lieux, etc).
  Future<Manifestation> getManifestationDetails(int manifestationId) async {
    print('🚀 [API] getManifestationDetails: START (manifId=$manifestationId)');
    final url = "${Config.apiUrlDetailManifestations}/$manifestationId";
    try {
      print('🚀 [API] getManifestationDetails: Requesting URL=$url');
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
      );
      print('🚀 [API] getManifestationDetails: StatusCode=${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        print('✅ [API] getManifestationDetails: SUCCESS');
        return Manifestation.fromDetailMap(jsonResponse['data']);
      } else if (response.statusCode == 404) {
        print('⚠️ [API] getManifestationDetails: Not found (404)');
        // On renvoie un objet vide ou on gère l'erreur plus haut
        throw "Manifestation non trouvée"; 
      } else {
        print('🛑 [API] getManifestationDetails: FAILED (StatusCode=${response.statusCode}, Body=${response.body})');
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
    print('🚀 [API] connexion: START');
    try {
      final url = Config.apiUrlConnexion;
      print('🚀 [API] connexion: URL=$url');
      final response = await http.post(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
        body: {'email': email, 'password': mdp},
      );
      print('🚀 [API] connexion: StatusCode=${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        print('🚀 [API] Connexion (User) ResponseBody=${response.body}');
        
        userId = _findId(jsonResponse);
        
        // Récupération du Bearer Token (cherche 'token' ou 'access_token' récursivement)
        _token = jsonResponse['token']?.toString() ?? 
                 jsonResponse['data']?['token']?.toString() ??
                 jsonResponse['access_token']?.toString();
        
        print('✅ [API] Token trouvé: ${_token != null}');

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

  /// Déconnexion sécurisée.
  void deconnexion() {
    isLoggedIn = false;
    isAdmin = false;
    userId = null;
    userNom = null;
    userPrenom = null;
    userEmail = null;
    _token = null;
    print('✅ [Auth] Déconnexion réussie');
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
    print('🚀 [API] connexionStaff: START');
    try {
      final url = Config.apiUrlConnexionStaff;
      print('🚀 [API] connexionStaff: URL=$url');
      final response = await http.post(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
        body: {'email': email, 'password': mdp},
      );
      print('🚀 [API] connexionStaff: StatusCode=${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        
        isAdmin = true; // Forcé dès le début du succès
        isLoggedIn = true;
        userId = _findId(jsonResponse);
        
        print('✅ [API] Connexion Staff réussie, userId=$userId');
        
        // On cherche les données utilisateur pour le nom/prenom/email
        final userData = jsonResponse['user'] ?? jsonResponse['data'] ?? jsonResponse['staff'] ?? jsonResponse;
        
        // Récupération du token si présent
        _token = jsonResponse['token']?.toString() ?? 
                 jsonResponse['data']?['token']?.toString() ??
                 jsonResponse['access_token']?.toString();
        
        print('✅ [API] Token Staff trouvé: ${_token != null}');

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
        print('DatabaseService.getUserTickets: FAILED (StatusCode=${response.statusCode}, Body=${response.body})');
        throw "Erreur récupération tickets (${response.statusCode})";
      }
    } catch (e) {
      print('DatabaseService.getUserTickets Error: $e');
      return [];
    }
  }

  /// Crée une nouvelle réservation sur le serveur.
  /// Lance une exception en cas d'erreur avec un message descriptif.
  Future<int?> reserverTicket({
    required int festivalId,
    int? manifestationId,
    required String type,
    required double prix,
  }) async {
    if (userId == null) throw "Utilisateur non connecté";

    final url = Config.apiUrlReserver;
    final bodyData = {
      'Id_Utilisateur': userId,
      'id_festival': manifestationId == null ? festivalId : null,
      'Id_Manifestation': manifestationId,
      'mode_obtention': 'en_ligne',
      'type_billet': type,
      'prix_payer': prix,
    };

    print('DatabaseService.reserverTicket: START');
    print('DatabaseService.reserverTicket: URL=$url');
    print('DatabaseService.reserverTicket: Body=${jsonEncode(bodyData)}');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
        body: jsonEncode(bodyData),
      );

      print('DatabaseService.reserverTicket: StatusCode=${response.statusCode}');
      print('DatabaseService.reserverTicket: ResponseBody=${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final data = json['data'] ?? json;
        final resId = int.tryParse((data['Id_Reservation'] ?? data['id']).toString());
        print('DatabaseService.reserverTicket: SUCCESS, ReservationID=$resId');
        return resId;
      } else {
        final errorMsg = _handleApiError(response);
        print('DatabaseService.reserverTicket: API error: $errorMsg');
        throw errorMsg;
      }
    } catch (e) {
      print('DatabaseService.reserverTicket: EXCEPTION: $e');
      rethrow;
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
