import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/manifestation.dart';
import '../models/festival.dart';
import '../services/database_service.dart';
import 'connexionPage.dart';
import 'ticket_selection_page.dart';

/// Page affichant les détails complets d'une manifestation spécifique.
/// Permet de consulter les horaires, le lieu et d'effectuer une réservation.
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
        title: const Text("Détails de l'événement"),
        centerTitle: true,
      ),
      body: FutureBuilder<Manifestation>(
        future: _databaseService.getManifestationDetails(widget.manifestationId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } 
          
          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          } 
          
          if (!snapshot.hasData) {
            return const Center(child: Text("Informations indisponibles."));
          }

          final manifestation = snapshot.data!;
          return _buildContent(manifestation);
        },
      ),
    );
  }

  /// Construit l'état d'erreur visuel.
  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text("Erreur lors du chargement : $error", textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => setState(() {}),
              child: const Text("Réessayer"),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit le corps de la page avec les données chargées.
  Widget _buildContent(Manifestation manifestation) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderImage(manifestation),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitleSection(manifestation),
                const SizedBox(height: 24),
                _buildInfoGrid(manifestation),
                const SizedBox(height: 32),
                _buildDescriptionSection(manifestation),
                const SizedBox(height: 40),
                _buildBookingButton(manifestation),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderImage(Manifestation manifestation) {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(color: Colors.grey.shade200),
      child: (manifestation.urlAffiche != null && manifestation.urlAffiche!.isNotEmpty)
          ? Image.network(
              manifestation.urlAffiche!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
            )
          : _buildImagePlaceholder(),
    );
  }

  Widget _buildImagePlaceholder() {
    return const Center(child: Icon(Icons.image_outlined, size: 80, color: Colors.grey));
  }

  Widget _buildTitleSection(Manifestation manifestation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          manifestation.titre,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF13293d)),
        ),
        if (manifestation.publicVise.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            "Public : ${manifestation.publicVise}",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoGrid(Manifestation manifestation) {
    return Column(
      children: [
        if (manifestation.session != null)
          _buildInfoRow(
            Icons.calendar_month,
            "Date et Horaires",
            "${_formatDate(manifestation.session!.date)} • ${manifestation.session!.heureDebut} - ${manifestation.session!.heureFin}",
          ),
        if (manifestation.session?.lieu != null)
          _buildInfoRow(
            Icons.location_on_outlined,
            "Lieu",
            "${manifestation.session!.lieu!.nomLieu}\n${manifestation.session!.lieu!.adresse}",
          ),
        _buildInfoRow(
          Icons.people_outline,
          "Places",
          manifestation.capaciteFormatted,
          subtext: "disponibles sur ${manifestation.jaugeMax}",
        ),
        _buildInfoRow(
          Icons.payments_outlined,
          "Tarif",
          (manifestation.prix == "0.00" || manifestation.prix == "Gratuit") ? "Gratuit" : "${manifestation.prix} €",
          isHighlight: true,
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String content, {String? subtext, bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF13293d), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
                    color: isHighlight ? Colors.green.shade700 : null,
                  ),
                ),
                if (subtext != null)
                  Text(subtext, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection(Manifestation manifestation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "À propos",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          manifestation.resume,
          style: const TextStyle(fontSize: 15, height: 1.6, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildBookingButton(Manifestation manifestation) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _handleBooking(manifestation),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF13293d),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
        child: const Text("Réserver", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  /// Gère la redirection vers l'achat avec contrôles de sécurité.
  Future<void> _handleBooking(Manifestation manifestation) async {
    // 1. Authentification
    if (!_databaseService.isLoggedIn) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ConnexionPage()));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez vous connecter pour réserver.")),
      );
      return;
    }

    _showLoading();

    try {
      // 2. Quota : 4 billets par manifestation
      int count = await _databaseService.getTicketsCount(
        manifestation.festivalId ?? 0, 
        manifestationId: manifestation.id,
      );
      
      if (!mounted) return;
      Navigator.pop(context); // Fermer loader

      if (count >= 4) {
        _showLimitDialog();
      } else {
        _navigateToSelection(manifestation, count);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showToast("Erreur : $e");
      }
    }
  }

  void _navigateToSelection(Manifestation manifestation, int count) {
    // Création d'un objet Festival minimal requis par la page de sélection
    final festival = Festival(
      id: manifestation.festivalId ?? 0,
      name: "Festival", 
      location: manifestation.session?.lieu?.nomLieu ?? "",
      prix: 0.0,
      annee: DateTime.now().year,
      theme: "",
      startDate: DateTime.tryParse(manifestation.session?.date ?? "") ?? DateTime.now(),
      endDate: DateTime.tryParse(manifestation.session?.date ?? "") ?? DateTime.now(),
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

  void _showLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _showLimitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Limite atteinte"),
        content: const Text("Vous avez déjà atteint la limite de 4 billets pour cet événement."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
        ],
      ),
    );
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
