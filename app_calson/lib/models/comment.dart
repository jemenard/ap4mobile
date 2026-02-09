class Comment {
  final int id;
  final String note;
  final String commentaire;
  final String? date;
  final String userName;
  final String userPrenom;

  Comment({
    required this.id,
    required this.note,
    required this.commentaire,
    this.date,
    required this.userName,
    required this.userPrenom,
  });

  factory Comment.fromMap(Map<String, dynamic> map) {
    final user = map['utilisateur'] ?? {};
    
    return Comment(
      id: int.tryParse(map['Id_Avis']?.toString() ?? "0") ?? 0,
      note: map['note']?.toString() ?? map['Note']?.toString() ?? "0",
      commentaire: map['comm']?.toString() ?? map['Commentaire']?.toString() ?? "",
      date: map['date_creation']?.toString() ?? map['created_at']?.toString(),
      userName: user['Nom']?.toString() ?? user['nom']?.toString() ?? "Anonyme",
      userPrenom: user['Prenom']?.toString() ?? user['prenom']?.toString() ?? "",
    );
  }

  String get userFullName => "$userPrenom $userName".trim();
}
