class Festival {
  final int id;
  final int annee;
  final String theme;
  final DateTime dateDebut;
  final DateTime dateFin;
  final double prix;

  Festival({
    required this.id,
    required this.annee,
    required this.theme,
    required this.dateDebut,
    required this.dateFin,
    required this.prix,
  });

  // Factory (Constructeur) pour créer un Festival depuis un objet JSON (Map)
  factory Festival.fromMap(Map<String, dynamic> data) {
    return Festival(
      id: data['Id_Festival'],
      annee: data['annee'],
      theme: data['theme'],
      // Gestion des dates : Si c'est déjà un DateTime on le garde, sinon on parse le String (format "2024-01-01")
      dateDebut: data['date_debut'] is DateTime 
          ? data['date_debut'] 
          : DateTime.parse(data['date_debut'].toString()),
      dateFin: data['date_fin'] is DateTime 
          ? data['date_fin'] 
          : DateTime.parse(data['date_fin'].toString()),
      prix: (data['prix'] as num).toDouble(),
    );
  }
}
