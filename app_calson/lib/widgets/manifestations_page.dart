import 'package:flutter/material.dart';
import '../models/festival.dart';

class ManifestationsPage extends StatelessWidget {
  final Festival festival;

  const ManifestationsPage({super.key, required this.festival});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Manifestations ${festival.annee}"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.theater_comedy, size: 80, color: Colors.indigo),
            const SizedBox(height: 20),
            Text(
              "Liste des manifestations du festival\n${festival.theme}",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            const Text(
              "(En construction)",
              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
