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
      id: int.parse(map['id'].toString()),
      titre: map['titre'],
      resume: map['resume'],
      publicVise: map['publicVise'],
      jaugeMax: map['jaugeMax'],
      prix: map['prix'] ?? "Gratuit",
      festivalId: int.parse(map['festivalId'].toString()),
    );
  }
}