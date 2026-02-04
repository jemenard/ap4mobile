import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/festival.dart';
import '../models/manifestation.dart';
import '../config.dart';

class DatabaseService {
  // Singleton pattern
  static final DatabaseService _instance = DatabaseService._internal();

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();
  
  bool isLoggedIn = false; // Stockage de l'état de connexion

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
          'Accept': 'application/json', // <--- LA LIGNE MAGIQUE
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
      final response = await http.post(
        Uri.parse(url),
        headers:
        {
          'Accept': 'application/json', // <--- LA LIGNE MAGIQUE
        },
        body:
        {
          'name': nom,
          'prenom': prenom,
          'email': email,
          'telephone': telephone,
          'password': mdp,
        },
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

  void deconnexion() {
    isLoggedIn = false;
  }
}
