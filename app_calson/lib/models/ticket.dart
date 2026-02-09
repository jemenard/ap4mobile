class Ticket {
  final int id;
  final String eventName;
  final String date;
  final String location;
  final double price;
  final String type; // Plein, Étudiant, Enfant
  final bool isPass;
  final bool isCancelled;

  Ticket({
    required this.id,
    required this.eventName,
    required this.date,
    required this.location,
    required this.price,
    required this.type,
    required this.isPass,
    required this.isCancelled,
  });

  factory Ticket.fromMap(Map<String, dynamic> map) {
    // Déterminer s'il s'agit d'un Pass ou d'une Manifestation
    final manifestation = map['manifestation'];
    final festival = map['festival'];
    
    String eventName = "Pass Festival";
    String location = "";
    String date = "";
    bool isPass = true;

    if (manifestation != null) {
      eventName = manifestation['titre'] ?? "Manifestation";
      isPass = false;
      // Protection contre les clés manquantes dans les relations imbriquées
      final session = manifestation['session'];
      if (session != null) {
        date = session['date_'] ?? session['date'] ?? "";
        final lieu = session['lieu'];
        if (lieu != null) {
          location = lieu['nom_lieu'] ?? lieu['nom'] ?? "";
        }
      }
    } else if (festival != null) {
      eventName = festival['nom'] ?? "Festival";
      location = festival['lieu'] ?? "";
      date = festival['date_debut'] ?? "";
    }

    return Ticket(
      id: int.parse(map['Id_Reservation'].toString()),
      eventName: eventName,
      date: date,
      location: location,
      price: double.tryParse(map['prix_paye'].toString()) ?? 0.0,
      type: map['type_billet'] ?? "Inconnu",
      isPass: isPass,
      isCancelled: map['statut']?.toString().toLowerCase() == 'annulé' || 
                   map['etat']?.toString().toLowerCase() == 'annulé' ||
                   map['is_cancelled'] == 1 || 
                   map['is_cancelled'] == true,
    );
  }
}
