import 'package:mysql_client/mysql_client.dart';
import '../models/festival.dart';

class DatabaseService {
  // Singleton pattern
  static final DatabaseService _instance = DatabaseService._internal();

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  // Connection settings
  final String _host = '192.168.110.16';
  final int _port = 3306;
  final String _user = 'myosobot';
  final String _password = '4m#2df&WDfG5E!KO';
  final String _db = 'calesons';

  Future<MySQLConnection> _getConnection() async {
    return await MySQLConnection.createConnection(
      host: _host,
      port: _port,
      userName: _user,
      password: _password,
      databaseName: _db,
      secure: true,
    );
  }

  Future<List<Festival>> getFestivals() async {
    print('Connecting to DB with mysql_client...');
    final conn = await _getConnection();
    try {
      await conn.connect();
      print('Connected!');

      // Execute query
      var results = await conn.execute(
          'SELECT Id_Festival, annee, theme, date_debut, date_fin, prix FROM Festival');
      
      List<Festival> festivals = [];
      for (final row in results.rows) {
        final data = row.assoc();
        
        // Manual conversion because mysql_client returns Strings in assoc()
        Map<String, dynamic> convertedData = {};
        
        // Helper to parse Int
        int parseInt(dynamic val) {
          if (val is int) return val;
          if (val == null) return 0;
          return int.tryParse(val.toString()) ?? 0;
        }

        // Helper to parse Double
        double parseDouble(dynamic val) {
           if (val is double) return val;
           if (val is int) return val.toDouble();
           if (val == null) return 0.0;
           return double.tryParse(val.toString()) ?? 0.0;
        }

        convertedData['Id_Festival'] = parseInt(data['Id_Festival']);
        convertedData['annee'] = parseInt(data['annee']);
        convertedData['theme'] = data['theme'] ?? '';
        convertedData['date_debut'] = DateTime.tryParse(data['date_debut'].toString()) ?? DateTime.now();
        convertedData['date_fin'] = DateTime.tryParse(data['date_fin'].toString()) ?? DateTime.now();
        convertedData['prix'] = parseDouble(data['prix']);


        festivals.add(Festival.fromMap(convertedData));
      }
      return festivals;
    } catch (e) {
      print('Database Error: $e');
      rethrow;
    } finally {
      if (conn.connected) {
          await conn.close();
      }
    }
  }
}
