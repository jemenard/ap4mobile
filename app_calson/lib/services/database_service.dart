import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/festival.dart';
import '../models/manifestation.dart';
import '../models/ticket.dart';
import '../config.dart';

/// Service gérant les interactions avec l'API (récupération de données, authentification).
class DatabaseService {
  // Instance unique de la classe (Singleton) pour éviter de créer plusieurs connexions inutiles.
  static final DatabaseService _instance = DatabaseService._internal();

  factory DatabaseService() {
    return _instance;
  }

  // Constructeur privé utilisé par le Singleton.
  DatabaseService._internal();
  
  // Variable pour suivre si l'utilisateur est actuellement connecté.
  bool isLoggedIn = false;
  
  // Variable pour suivre si l'utilisateur est un administrateur.
  bool isAdmin = false;

  // Stocke l'ID de l'utilisateur connecté.
  int? userId;

  // Stocke le jeton d'authentification (Bearer Token)
  String? _token;

  /// Récupère la liste de tous les festivals depuis l'API.
  /// Retourne une liste d'objets [Festival].
  Future<List<Festival>> getFestivals() async {
    final url = Config.apiUrlFestivals;
    print('--- API REQUEST (getFestivals) ---');
    print('URL: $url');
    try {
      final response = await http.get(Uri.parse(url));
      print('Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        print('Response Body: ${response.body}');
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final List<dynamic> body = jsonResponse['data'];
        return body.map((dynamic item) => Festival.fromMap(item)).toList();
      } else {
        print('Error Body: ${response.body}');
        throw "Erreur serveur : ${response.statusCode}";
      }
    } catch (e) {
      print('!!! API Error !!! : $e');
      rethrow;
    } finally {
      print('--- END API REQUEST ---');
    }
  }

  /// Récupère la liste des manifestations pour un festival donné (via son id).
  /// Retourne une liste d'objets [Manifestation].
  Future<List<Manifestation>> getManifestations(int festivalId) async {

    
    final url = "${Config.apiUrlManifestations}/$festivalId/manifestations";
    print('--- API REQUEST (getManifestations) ---');
    print('URL: $url');
    try {
      final response = await http.get(Uri.parse(url));
      print('Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('Response Body: ${response.body}');
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final List<dynamic> body = jsonResponse['data'];
        // Parse la structure imbriquée {"manifestation": {...}}
        return body.map((dynamic item) {
          final manifestationData = item['manifestation'];
          return Manifestation.fromMap(manifestationData);
        }).toList();
      } else {
        print('Error Body: ${response.body}');
        throw "Erreur serveur : ${response.statusCode}";
      }
    } catch (e) {
      print('!!! API Error !!! : $e');
      rethrow;
    } finally {
      print('--- END API REQUEST ---');
    }
  }

  /// Récupère les détails complets d'une manifestation (avec session, lieu, réservations)
  Future<Manifestation> getManifestationDetails(int manifestationId) async {
    final url = "${Config.apiUrlDetailManifestations}/$manifestationId";
    print('--- API REQUEST (getManifestationDetails) ---');
    print('URL: $url');
    try {
      final response = await http.get(Uri.parse(url));
      print('Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('Response Body: ${response.body}');
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        return Manifestation.fromDetailMap(jsonResponse['data']);
      } else {
        print('Error Body: ${response.body}');
        throw "Erreur serveur : ${response.statusCode}";
      }
    } catch (e) {
      print('!!! API Error !!! : $e');
      rethrow;
    } finally {
      print('--- END API REQUEST ---');
    }
  }

