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

  factory Festival.fromMap(Map<String, dynamic> data) {
    return Festival(
      id: data['Id_Festival'],
      annee: data['annee'],
      theme: data['theme'],
      dateDebut: data['date_debut'],
      dateFin: data['date_fin'],
      prix: (data['prix'] as num).toDouble(),
    );
  }
}
