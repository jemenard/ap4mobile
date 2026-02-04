class Festival {
  final int id;
  final int annee;
  final String theme;
  final DateTime startDate;
  final DateTime endDate;
  final double prix;
  final String name;
  final String location;

  Festival({
    required this.id,
    required this.annee,
    required this.theme,
    required this.startDate,
    required this.endDate,
    required this.prix,
    required this.name,
    required this.location,
  });

  // Factory (Constructeur) pour créer un Festival depuis un objet JSON (Map)
  factory Festival.fromMap(Map<String, dynamic> data) {
    return Festival(
      id: int.parse(data['Id_Festival'].toString()),
      annee: int.parse(data['annee'].toString()),
      theme: data['theme'],
      startDate: data['date_debut'] is DateTime 
          ? data['date_debut'] 
          : DateTime.parse(data['date_debut'].toString()),
      endDate: data['date_fin'] is DateTime 
          ? data['date_fin'] 
          : DateTime.parse(data['date_fin'].toString()),
      prix: double.parse(data['prix'].toString()),
      name: data['theme'],
      location: data['adresse'] ?? "L'entre terre",
    );
  }
}
