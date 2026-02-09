import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/festival.dart';
import '../models/manifestation.dart';
import '../models/ticket.dart';
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
  Future<List<Festival>> getFestivals() async {
    try {
      final response = await http.get(Uri.parse(Config.apiUrlFestivals));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final List<dynamic> body = jsonResponse['data'];
        
        final festivals = body.map((item) => Festival.fromMap(item)).toList();
        
        // Filtrage : on ne garde que les festivals qui ne sont pas encore terminés
        final today = DateTime.now();
        final startOfToday = DateTime(today.year, today.month, today.day);
        
        return festivals.where((f) => 
          f.endDate.isAfter(startOfToday) || f.endDate.isAtSameMomentAs(startOfToday)
        ).toList();
      } else {
        throw "Erreur serveur (${response.statusCode})";
      }
    } catch (e) {
      print('DatabaseService.getFestivals Error: $e');
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
        final Map<String, dynamic> json = jsonDecode(response.body);
        
        // Extraction de l'ID utilisateur (gestion de plusieurs formats possibles de l'API)
        final userData = json['user'] ?? json['data'] ?? json;
        userId = int.tryParse((userData['Id_Utilisateur'] ?? userData['id']).toString());
        
        // Récupération du Bearer Token pour les requêtes authentifiées suivantes
        if (json.containsKey('token')) {
          _token = json['token'].toString();
        }

        if (userId != null) {
          userNom = userData['nom']?.toString() ?? userData['Nom']?.toString();
          userPrenom = userData['prenom']?.toString() ?? userData['Prenom']?.toString();
          userEmail = userData['email']?.toString() ?? userData['Email']?.toString() ?? email;
          
          isLoggedIn = true;
          isAdmin = false; 
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
        final json = jsonDecode(response.body);
        
        if (json.containsKey('data') && json['data']['Id_Utilisateur'] != null) {
          userId = int.tryParse(json['data']['Id_Utilisateur'].toString());
        }

        if (json.containsKey('data')) {
          final userData = json['data'];
          userNom = userData['nom']?.toString() ?? userData['Nom']?.toString();
          userPrenom = userData['prenom']?.toString() ?? userData['Prenom']?.toString();
          userEmail = userData['email']?.toString() ?? userData['Email']?.toString() ?? email;
        }

        isLoggedIn = true;
        isAdmin = true;
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
