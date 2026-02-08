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

  factory Lieu.fromMap(Map<String, dynamic> map) {
    return Lieu(
      id: int.parse(map['Id_Lieu'].toString()),
      nomLieu: map['nom_lieu'],
      adresse: map['adresse'],
      capaciteMax: int.parse(map['capacite_max'].toString()),
      typeLieu: int.parse(map['type_lieu'].toString()),
      equipements: map['equipements'],
    );
  }
}
