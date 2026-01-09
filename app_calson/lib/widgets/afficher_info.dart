import 'package:flutter/material.dart';
import '../models/festival.dart';
import 'package:intl/intl.dart';

class AfficherInfo extends StatelessWidget {
  final Festival festival;

  const AfficherInfo({super.key, required this.festival});

  @override
  Widget build(BuildContext context) {
    // Format dates
    final dateFormat = DateFormat('dd/MM/yyyy');
    final dateDebut = dateFormat.format(festival.dateDebut);
    final dateFin = dateFormat.format(festival.dateFin);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Festival ${festival.annee}",
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

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(Icons.calendar_today, "Début", dateDebut),
                  const SizedBox(height: 10),
                  _buildInfoRow(Icons.event_busy, "Fin", dateFin),
                  const SizedBox(height: 10),
                  _buildInfoRow(
                      Icons.euro, "Prix", "${festival.prix.toStringAsFixed(2)} €"),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Add action for button
              },
              child: const Text("Acheter"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Text(
          "$label : ",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }
}
