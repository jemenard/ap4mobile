import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/database_service.dart';
import '../models/ticket.dart';

/// Page affichant la liste des tickets et pass réservés par l'utilisateur.
/// Permet de consulter les détails, afficher le QR Code et annuler une réservation.
class UserTicketsPage extends StatefulWidget {
  const UserTicketsPage({super.key});

  @override
  State<UserTicketsPage> createState() => _UserTicketsPageState();
}

class _UserTicketsPageState extends State<UserTicketsPage> {
  final DatabaseService _databaseService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Ticket>>(
      future: _databaseService.getUserTickets(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } 
        
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text("Erreur lors de la récupération des tickets : ${snapshot.error}"),
            ),
          );
        } 
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState();
        }

        final tickets = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tickets.length,
          itemBuilder: (context, index) => _buildTicketCard(tickets[index]),
        );
      },
    );
  }

  /// État affiché lorsqu'aucun ticket n'est présent.
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.confirmation_number_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            "Aucun ticket trouvé",
            style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text("Vos réservations apparaîtront ici après vos achats."),
        ],
      ),
    );
  }

  /// Construit une carte interactive pour un ticket.
  Widget _buildTicketCard(Ticket ticket) {
    // Calcul des couleurs selon l'état et le type
    final Color accentColor = ticket.isCancelled 
        ? Colors.grey 
        : (ticket.isPass ? const Color(0xFF13293d) : Colors.orange);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: ticket.isCancelled ? null : () => _showQrCode(ticket),
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Barre latérale de couleur
              Container(
                width: 8,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(ticket, accentColor),
                      const SizedBox(height: 12),
                      _buildBody(ticket),
                      const Divider(height: 24),
                      _buildFooter(ticket),
                      if (!ticket.isCancelled) _buildCancelButton(ticket),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Ticket ticket, Color accentColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            ticket.eventName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            ticket.type.toUpperCase(),
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: accentColor),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(Ticket ticket) {
    return Column(
      children: [
        if (ticket.date.isNotEmpty) _buildInfoRow(Icons.calendar_today, _formatDate(ticket.date)),
        if (ticket.location.isNotEmpty) ...[
          const SizedBox(height: 4),
          _buildInfoRow(Icons.location_on_outlined, ticket.location),
        ],
      ],
    );
  }

  Widget _buildFooter(Ticket ticket) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("Prix payé", style: TextStyle(color: Colors.grey, fontSize: 13)),
        Text(
          "${ticket.price.toStringAsFixed(2)} €",
          style: TextStyle(
            fontSize: 17, 
            fontWeight: FontWeight.bold,
            color: ticket.isCancelled ? Colors.grey : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildCancelButton(Ticket ticket) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _confirmAnnulation(ticket),
          icon: const Icon(Icons.cancel_outlined, size: 18),
          label: const Text("Annuler la réservation"),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
            padding: const EdgeInsets.symmetric(vertical: 8),
          ),
        ),
      ),
    );
  }

  /// Affiche le QR Code dans un dialogue.
  void _showQrCode(Ticket ticket) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ticket.eventName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FutureBuilder<String?>(
              future: _databaseService.getQrCode(ticket.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
                }
                if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                  return const Text("Erreur lors de la génération du QR code.");
                }

                return Column(
                  children: [
                    const Text("Présentez ce code au contrôle", style: TextStyle(fontSize: 14)),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: QrImageView(
                        data: snapshot.data!,
                        version: QrVersions.auto,
                        size: 200.0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text("Ref: ${snapshot.data!}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Fermer")),
        ],
      ),
    );
  }

  /// Demande confirmation avant annulation.
  void _confirmAnnulation(Ticket ticket) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmer l'annulation ?"),
        content: const Text("Cette action est irréversible. Souhaitez-vous vraiment annuler votre réservation ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Conserver")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _executeAnnulation(ticket);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Confirmer"),
          ),
        ],
      ),
    );
  }

  /// Exécute l'annulation via le service.
  Future<void> _executeAnnulation(Ticket ticket) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final success = await _databaseService.annulerReservation(ticket.id);

    if (mounted) {
      Navigator.pop(context); // Fermer loader
      if (success) {
        _showToast("Réservation annulée.");
        setState(() {}); // Rafraîchir la liste
      } else {
        _showToast("Échec de l'annulation.");
      }
    }
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: TextStyle(color: Colors.grey.shade800, fontSize: 13), overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _formatDate(String dateStr) {
    try {
      final DateTime date = DateTime.parse(dateStr);
      return DateFormat('dd MMMM yyyy', 'fr_FR').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}
