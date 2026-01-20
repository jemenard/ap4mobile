class Manifestation {
  final int id;
  final String nom;
  final String date;
  final String heure;
  final String lieu;
  final String description;
  final String image;
  final int festivalId;

  Manifestation({
    required this.id,
    required this.nom,
    required this.date,
    required this.heure,
    required this.lieu,
    required this.description,
    required this.image,
    required this.festivalId,
  });

  factory Manifestation.fromMap(Map<String, dynamic> map) {
    return Manifestation(
      id: map['id'],
      nom: map['nom'],
      date: map['date'],
      heure: map['heure'],
      lieu: map['lieu'],
      description: map['description'],
      image: map['image'],
      festivalId: map['festivalId'],
    );
  }
}