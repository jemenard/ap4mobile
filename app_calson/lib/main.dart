import 'package:flutter/material.dart';
import 'widgets/my_flutter_app_icons.dart';
import 'widgets/carousel.dart';

import 'widgets/festival_item.dart';
import 'widgets/afficher_info.dart';
import 'widgets/section_header.dart';
import 'services/database_service.dart';
import 'models/festival.dart';
import 'widgets/home_appbar.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestion des festivals',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF406080), // Steel Blue from logo
          secondary: const Color(0xFF80A0A0), // Muted Teal from logo
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F5F7), // Light grey background
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}



//liste des images pour le carousel
final List<String> images = [
  'assets/images/afficheLogo.png',
  'assets/images/afficheNoel.jpg',
  'assets/images/afficheNoel.jpg',
  //'assets/images/usseewa.jpg',
];

final List<Widget> carouselItems = images.map((path) {
  return Container(
    margin: const EdgeInsets.all(6.0),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(8.0)),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: Image.asset(path, fit: BoxFit.cover, width: double.infinity),
    ),
  );
}).toList();

class _MyHomePageState extends State<MyHomePage> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: currentIndex,
        children: [
          _buildAccueilPage(),
          _buildListeFestivalPage(),
          _buildTicketPage(),
          _buildParamPage(),     
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (value) {
          setState(() => currentIndex = value);
        },
        destinations: const [
          NavigationDestination(
            selectedIcon: Icon(Icons.home),
            icon: Icon(Icons.home_outlined),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.music_note),
            label: 'Festivals',
          ),
          NavigationDestination(
            icon: Icon(Icons.confirmation_number_outlined),
            label: 'Tickets',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Paramètres',
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    switch (currentIndex) {
      case 0:
        return const GradientAppBar(
          title: "Bienvenue !",
          subtitle: "Trouvez vos festivals préférés",
          showLogo: true,
        );
      case 1:
        return const GradientAppBar(
          title: "Liste des festivals",
          subtitle: "Explorez tout les festivals",
          showLogo: false,
          actions: [
             Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Icon(Icons.search, color: Colors.white),
            )
          ],
        );

        case 2:
        return const GradientAppBar(
          title: "Tickets",
          subtitle: "Retrouvez vos tickets",
          showLogo: false,
        );

      case 3:
        return const GradientAppBar(
          title: "Paramètres",
          subtitle: "Configuration de l'application",
          showLogo: false,
        );
      default:
        return const GradientAppBar(title: "CaleSon");
    }
  }

  Widget _buildAccueilPage() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // News Section
          SectionHeader(title: "Actualités"),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              elevation: 4,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF406080).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.new_releases, color: Color(0xFF406080)),
                ),
                title: const Text(
                  "Dernières sorties",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text("Découvrez les festivals les plus attendus."),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Featured / Carousel Section
          SectionHeader(
            title: "En Vedette",
            onMoreTap: () => setState(() => currentIndex = 1), // Go to list
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: CarouselWidget(carouselItems: carouselItems),
          ),

          const SizedBox(height: 20),

          // Info Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Card(
              elevation: 2,
              color: Colors.grey.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Version 1.0 • En développement",
                        style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildListeFestivalPage() {
    final databaseService = DatabaseService();

    // FutureBuilder : Construit l'interface en fonction de l'état de la requête (en attente, erreur, succès)
    return FutureBuilder<List<Festival>>(
      future: databaseService.getFestivals(), // Appel asynchrone à l'API
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Affiche un rond de chargement pendant la requête
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Erreur : ${snapshot.error}"));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("Aucun festival trouvé"));
        }

        final festivals = snapshot.data!;

        return Container(
          color: Colors.white, // Changed from blue to white for better look
          alignment: Alignment.center,
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(2.0, 10.0, 2.0, 10.0),
            itemCount: festivals.length, // Nombre total de festivals
            itemBuilder: (context, index) { // Construit chaque ligne à la demande
              final festival = festivals[index];
              return GestureDetector(
                onTap: () {
                  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      // Navigation vers la page de détails en passant l'objet "festival"
                      builder: (context) => AfficherInfo(festival: festival),
                    ),
                  );
                },
                child: FestivalItem(festival: festival),
              );
            },
          ),
        );
      },
    );
  }


  
Widget _buildTicketPage() {
  return Center(
    child: Column(
      children: [
        
      ],
    ),
  );
}

  Widget _buildParamPage() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 15),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: const ListTile(
              title: Text("Configurer les paramètres de l'application"),
              subtitle: Text("Work in progress"),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: const ListTile(
              title: Text("Param 2"),
              subtitle: Text("Work in progress"),
            ),
          ),
        ],
      ),
    );
  }
}
