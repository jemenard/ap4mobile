import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'services/database_service.dart';
import 'models/festival.dart';
import 'config.dart';

// Import des widgets personnalisés
import 'widgets/carousel.dart';
import 'widgets/festival_item.dart';
import 'widgets/afficher_info.dart';
import 'widgets/section_header.dart';
import 'widgets/home_appbar.dart';
import 'widgets/scanner.dart';
import 'widgets/connexionPage.dart';
import 'widgets/user_tickets_page.dart';
import 'widgets/news_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Initialisation de la localisation pour le formatage des dates en français
    await initializeDateFormatting('fr_FR', null);
  } catch (e) {
    debugPrint('Erreur d\'initialisation des dates : $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CaleSon - Festivals',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF13293d), 
          secondary: const Color(0xFF2a4e6c),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F5F7), // Gris très clair pour un look premium
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

class _MyHomePageState extends State<MyHomePage> {
  // Index de la page actuellement affichée dans l'IndexedStack
  int currentIndex = 0;
  final DatabaseService _databaseService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    // Construction dynamique de la barre de navigation selon les droits de l'utilisateur
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

    // Mapping pour lier l'index visuel de la barre à l'index technique de l'IndexedStack
    // Stack Index convention: 0:Accueil, 1:Festivals, 2:Tickets, 3:Scanner, 4:Paramètres
    final Map<int, int> barToStack = {0: 0, 1: 1};

    if (_databaseService.isLoggedIn && !_databaseService.isAdmin) {
      barToStack[destinations.length] = 2; // Accès aux tickets
      destinations.add(const NavigationDestination(
        icon: Icon(Icons.confirmation_number_outlined),
        label: 'Tickets',
      ));
    }

    if (_databaseService.isAdmin) {
      barToStack[destinations.length] = 3; // Accès scanner (Admin uniquement)
      destinations.add(const NavigationDestination(
        icon: Icon(Icons.qr_code),
        label: 'Scanner',
      ));
    }

    // Paramètres : toujours présent en dernière position
    final int settingsBarIndex = destinations.length;
    barToStack[settingsBarIndex] = 4;
    destinations.add(const NavigationDestination(
      icon: Icon(Icons.settings),
      label: 'Paramètres',
    ));

