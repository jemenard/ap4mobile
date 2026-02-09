class Ticket {
  final int id;
  final int? festivalId;
  final int? manifestationId;
  final String eventName;
  final String date;
  final String location;
  final double price;
  final String type; // Plein, Étudiant, Enfant
  final bool isPass;
  final bool isCancelled;

  Ticket({
    required this.id,
    this.festivalId,
    this.manifestationId,
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
    
    int? festivalId = int.tryParse((map['id_festival'] ?? map['Id_Festival']).toString());
    int? manifestationId = int.tryParse((map['Id_Manifestation'] ?? map['id_manifestation']).toString());
    
    String eventName = "Pass Festival";
    String location = "";
    String date = "";
    bool isPass = true;

    if (manifestation != null) {
      eventName = manifestation['titre'] ?? "Manifestation";
      isPass = false;
      manifestationId ??= int.tryParse(manifestation['id']?.toString() ?? "");
      festivalId ??= int.tryParse(manifestation['id_festival']?.toString() ?? "");
      
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
      festivalId ??= int.tryParse(festival['id']?.toString() ?? "");
    }

    // Extraction du statut depuis l'objet 'statut' (colonnes Id_Statut, etat)
    final statutData = map['statut'];
    String labelStatut = "Inconnu";
    if (statutData is Map) {
      labelStatut = statutData['etat']?.toString() ?? "Inconnu";
    } else {
      labelStatut = map['etat']?.toString() ?? map['libelle_statut']?.toString() ?? "Inconnu";
    }

    return Ticket(
      id: int.parse(map['Id_Reservation'].toString()),
      festivalId: festivalId,
      manifestationId: manifestationId,
      eventName: eventName,
      date: date,
      location: location,
      price: double.tryParse((map['prix_payer'] ?? map['prix_paye'] ?? map['Prix_Paye'] ?? 0).toString()) ?? 0.0,
      type: labelStatut,
      isPass: isPass,
      isCancelled: map['Id_Statut']?.toString() == '0' || 
                   map['id_statut']?.toString() == '0' ||
                   labelStatut.toLowerCase().contains('annulé') == true ||
                   map['is_cancelled'] == 1 || 
                   map['is_cancelled'] == true,
    );
  }
}
