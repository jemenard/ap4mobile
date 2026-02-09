import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/festival.dart';
import '../services/database_service.dart';
import 'connexionPage.dart';
import 'manifestations_page.dart';
import 'ticket_selection_page.dart';

/// Page d'affichage des détails d'un festival.
/// Permet de consulter les informations générales et d'initier l'achat de pass.
class AfficherInfo extends StatelessWidget {
  final Festival festival;

  const AfficherInfo({super.key, required this.festival});

  @override
  Widget build(BuildContext context) {
    // Formatage des dates pour l'affichage localisé
    final dateFormat = DateFormat('dd MMMM yyyy', 'fr_FR');
    final dateDebut = dateFormat.format(festival.startDate);
    final dateFin = dateFormat.format(festival.endDate);

    return Scaffold(
      appBar: AppBar(
        title: Text(festival.name),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Section visuelle (Logo/Affiche)
            _buildFestivalHeader(),

            const SizedBox(height: 24),

            // Titre et Édition
            Text(
              festival.theme,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Édition ${festival.annee}",
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),

            const SizedBox(height: 24),

            // Cartouche d'informations pratiques
            _buildPracticalInfo(dateDebut, dateFin),

            const SizedBox(height: 32),

            // Section d'actions (Boutons)
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  /// Construit l'en-tête visuel avec l'image du festival.
  Widget _buildFestivalHeader() {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: (festival.urlLogo != null && festival.urlLogo!.isNotEmpty)
            ? Image.network(
                festival.urlLogo!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholder(),
              )
            : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return const Icon(Icons.festival_outlined, size: 80, color: Colors.blueGrey);
  }

  /// Affiche les informations de dates, lieu et prix.
  Widget _buildPracticalInfo(String start, String end) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.calendar_month, "Dates", "$start au $end"),
          const Divider(height: 24),
          _buildInfoRow(Icons.location_on_outlined, "Lieu", festival.location),
          const Divider(height: 24),
          _buildInfoRow(Icons.payments_outlined, "Prix Pass", "${festival.prix.toStringAsFixed(2)} €"),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF13293d), size: 24),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  /// Groupe les boutons d'achat et de consultation des manifestations.
  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Bouton Manifestations
        OutlinedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ManifestationsPage(festival: festival, festivalId: festival.id),
            ),
          ),
          icon: const Icon(Icons.list_alt),
          label: const Text("Détails des manifestations"),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        
        const SizedBox(height: 16),

        // Bouton Achat Tickets
        ElevatedButton.icon(
          onPressed: () => _handleTicketPurchase(context),
          icon: const Icon(Icons.shopping_bag_outlined),
          label: const Text("Acheter un Pass Festival"),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF13293d),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
          ),
        ),
      ],
    );
  }

  /// Gère la logique d'achat : connexion et vérification du quota.
  Future<void> _handleTicketPurchase(BuildContext context) async {
    final dbService = DatabaseService();

    // 1. Vérification connexion
    if (!dbService.isLoggedIn) {
      _redirectToLogin(context);
      return;
    }

    // 2. Affichage loader
    _showLoading(context);

    try {
      // 3. Vérification du quota (max 4 billets par festival)
      int count = await dbService.getTicketsCount(festival.id);
      
      if (!context.mounted) return;
      Navigator.pop(context); // Fermeturer loader

      if (count >= 4) {
        _showLimitDialog(context);
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TicketSelectionPage(
              festival: festival,
              existingTicketsCount: count,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Fermer loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur technique : $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _redirectToLogin(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const ConnexionPage()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Veuillez vous connecter pour acheter un billet.")),
    );
  }

  void _showLoading(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _showLimitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Limite atteinte"),
        content: const Text("Vous ne pouvez pas acheter plus de 4 pass pour ce festival."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Compris")),
        ],
      ),
    );
  }
}
