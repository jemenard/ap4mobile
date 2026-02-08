import 'lieu.dart';

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

  factory Session.fromMap(Map<String, dynamic> map) {
    return Session(
      id: int.parse(map['Id_Session'].toString()),
      date: map['date_'],
      heureDebut: map['heure_debut'],
      heureFin: map['heure_fin'],
      idLieu: int.parse(map['Id_Lieu'].toString()),
      lieu: map['lieu'] != null ? Lieu.fromMap(map['lieu']) : null,
    );
  }
}
