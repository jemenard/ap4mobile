/// Représente un lieu physique où se déroule une manifestation.
class Lieu {
  final int id;
  final String nomLieu;
  final String adresse;
  final int capaciteMax;
  final int typeLieu;
  final String? equipements;

  Lieu({
    required this.id,
    required this.nomLieu,
    required this.adresse,
    required this.capaciteMax,
    required this.typeLieu,
    this.equipements,
  });

  /// Crée un [Lieu] depuis une Map (JSON).
  factory Lieu.fromMap(Map<String, dynamic> map) {
    return Lieu(
      id: int.parse(map['Id_Lieu']?.toString() ?? "0"),
      nomLieu: map['nom_lieu']?.toString() ?? "Lieu inconnu",
      adresse: map['adresse']?.toString() ?? "",
      capaciteMax: int.tryParse(map['capacite_max']?.toString() ?? "") ?? 0,
      typeLieu: int.tryParse(map['type_lieu']?.toString() ?? "") ?? 0,
      equipements: map['equipements']?.toString(),
    );
  }
}
