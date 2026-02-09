import 'session.dart';

/// Représente une manifestation (événement spécifique au sein d'un festival).
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

  /// Retourne le prix sous forme de double pour les calculs.
  double get numericPrix {
    if (prix.toLowerCase().contains('gratuit')) return 0.0;
    final cleanPrix = prix.replaceAll(' €', '').replaceAll(',', '.').trim();
    return double.tryParse(cleanPrix) ?? 0.0;
  }

  /// Calcule la capacité restante en fonction des réservations connues.
  int get capaciteRestante {
    final capaciteMax = int.tryParse(jaugeMax) ?? 0;
    final nbReservations = reservations?.length ?? 0;
    return capaciteMax - nbReservations;
  }

  /// Retourne la capacité sous forme texte "Restant / Max".
  String get capaciteFormatted {
    final capaciteMax = int.tryParse(jaugeMax) ?? 0;
    return "$capaciteRestante / $capaciteMax";
  }

  /// Crée une [Manifestation] depuis une Map simple.
  factory Manifestation.fromMap(Map<String, dynamic> map) {
    return Manifestation(
      id: int.parse(map['Id_Manifestation']?.toString() ?? "0"),
      titre: map['titre']?.toString() ?? "Sans titre",
      resume: map['resume']?.toString() ?? "",
      publicVise: map['public_vise']?.toString() ?? "Tout public",
      jaugeMax: (map['jauge_max'] ?? "0").toString(),
      prix: map['prix']?.toString() ?? "Gratuit",
      // On tente de récupérer l'ID du festival via différentes clés possibles
      festivalId: int.tryParse((map['id_festival'] ?? map['Id_Festival'] ?? "").toString()),
      session: map['session'] != null ? Session.fromMap(map['session']) : null,
      reservations: map['reservations'] is List ? map['reservations'] : null,
      urlAffiche: map['url_affiche']?.toString(),
    );
  }

  /// Factory spécialisée pour parser la réponse détaillée de l'API.
  factory Manifestation.fromDetailMap(Map<String, dynamic> data) {
    final manifData = data['manifestation'] ?? data;
    return Manifestation.fromMap(manifData);
  }
}
