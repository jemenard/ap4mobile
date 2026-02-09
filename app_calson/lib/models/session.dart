import 'lieu.dart';

/// Représente une session de manifestation (une occurrence temporelle).
class Session {
  final int id;
  final String date;
  final String heureDebut;
  final String heureFin;
  final int idLieu;
  final Lieu? lieu;

  Session({
    required this.id,
    required this.date,
    required this.heureDebut,
    required this.heureFin,
    required this.idLieu,
    this.lieu,
  });

  /// Crée une [Session] depuis une Map (JSON).
  factory Session.fromMap(Map<String, dynamic> map) {
    return Session(
      id: int.parse(map['Id_Session']?.toString() ?? "0"),
      date: (map['date_'] ?? map['date'] ?? "").toString(),
      heureDebut: (map['heure_debut'] ?? "").toString(),
      heureFin: (map['heure_fin'] ?? "").toString(),
      idLieu: int.parse(map['Id_Lieu']?.toString() ?? "0"),
      lieu: map['lieu'] != null ? Lieu.fromMap(map['lieu']) : null,
    );
  }
}
