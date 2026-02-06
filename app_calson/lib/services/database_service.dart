import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/festival.dart';
import '../models/manifestation.dart';
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
        return body.map((dynamic item) => Manifestation.fromMap(item)).toList();
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
        isLoggedIn = true;
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
        isLoggedIn = true;
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
        isLoggedIn = true;
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
  }
}
