import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/festival.dart';
import '../config.dart';

class DatabaseService {
  // Singleton pattern
  static final DatabaseService _instance = DatabaseService._internal();

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<List<Festival>> getFestivals() async {
    try {
      // 1. Appel HTTP GET vers l'API (l'URL est stockée dans config.dart)
      final response = await http.get(Uri.parse(Config.apiUrl));

      if (response.statusCode == 200) {
        // 2. Décodage du JSON reçu en une liste dynamique
        List<dynamic> body = jsonDecode(response.body);
        
        // 3. Transformation de chaque élément JSON en objet Festival
        return body.map((dynamic item) => Festival.fromMap(item)).toList();
      } else {
        throw "Erreur serveur : ${response.statusCode}";
      }
    } catch (e) {
      print('Erreur API : $e');
      rethrow;
    }
  }
}
