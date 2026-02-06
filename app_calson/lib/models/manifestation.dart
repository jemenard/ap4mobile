class Manifestation {
  final int id;
  final String titre;
  final String resume;
  final String publicVise;
  final String jaugeMax;
  final String prix;
  final int festivalId;

  Manifestation({
    required this.id,
    required this.titre,
    required this.resume,
    required this.publicVise,
    required this.jaugeMax,
    required this.prix,
    required this.festivalId,
  });

  factory Manifestation.fromMap(Map<String, dynamic> map) {
    return Manifestation(
      id: int.parse(map['Id_Manifestation'].toString()),
      titre: map['titre'],
      resume: map['resume'],
      publicVise: map['public_vise'],
      jaugeMax: map['jauge_max'].toString(),
      prix: map['prix']?.toString() ?? "Gratuit",
      festivalId: int.parse(map['Id_Session']?.toString() ?? '0'),
    );
  }
}