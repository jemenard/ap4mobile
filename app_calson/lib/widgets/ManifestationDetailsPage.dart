import 'package:flutter/material.dart';
import '../models/manifestation.dart';

class ManifestationDetailsPage extends StatelessWidget {
  final Manifestation manifestation;

  const ManifestationDetailsPage({super.key, required this.manifestation});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(manifestation.titre), 
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              manifestation.titre,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              "Description",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(manifestation.resume),
          ],
        ),
      ),
    );
  }
}
