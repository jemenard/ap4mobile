/// Représente une actualité ou annonce postée par le staff.
class News {
  final int id;
  final String titre;
  final String message;
  final DateTime createdAt;
  final String staffNom;
  final String staffPrenom;

  News({
    required this.id,
    required this.titre,
    required this.message,
    required this.createdAt,
    required this.staffNom,
    required this.staffPrenom,
  });

  /// Nom complet du staff.
  String get staffFullName => "$staffPrenom $staffNom";

  /// Crée un objet [News] depuis une Map JSON.
  factory News.fromMap(Map<String, dynamic> map) {
    // Extraction des infos staff
    final staffData = map['staff'] ?? {};
    
    return News(
      id: int.tryParse(map['id_actu']?.toString() ?? "0") ?? 0,
      titre: map['titre']?.toString() ?? "Sans titre",
      message: map['message']?.toString() ?? "",
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? "") ?? DateTime.now(),
      staffNom: staffData['nom']?.toString() ?? "Inconnu",
      staffPrenom: staffData['prenom']?.toString() ?? "",
    );
  }
}
