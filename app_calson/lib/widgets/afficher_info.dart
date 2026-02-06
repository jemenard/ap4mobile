import 'package:flutter/material.dart';
import '../models/festival.dart';
import 'package:intl/intl.dart';
import 'manifestations_page.dart';
import 'ticket_selection_page.dart';

class AfficherInfo extends StatelessWidget {
  final Festival festival;

  const AfficherInfo({super.key, required this.festival});

  @override
  Widget build(BuildContext context) {
    // Format dates
    final dateFormat = DateFormat('dd/MM/yyyy');
    final dateDebut = dateFormat.format(festival.startDate);
    final dateFin = dateFormat.format(festival.endDate);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          festival.name,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18),
        ),
        toolbarHeight: 70,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Placeholder for image since we removed it from schema
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.event, size: 100, color: Colors.blueGrey),
            ),

            const SizedBox(height: 20),

            Text(
              "Thème : ${festival.theme}",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Text(
              "Édition ${festival.annee}",
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(Icons.calendar_today, "Début", dateDebut),
                  const SizedBox(height: 10),
                  _buildInfoRow(Icons.event_busy, "Fin", dateFin),
                  const SizedBox(height: 10),
                  _buildInfoRow(Icons.location_on, "Lieu", festival.location),
                  const SizedBox(height: 10),
                  _buildInfoRow(
                      Icons.euro, "Prix", "${festival.prix.toStringAsFixed(2)} €"),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "À propos du festival",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    festival.theme,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ManifestationsPage(
                      festival: festival,
                      festivalId: festival.id,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.list_alt),
              label: const Text("Détails des manifestations"),
            ),

            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TicketSelectionPage(
                      festival: festival,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.shopping_cart),
              label: const Text("Acheter des billets"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Text(
          "$label : ",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
      ],
    );
  }
}