  /// Tente de connecter un utilisateur avec son email et mot de passe.
  /// Retourne `true` si la connexion est réussie, sinon lève une erreur.
  Future<bool> connexion(String email, String mdp) async {
    final url = Config.apiUrlConnexion;
    print('--- API REQUEST (connexion) ---');
    print('URL: $url');
    try 
    {
      final response = await http.post(
        Uri.parse(url),
        headers:
        {
          // Indique au serveur que l'application attend une réponse au format JSON.
          // C'est nécessaire pour éviter des erreurs de format ou des redirections inattendues.
          'Accept': 'application/json', 
        },
        body:
        {
          'email': email,
          'password': mdp,
        },
      );
      print('Status Code: ${response.statusCode}');
      if (response.statusCode == 200) {
        print('Response Body: ${response.body}');
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        
        // On suppose que l'ID est dans jsonResponse['user']['id'] ou jsonResponse['id']
        // À adapter selon le retour réel de ton API
        print('--- LOGIN PARSING DEBUG ---');
        print('jsonResponse keys: ${jsonResponse.keys}');
        if (jsonResponse.containsKey('user')) {
          final userData = jsonResponse['user'];
          print('Found "user" object: $userData');
          print('user["Id_Utilisateur"]: ${userData['Id_Utilisateur']} (Type: ${userData['Id_Utilisateur']?.runtimeType})');
          print('user["id"]: ${userData['id']} (Type: ${userData['id']?.runtimeType})');
          
          userId = int.tryParse(userData['Id_Utilisateur']?.toString() ?? userData['id']?.toString() ?? "");
          print('Resulting userId from "user": $userId');
        } else if (jsonResponse.containsKey('data')) {
          final data = jsonResponse['data'];
          print('Found "data" object: $data');
          userId = int.tryParse((data['Id_Utilisateur'] ?? data['id'] ?? "").toString());
          print('Resulting userId from "data": $userId');
        } else if (jsonResponse.containsKey('id')) {
          userId = int.tryParse(jsonResponse['id'].toString());
          print('Resulting userId from root "id": $userId');
        }

        if (jsonResponse.containsKey('token')) {
          _token = jsonResponse['token'].toString();
          print('Token extracted successfully');
        }

        print('--- END LOGIN PARSING DEBUG ---');
        if (userId != null) {
          isLoggedIn = true;
          isAdmin = false; 
          return true;
        } else {
          print('ERREUR : Login réussi mais ID utilisateur introuvable dans la réponse.');
          throw "Erreur de format de réponse (ID manquant)";
        }
      } else {
        print('Error Body: ${response.body}');
        throw "Erreur serveur : ${response.statusCode}";
      }
    } catch (e) {
      print('!!! API Error !!! : $e');
      rethrow;
    } finally {
      print('--- END API REQUEST ---');
    }
  }

  /// Inscrit un nouvel utilisateur avec les informations fournies.
  /// Connecte automatiquement l'utilisateur si l'inscription réussit.
  Future<bool> inscription
  ({
    required String nom,
    required String prenom,
    required String email,
    required String telephone,
    required String mdp,
  }) async {
    print('--- API REQUEST (inscription) ---');
    final url = Config.apiUrlInscription;
    print('URL: $url');
    try 
    {
      final bodyData = {
        'nom': nom,
        'prenom': prenom,
        'email': email,
        'telephone': telephone,
        'mdp': mdp,
      };
      print('Sending Registration Data: $bodyData');

      final response = await http.post(
        Uri.parse(url),
        headers:
        {
          // Indique au serveur que nous attendons du JSON en réponse.
          'Accept': 'application/json',
        },
        body: bodyData,
      );
      print('Status Code: ${response.statusCode}');
      if (response.statusCode == 201) {
        print('Response Body: ${response.body}');
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        
        if (jsonResponse.containsKey('data') && jsonResponse['data'] is Map && jsonResponse['data'].containsKey('Id_Utilisateur')) {
           userId = int.tryParse(jsonResponse['data']['Id_Utilisateur'].toString());
        }

        isLoggedIn = true;
        isAdmin = false;
        return true;
      } else {
        print('Error Body: ${response.body}');
        throw "Erreur serveur : ${response.statusCode}";
      }

      
    } catch (e) {
      print('!!! API Error !!! : $e');
      rethrow;
    } finally {
      print('--- END API REQUEST ---');
    }
  }

