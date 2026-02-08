import 'session.dart';

class Manifestation {
  final int id;
  final String titre;
  final String resume;
  final String publicVise;
  final String jaugeMax;
  final String prix;
  final int? festivalId;
  final Session? session;
  final List<dynamic>? reservations;
  final String? urlAffiche;

  Manifestation({
    required this.id,
    required this.titre,
    required this.resume,
    required this.publicVise,
    required this.jaugeMax,
    required this.prix,
    this.festivalId,
    this.session,
    this.reservations,
    this.urlAffiche,
  });

  /// Calcule la capacité restante
  int get capaciteRestante {
    final capaciteMax = int.tryParse(jaugeMax) ?? 0;
    final nbReservations = reservations?.length ?? 0;
    return capaciteMax - nbReservations;
  }

  /// Retourne la capacité sous forme "X / Y"
  String get capaciteFormatted {
    final capaciteMax = int.tryParse(jaugeMax) ?? 0;
    return "$capaciteRestante / $capaciteMax";
  }

  factory Manifestation.fromMap(Map<String, dynamic> map) {
    return Manifestation(
      id: int.parse(map['Id_Manifestation'].toString()),
      titre: map['titre'],
      resume: map['resume'],
      publicVise: map['public_vise'],
      jaugeMax: map['jauge_max'].toString(),
      prix: map['prix']?.toString() ?? "Gratuit",
      festivalId: map['Id_Session'] != null ? int.tryParse(map['Id_Session'].toString()) : null,
      session: map['session'] != null ? Session.fromMap(map['session']) : null,
      reservations: map['reservations'],
      urlAffiche: map['url_affiche'],
    );
  }

  /// Factory pour parser depuis la structure complète de l'API détails
  factory Manifestation.fromDetailMap(Map<String, dynamic> data) {
    final manifestation = data['manifestation'];
    return Manifestation(
      id: int.parse(manifestation['Id_Manifestation'].toString()),
      titre: manifestation['titre'],
      resume: manifestation['resume'],
      publicVise: manifestation['public_vise'],
      jaugeMax: manifestation['jauge_max'].toString(),
      prix: manifestation['prix']?.toString() ?? "Gratuit",
      festivalId: manifestation['Id_Session'] != null 
          ? int.tryParse(manifestation['Id_Session'].toString()) 
          : null,
      session: manifestation['session'] != null 
          ? Session.fromMap(manifestation['session']) 
          : null,
      reservations: manifestation['reservations'],
      urlAffiche: manifestation['url_affiche'],
    );
  }
}
