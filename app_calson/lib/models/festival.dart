class Festival {
  final int id;
  final int annee;
  final String theme;
  final DateTime startDate;
  final DateTime endDate;
  final double prix;
  final String name;
  final String description;
  final String location;

  Festival({
    required this.id,
    required this.annee,
    required this.theme,
    required this.startDate,
    required this.endDate,
    required this.prix,
    required this.name,
    required this.description,
    required this.location,
  });

  // Factory (Constructeur) pour créer un Festival depuis un objet JSON (Map)
  factory Festival.fromMap(Map<String, dynamic> data) {
    return Festival(
      id: data['Id_Festival'],
      annee: data['annee'],
      theme: data['theme'],
      // Gestion des dates : Si c'est déjà un DateTime on le garde, sinon on parse le String (format "2024-01-01")
      startDate: data['start_date'] is DateTime 
          ? data['start_date'] 
          : DateTime.parse(data['start_date'].toString()),
      endDate: data['end_date'] is DateTime 
          ? data['end_date'] 
          : DateTime.parse(data['end_date'].toString()),
      prix: (data['prix'] as num).toDouble(),
      name: data['name'],
      description: data['description'],
      location: data['location'],
    );
  }
}
