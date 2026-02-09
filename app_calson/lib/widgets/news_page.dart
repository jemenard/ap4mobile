import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../models/news.dart';
import 'news_details_page.dart';

/// Page affichant la liste des actualités du festival.
class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  final DatabaseService _databaseService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Actualités"),
        backgroundColor: const Color(0xFF13293d),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<News>>(
        future: _databaseService.getNews(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text("Erreur : ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.newspaper, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("Aucune actualité pour le moment.", 
                    style: TextStyle(color: Colors.grey, fontSize: 16)
                  ),
                ],
              ),
            );
          }

          final newsList = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: newsList.length,
            itemBuilder: (context, index) {
              return _buildNewsCard(newsList[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildNewsCard(News news) {
    // Formatage de la date (ex: 09 fév. 2026 à 21:14)
    final dateStr = DateFormat('dd MMM yyyy à HH:mm', 'fr_FR').format(news.createdAt);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewsDetailsPage(news: news),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      news.titre,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF13293d),
                      ),
                    ),
                  ),
                  const Icon(Icons.push_pin, size: 16, color: Colors.orange),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                news.message,
                maxLines: 3, // On limite l'aperçu dans la liste
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.4),
              ),
              const Divider(height: 24),
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: const Color(0xFF13293d).withOpacity(0.1),
                    child: const Icon(Icons.person, size: 14, color: Color(0xFF13293d)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Par ${news.staffFullName}",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