    // Détermination de l'index à surligner dans la barre
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
          _buildScannerPage(),
          _buildParamPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedBarIndex,
        onDestinationSelected: (value) async {
          int targetStackIndex = barToStack[value] ?? 0;
          
          // Vérification spécifique pour le scanner
          if (targetStackIndex == 3) {
            bool active = await _databaseService.isFestivalActive();
            if (!active && mounted) {
              _showNoFestivalDialog();
              return;
            }
          }

          // Protection : redirection si accès non autorisé
          if (!_databaseService.isLoggedIn && (targetStackIndex == 2 || targetStackIndex == 3)) {
            targetStackIndex = 4;
          }

          if (mounted) {
            setState(() => currentIndex = targetStackIndex);
          }
        },
        destinations: destinations,
      ),
    );
  }

  /// Dialogue d'alerte si aucun festival n'est en cours (pour le scanner).
  void _showNoFestivalDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Accès restreint"),
        content: const Text("Le scanner n'est disponible que lorsqu'un festival est en cours."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  /// Gère l'action d'authentification dans l'AppBar.
  Widget _buildAuthAction() {
    return IconButton(
      icon: Icon(
        _databaseService.isLoggedIn ? Icons.logout : Icons.account_circle,
        color: Colors.white,
      ),
      onPressed: () {
        if (_databaseService.isLoggedIn) {
          setState(() {
            _databaseService.deconnexion();
            currentIndex = 0;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Déconnexion réussie.")),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ConnexionPage()),
          ).then((_) {
            setState(() {}); // Rafraîchissement pour mettre à jour la barre de navigation
          });
        }
      },
      tooltip: _databaseService.isLoggedIn ? "Se déconnecter" : "Se connecter",
    );
  }

  /// Génère l'AppBar adaptée à la page courante.
  PreferredSizeWidget _buildAppBar() {
    switch (currentIndex) {
      case 0:
        return GradientAppBar(
          title: "Bienvenue !",
          subtitle: "${DateTime.now().hour < 18 ? 'Bonne journée' : 'Bonne soirée'} sur CaleSon",
          showLogo: true,
          actions: [_buildAuthAction()],
        );
      case 1:
        return GradientAppBar(
          title: "Festivals",
          subtitle: "Découvrez tous les événements à venir",
          showLogo: false,
          actions: [
            const Icon(Icons.search, color: Colors.white),
            _buildAuthAction()
          ],
        );
      case 2:
        return GradientAppBar(
          title: "Mes Tickets",
          subtitle: "Gérez vos réservations",
          showLogo: false,
          actions: [_buildAuthAction()],
        );
      case 3:
        return GradientAppBar(
          title: "Scanner",
          subtitle: "Contrôle d'accès",
          showLogo: false,
          actions: [_buildAuthAction()],
        );
      case 4:
        return GradientAppBar(
          title: "Paramètres",
          subtitle: "Configuration du compte",
          showLogo: false,
          actions: [_buildAuthAction()],
        );
      default:
        return const GradientAppBar(title: "CaleSon");
    }
  }

  /// Page d'accueil : Actualités et Mise en vedette.
  Widget _buildAccueilPage() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          SectionHeader(title: "Actualités"),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NewsPage()),
                  );
                },
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF13293d).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.new_releases, color: Color(0xFF13293d)),
                ),
                title: const Text("Dernières sorties", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("Découvrez les dernières nouvelles et annonces."),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
            ),
          ),

          const SizedBox(height: 20),
          SectionHeader(
            title: "En Vedette",
            onMoreTap: () => setState(() => currentIndex = 1),
          ),
          
          FutureBuilder<List<Festival>>(
            future: _databaseService.getFestivals(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
              }
              
              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: Text("Aucun festival à l'affiche")),
                );
              }

              final festivals = snapshot.data!;
              final carouselItems = festivals.map((festival) {
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AfficherInfo(festival: festival)),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(6.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.0),
                      child: (festival.urlLogo != null && festival.urlLogo!.isNotEmpty)
                        ? Image.network(
                            festival.urlLogo!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) => _buildPlaceholderLogo(),
                          )
                        : _buildPlaceholderLogo(),
                    ),
                  ),
                );
              }).toList();

              return CarouselWidget(carouselItems: carouselItems);
            },
          ),

          const SizedBox(height: 20),
          _buildInfoFooter(),
        ],
      ),
    );
  }

  Widget _buildPlaceholderLogo() {
    return Container(
      color: Colors.grey.shade200,
      child: const Icon(Icons.music_note, size: 50, color: Colors.grey),
    );
  }

  Widget _buildInfoFooter() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 0,
        color: Colors.grey.shade100,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.grey, size: 20),
              SizedBox(width: 12),
              Text("Application CaleSon • v1.0.0", style: TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  /// Page Liste des Festivals : Affichage sous forme de liste défilante.
  Widget _buildListeFestivalPage() {
    return FutureBuilder<List<Festival>>(
      future: _databaseService.getFestivals(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Erreur de chargement des festivals"));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("Aucun festival disponible"));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 10),
          itemCount: snapshot.data!.length, 
          itemBuilder: (context, index) {
            final festival = snapshot.data![index];
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AfficherInfo(festival: festival)),
              ),
              child: FestivalItem(festival: festival),
            );
          },
        );
      },
    );
  }

  /// Page Mes Tickets : Redirection vers UserTicketsPage.
  Widget _buildTicketPage() {
    return UserTicketsPage(key: UniqueKey());
  }

  /// Page Scanner : Interface pour le contrôle d'accès QR Code.
  Widget _buildScannerPage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.qr_code_scanner, size: 80, color: Color(0xFF13293d)),
          const SizedBox(height: 20),
          const Text("Prêt à scanner ?", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () async {
              // Vérifie à nouveau si un festival est actif avant d'ouvrir la caméra
              bool active = await _databaseService.isFestivalActive();
              if (!active && mounted) {
                _showNoFestivalDialog();
                return;
              }

              final String? result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Scanner()),
              );

              if (result != null && mounted) {
                _handleScannerResult(result);
              }
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text("Lancer le scanner"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF13293d),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  /// Traitement du résultat scanné avec validation de sécurité.
  void _handleScannerResult(String result) async {
    if (result.startsWith('http://') || result.startsWith('https://')) {
      if (Config.isUrlAllowed(result)) {
        final Uri url = Uri.parse(result);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          _showToast("Impossible d'ouvrir l'URL : $result");
        }
      } else {
        _showToast("Accès refusé : ce code QR n'est pas autorisé.", isError: true);
      }
    } else {
      _showToast("Code détecté : $result");
    }
  }

  void _showToast(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  /// Page Paramètres : Placeholder pour les réglages.
  Widget _buildParamPage() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.settings_suggest, size: 60, color: Colors.grey),
          SizedBox(height: 16),
          Text("Paramètres bientôt disponibles", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