  /// Connexion pour le personnel staff avec endpoint dédié.
  Future<bool> connexionStaff(String email, String mdp) async {
    final url = Config.apiUrlConnexionStaff;
    print('--- API REQUEST (connexionStaff) ---');
    print('URL: $url');
    try {
      final bodyData = {
        'email': email,
        'password': mdp,
      };
      print('Sending Staff Login Data: $bodyData');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
        },
        body: bodyData,
      );
      print('Status Code: ${response.statusCode}');
      if (response.statusCode == 200) {
        print('Response Body: ${response.body}');
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        
        // Extraction de l'ID pour le staff si présent
        if (jsonResponse.containsKey('data') && jsonResponse['data'] is Map && jsonResponse['data'].containsKey('Id_Utilisateur')) {
           userId = int.tryParse(jsonResponse['data']['Id_Utilisateur'].toString());
        }

        isLoggedIn = true;
        isAdmin = true; // C'est un staff/admin
        return true;
      } else {
        print('Error Body: ${response.body}');
        throw "Erreur serveur : ${response.statusCode}";
      }
    } catch (e) {
      print('!!! API Error !!! : $e');
      rethrow;
    } finally {
      print('--- END API REQUEST ---');
    }
  }

  /// Déconnecte l'utilisateur localement.
  void deconnexion() {
    isLoggedIn = false;
    isAdmin = false;
    userId = null;
    _token = null;
  }

  /// Récupère le nombre de réservations d'un utilisateur pour un événement donné.
  /// Si [manifestationId] est fourni, compte les billets pour cette manifestation.
  /// Sinon, compte les billets "Pass Festival" (Id_Manifestation est null).
  Future<int> getTicketsCount(int festivalId, {int? manifestationId}) async {
    if (userId == null) return 0;
    
    final url = "${Config.apiUrlReservations}/$userId";
    print('--- API REQUEST (getTicketsCount) ---');
    print('URL: $url | Filter: ${manifestationId != null ? "Manifestation $manifestationId" : "Pass Festival"}');
    
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
        
        int count = 0;
        for (var res in reservations) {
          if (manifestationId != null) {
            // Pour une manifestation, on cherche uniquement l'ID manifestation
            if (res['Id_Manifestation'] == manifestationId || res['id_manifestation'] == manifestationId) {
              count++;
            }
          } else {
            // Pour le festival (Pass), on cherche l'ID festival ET que manifestation soit null
            bool sameFestival = (res['id_festival'] == festivalId || res['Id_Festival'] == festivalId);
            bool isPass = (res['Id_Manifestation'] == null && res['id_manifestation'] == null);
            if (sameFestival && isPass) {
              count++;
            }
          }
        }
        print('Nombre de tickets trouvé : $count');
        return count;
      } else if (response.statusCode == 404) {
        return 0; // Aucune réservation trouvée
      } else {
        throw "Erreur lors de la récupération des réservations";
      }
    } catch (e) {
      print('Erreur tickets count: $e');
      return 0;
    }
  }

  /// Récupère toutes les réservations d'un utilisateur.
  Future<List<Ticket>> getUserTickets() async {
    print('########################################');
    print('### FETCHING TICKETS FOR USER : $userId ###');
    print('########################################');
    if (userId == null) {
      print('!!! ABORTING FETCH : userId is NULL !!!');
      return [];
    }
    
    final url = "${Config.apiUrlReservations}/$userId";
    print('--- API REQUEST (getUserTickets) ---');
    
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        print('Response Body: ${response.body}');
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final List<dynamic> reservations = jsonResponse['data'] ?? [];
        print('Nombre de tickets reçus: ${reservations.length}');
        return reservations.map((res) => Ticket.fromMap(res)).toList();
      } else if (response.statusCode == 404) {
        print('Aucune réservation trouvée (404)');
        return [];
      } else {
        print('Erreur API (${response.statusCode}): ${response.body}');
        throw "Erreur lors de la récupération des tickets";
      }
    } catch (e) {
      print('Erreur getUserTickets: $e');
      return [];
    }
  }

  /// Effectue une réservation pour un utilisateur.
  Future<bool> reserverTicket({
    required int festivalId,
    int? manifestationId,
    required String type,
    required double prix,
  }) async {
    final url = Config.apiUrlReserver;
    print('--- API REQUEST (reserverTicket) ---');
    print('URL: $url');
    print('Current User ID: $userId');

    if (userId == null) {
      print('ERREUR : Impossible de réserver, userId est null (l\'utilisateur n\'est pas connecté)');
      return false;
    }

    try {
      // On prépare les données. Selon tes règles Laravel "required", 
      // on envoie les deux champs mais l'un sera vide si c'est l'autre qui est visé.
      final bodyData = {
        'Id_Utilisateur': userId.toString(),
        'id_festival': manifestationId == null ? festivalId.toString() : "",
        'Id_Manifestation': manifestationId?.toString() ?? "",
        'mode_obtention': 'en_ligne',
        'type_billet': type,
        'prix_paye': prix.toString(),
      };
      
      print('Données envoyées : $bodyData');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
        body: bodyData,
      );

      print('Status Code: ${response.statusCode}');
      if (response.statusCode == 201 || response.statusCode == 200) {
        print('Reservation Globale Success: ${response.body}');
        return true;
      } else {
        print('--- RESERVATION FAIL ---');
        print('Status: ${response.statusCode}');
        print('Response Body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('ERREUR Exception reserverTicket: $e');
      return false;
    }
  }

  /// Récupère les données du QR code pour une réservation.
  Future<String?> getQrCode(int reservationId) async {
    final url = "${Config.apiUrlQrCode}/$reservationId/qrcode";
    print('--- API REQUEST (getQrCode) ---');
    print('URL: $url');
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
      );

      print('Status Code: ${response.statusCode}');
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        return jsonResponse['qr_code']?.toString();
      } else {
        print('Erreur getQrCode (${response.statusCode}): ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception getQrCode: $e');
      return null;
    }
  }
}
