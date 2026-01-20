import 'package:flutter/material.dart';
import '../models/festival.dart';
import '../services/database_service.dart';
import 'ManifestationDetailsPage.dart';

class ManifestationsPage extends StatelessWidget {
  final Festival festival;
  final int festivalId;
  const ManifestationsPage({super.key, required this.festival, required this.festivalId});
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
            Expanded(
              child: FutureBuilder(
                future: DatabaseService().getManifestations(festivalId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    if (snapshot.hasError) {
                      return Text('Erreur: ${snapshot.error}');
                    } else if (snapshot.hasData) {
                      final manifestations = snapshot.data!;
                      return ListView.builder(
                        itemCount: manifestations.length,
                        itemBuilder: (context, index) {
                          final manifestation = manifestations[index];
                          return ListTile(
                            title: Text(manifestation.nom),
                            subtitle: Text(manifestation.date),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ManifestationDetailsPage(manifestation: manifestation),
                                ),
                              );
                            },
                          );
                        },
                      );
                    } else {
                      return const Text("Aucune manifestation trouvée.");
                    }
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
