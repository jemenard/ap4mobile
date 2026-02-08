import 'package:flutter/material.dart';
import 'widgets/carousel.dart';
import 'package:url_launcher/url_launcher.dart';
import 'widgets/festival_item.dart';
import 'widgets/afficher_info.dart';
import 'widgets/section_header.dart';
import 'services/database_service.dart';
import 'models/festival.dart';
import 'widgets/home_appbar.dart';
import 'package:flutter/services.dart';
import 'widgets/scanner.dart';
import 'widgets/connexionPage.dart';
import 'widgets/user_tickets_page.dart';

import 'package:intl/date_symbol_data_local.dart';

void main() async {
  print('=== APP STARTING ===');
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initializeDateFormatting('fr_FR', null);
    print('Date formatting initialized');
  } catch (e) {
    print('Failed to initialize date formatting: $e');
  }
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
          seedColor: const Color(0xFF13293d), 
          secondary: const Color(0xFF2a4e6c),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F5F7),
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



// Liste des chemins d'accès aux images affichées dans le carousel d'accueil.
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
  final DatabaseService _databaseService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    // Liste dynamique des destinations basée sur l'état de connexion/admin
    final List<NavigationDestination> destinations = [
      const NavigationDestination(
        selectedIcon: Icon(Icons.home),
        icon: Icon(Icons.home_outlined),
        label: 'Accueil',
      ),
      const NavigationDestination(
        icon: Icon(Icons.music_note),
        label: 'Festivals',
      ),
    ];

    // Map pour convertir l'index de la barre vers l'index de l'IndexedStack
    // Stack Index: 0:Accueil, 1:Festivals, 2:Tickets, 3:Scanner, 4:Paramètres
    final Map<int, int> barToStack = {0: 0, 1: 1};

    if (_databaseService.isLoggedIn) {
      barToStack[destinations.length] = 2; // Tickets
      destinations.add(const NavigationDestination(
        icon: Icon(Icons.confirmation_number_outlined),
        label: 'Tickets',
      ));
    }

    if (_databaseService.isAdmin) {
      barToStack[destinations.length] = 3; // Scanner
      destinations.add(const NavigationDestination(
        icon: Icon(Icons.qr_code),
        label: 'Scanner',
      ));
    }

    // Paramètres est toujours le dernier élément de la barre
    final int settingsBarIndex = destinations.length;
    barToStack[settingsBarIndex] = 4;
    destinations.add(const NavigationDestination(
      icon: Icon(Icons.settings),
      label: 'Paramètres',
    ));

    // Déterminer l'index sélectionné dans la barre à partir de currentIndex
    int selectedBarIndex = 0;
    barToStack.forEach((barIdx, stackIdx) {
      if (stackIdx == currentIndex) selectedBarIndex = barIdx;
    });

    return Scaffold(
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: currentIndex,
        children: [
          _buildAccueilPage(),
          _buildListeFestivalPage(),
          _buildTicketPage(),
          _buildscannerPage(),
          _buildParamPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedBarIndex,
        onDestinationSelected: (value) {
          int targetStackIndex = barToStack[value] ?? 0;
          print('Navigation: BarIndex $value -> StackIndex $targetStackIndex');
          
          // Sécurité : si on n'est pas connecté et qu'on essaie d'aller sur Tickets/Scanner
          // On redirige vers Paramètres
          if (!_databaseService.isLoggedIn && (targetStackIndex == 2 || targetStackIndex == 3)) {
            targetStackIndex = 4;
          }

          setState(() => currentIndex = targetStackIndex);
        },
        destinations: destinations,
      ),
    );
  }

  /// Construit le bouton d'action pour la connexion/déconnexion dans la barre d'application.
  Widget _buildAuthAction() {
    return IconButton(
      icon: Icon(
        _databaseService.isLoggedIn ? Icons.logout : Icons.account_circle,
        color: Colors.white,
      ),
      onPressed: () {
        if (_databaseService.isLoggedIn) {
          // Déconnexion
          setState(() {
            _databaseService.deconnexion();
            currentIndex = 0; // Retour à l'accueil après déconnexion
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Vous avez été déconnecté.")),
          );
        } else {
          // Navigation vers la page de connexion
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ConnexionPage()),
          ).then((_) {
            print('Retour de ConnexionPage. LoggedIn: ${_databaseService.isLoggedIn}');
            setState(() {}); // Rafraîchir pour afficher l'onglet Tickets
          });
        }
      },
      tooltip: _databaseService.isLoggedIn ? "Se déconnecter" : "Se connecter",
    );
  }

  PreferredSizeWidget _buildAppBar() {
    switch (currentIndex) {
      case 0:
        return GradientAppBar(
          title: "Bienvenue !",
          subtitle: "Trouvez vos festivals préférés",
          showLogo: true,
          actions: [_buildAuthAction()],
        );
      case 1:
        return GradientAppBar(
          title: "Liste des festivals",
          subtitle: "Explorez tout les festivals",
          showLogo: false,
          actions: [
             const Padding(
              padding: EdgeInsets.only(right: 8.0), // Reduced because we add another icon
              child: Icon(Icons.search, color: Colors.white),
            ),
            _buildAuthAction(),
          ],
        
        );

        case 2:
        return GradientAppBar(
          title: "Tickets",
          subtitle: "Retrouvez vos tickets",
          showLogo: false,
          actions: [_buildAuthAction()],
        );

        case 3:
        return GradientAppBar(
          title: "Scanner",
          subtitle: "Scanner un code QR",
          showLogo: false,
          actions: [
             const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: Icon(Icons.qr_code_scanner, color: Colors.white),
            ),
            _buildAuthAction(),
          ],
        );

      case 4:
        return GradientAppBar(
          title: "Paramètres",
          subtitle: "Configuration de l'application",
          showLogo: false,
          actions: [_buildAuthAction()],
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
                    color: const Color(0xFF13293d).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.new_releases, color: Color(0xFF13293d)),
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

    // Widget FutureBuilder pour gérer l'état asynchrone de la récupération des festivals.
    return FutureBuilder<List<Festival>>(
      future: databaseService.getFestivals(), // Appel au service pour récupérer les données.
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Affichage d'un indicateur de chargement pendant la requête réseau.
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
            itemCount: festivals.length, 
            itemBuilder: (context, index) { // Construction dynamique des éléments de la liste.
              final festival = festivals[index];
              return GestureDetector(
                onTap: () {
                  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      // Navigation vers la page de détails du festival sélectionné.
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
  return UserTicketsPage(key: UniqueKey());
}


Widget _buildscannerPage() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.qr_code_scanner, size: 80, color: Color(0xFF13293d)),
        const SizedBox(height: 20),
        const Text(
          "Prêt à scanner ?",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 30),
        ElevatedButton.icon(
          onPressed: () async 
          {
            final String? result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const Scanner()),
            );
            if (result != null && mounted) {
            // Vérifie si le résultat ressemble à une URL
            if (result.startsWith('http://') || result.startsWith('https://')) {
              final Uri url = Uri.parse(result);
              // Si le résultat est une URL valide, tentative d'ouverture dans le navigateur.
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Impossible d'ouvrir l'URL : $result")),
                );
              }
            } else {
              // Si le résultat n'est pas une URL, affichage du contenu brut dans une SnackBar.
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Code détecté : $result")),
              );
            }
          }
          },
          icon: const Icon(Icons.camera_alt),
          label: const Text("Ouvrir le scanner"),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF13293d),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
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
        ],
      ),
    );
  }
}
