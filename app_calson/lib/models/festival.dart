class Festival {
  final int id;
  final int annee;
  final String theme;
  final DateTime startDate;
  final DateTime endDate;
  final double prix;
  final String name;
  final String location;
  final String? urlLogo;

  Festival({
    required this.id,
    required this.annee,
    required this.theme,
    required this.startDate,
    required this.endDate,
    required this.prix,
    required this.name,
    required this.location,
    this.urlLogo,
  });

  // Factory (Constructeur) pour créer un Festival depuis un objet JSON (Map)
  factory Festival.fromMap(Map<String, dynamic> data) {
    return Festival(
      id: int.parse(data['Id_Festival'].toString()),
      annee: int.parse(data['annee'].toString()),
      theme: data['theme'],
      location: data['adresse'] ?? "L'entre terre",
      startDate: data['date_debut'] is DateTime 
          ? data['date_debut'] 
          : DateTime.parse(data['date_debut'].toString()),
      endDate: data['date_fin'] is DateTime 
          ? data['date_fin'] 
          : DateTime.parse(data['date_fin'].toString()),
      name: data['theme'],
      prix: double.parse(data['prix'].toString()),
      urlLogo: data['url_logo']?.toString(),
    );
  }
}
