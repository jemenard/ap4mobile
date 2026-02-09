/// Représente un festival avec ses informations principales.
class Festival {
  final int id;
  final int annee;
  final String theme;
  final DateTime startDate;
  final DateTime endDate;
  final double prix;
  final String name; // Souvent identique au thème dans cette API
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

  /// Crée une instance de [Festival] à partir d'une Map (JSON).
  factory Festival.fromMap(Map<String, dynamic> data) {
    return Festival(
      id: int.parse(data['Id_Festival'].toString()),
      annee: int.tryParse(data['annee'].toString()) ?? DateTime.now().year,
      theme: data['theme']?.toString() ?? "Inconnu",
      location: data['adresse']?.toString() ?? data['lieu']?.toString() ?? "Lieu non précisé",
      startDate: data['date_debut'] is DateTime 
          ? data['date_debut'] 
          : DateTime.tryParse(data['date_debut']?.toString() ?? "") ?? DateTime.now(),
      endDate: data['date_fin'] is DateTime 
          ? data['date_fin'] 
          : DateTime.tryParse(data['date_fin']?.toString() ?? "") ?? DateTime.now(),
      name: data['nom']?.toString() ?? data['theme']?.toString() ?? "Festival",
      prix: double.tryParse(data['prix']?.toString() ?? "0") ?? 0.0,
      urlLogo: data['url_logo']?.toString(),
    );
  }
}
