import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/manifestation.dart';
import '../services/database_service.dart';
import 'connexionPage.dart';
import 'ticket_selection_page.dart';
import '../models/festival.dart';

class ManifestationDetailsPage extends StatefulWidget {
  final int manifestationId;

  const ManifestationDetailsPage({super.key, required this.manifestationId});

  @override
  State<ManifestationDetailsPage> createState() => _ManifestationDetailsPageState();
}

class _ManifestationDetailsPageState extends State<ManifestationDetailsPage> {
  final DatabaseService _databaseService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text("Détails de la manifestation"),
        backgroundColor: const Color(0xFF13293d),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Manifestation>(
        future: _databaseService.getManifestationDetails(widget.manifestationId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text("Erreur : ${snapshot.error}"),
                ],
              ),
            );
          } else if (!snapshot.hasData) {
            return const Center(child: Text("Aucune donnée disponible"));
          }

          final manifestation = snapshot.data!;
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image d'affiche
                if (manifestation.urlAffiche != null)
                  Image.network(
                    manifestation.urlAffiche!,
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 250,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported, size: 80),
                      );
                    },
                  ),

                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Titre
                      Text(
                        manifestation.titre,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF13293d),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Date et horaires
                      if (manifestation.session != null) ...[
                        _buildInfoCard(
                          icon: Icons.calendar_today,
                          title: "Date et Horaires",
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatDate(manifestation.session!.date),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${manifestation.session!.heureDebut} - ${manifestation.session!.heureFin}",
                                style: const TextStyle(fontSize: 15, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Lieu
                      if (manifestation.session?.lieu != null) ...[
                        _buildInfoCard(
                          icon: Icons.location_on,
                          title: "Lieu",
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                manifestation.session!.lieu!.nomLieu,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                manifestation.session!.lieu!.adresse,
                                style: const TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Capacité
                      _buildInfoCard(
                        icon: Icons.people,
                        title: "Capacité",
                        content: Row(
                          children: [
                            Flexible(
                              child: Text(
                                manifestation.capaciteFormatted,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                "places disponibles",
                                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Prix
                      _buildInfoCard(
                        icon: Icons.euro,
                        title: "Prix",
                        content: Text(
                          manifestation.prix == "0.00" || manifestation.prix == "Gratuit"
                              ? "Gratuit"
                              : "${manifestation.prix} €",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF13293d)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Public visé
                      _buildInfoCard(
                        icon: Icons.group,
                        title: "Public visé",
                        content: Text(
                          manifestation.publicVise,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Description
                      const Text(
                        "Description",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF13293d)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        manifestation.resume,
                        style: const TextStyle(fontSize: 15, height: 1.5),
                      ),
                      const SizedBox(height: 30),

                      // Bouton de réservation
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            // Vérifier si l'utilisateur est connecté
                            if (!_databaseService.isLoggedIn) {
                              // Rediriger vers la page de connexion
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ConnexionPage()),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Vous devez être connecté pour réserver"),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            } else {
                              // Afficher un indicateur de chargement
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => const Center(child: CircularProgressIndicator()),
                              );
                              
                              try {
                                // Vérifier la limite de 4 billets pour CETTE manifestation spécifique
                                int count = await _databaseService.getTicketsCount(
                                  manifestation.festivalId ?? 0, 
                                  manifestationId: manifestation.id,
                                );
                                
                                if (!mounted) return;
                                Navigator.pop(context); // Fermer le loader
                                
                                if (count >= 4) {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text("Limite atteinte"),
                                      content: const Text("Vous avez déjà réservé le maximum de 4 billets autorisés pour cette manifestation."),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text("OK"),
                                        ),
                                      ],
                                    ),
                                  );
                                } else {
                                  // Naviguer vers la sélection de billets
                                  // Note: On passe un "faux" festival ou on en récupère un vrai
                                  // Pour l'instant on crée un objet Festival minimal à partir des infos de la manif
                                  final festival = Festival(
                                    id: manifestation.festivalId ?? 0,
                                    name: "Festival", // Sera mis à jour par TicketSelectionPage si besoin
                                    location: manifestation.session?.lieu?.nomLieu ?? "",
                                    prix: 0.0, // Pas utilisé si manifestation est présent
                                    annee: 2026,
                                    theme: "",
                                    startDate: manifestation.session?.date != null 
                                        ? DateTime.tryParse(manifestation.session!.date) ?? DateTime.now() 
                                        : DateTime.now(),
                                    endDate: manifestation.session?.date != null 
                                        ? DateTime.tryParse(manifestation.session!.date) ?? DateTime.now() 
                                        : DateTime.now(),
                                  );

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TicketSelectionPage(
                                        festival: festival,
                                        manifestation: manifestation,
                                        existingTicketsCount: count,
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (!mounted) return;
                                Navigator.pop(context); // Fermer le loader
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Erreur lors de la vérification : $e")),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF13293d),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Réserver",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required Widget content,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF13293d).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF13293d), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  content,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}
