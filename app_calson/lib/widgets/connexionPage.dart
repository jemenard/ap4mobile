import 'package:flutter/material.dart';
import '../services/database_service.dart';
import 'inscriptionPage.dart';
import 'staffConnexionPage.dart';

class ConnexionPage extends StatefulWidget {
  const ConnexionPage({super.key});

  @override
  State<ConnexionPage> createState() => _ConnexionPageState();
}

class _ConnexionPageState extends State<ConnexionPage> {
  // Contrôleurs pour récupérer le texte saisi par l'utilisateur dans les champs Email et Mot de passe.
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mdpController = TextEditingController();
  
  final DatabaseService _databaseService = DatabaseService();

  /// Méthode déclenchée lors du clic sur le bouton "Se connecter".
  void _tenterConnexion() async {
    // Récupération des données saisies.
    String email = _emailController.text;
    String mdp = _mdpController.text;

    try
    {
      print('Tentative de connexion pour : $email');
      // Tentative de connexion via le service dédié.
      bool result = await _databaseService.connexion(email, mdp);
      print('Résultat connexion : $result');
      
      // Si la connexion réussit, on ferme simplement la page pour revenir à l'accueil
      if(result && mounted){
        print('Connexion réussie, fermeture de la page...');
        Navigator.pop(context);
      }
    }
    catch (e) 
    {
      print('ERREUR lors de la connexion : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Échec : ${e.toString()}"))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo avec long press pour accès staff
              GestureDetector(
                onLongPress: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const StaffConnexionPage()),
                  );
                },
                child: const Icon(
                  Icons.music_note_rounded,
                  size: 80,
                  color: Color(0xFF13293d),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Bienvenue !",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF13293d),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Connectez-vous pour continuer",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              
              // Formulaire dans une Card
              Card(
                elevation: 4,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: "Email",
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF5F5F7),
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _mdpController,
                        decoration: InputDecoration(
                          labelText: "Mot de passe",
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF5F5F7),
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _tenterConnexion,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF13293d),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Se connecter",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Text("Pas encore de compte ? "),
                   GestureDetector(
                     onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const InscriptionPage()),
                        );
                     },
                     child: const Text(
                       "Inscrivez-vous",
                       style: TextStyle(
                         color: Color(0xFF13293d),
                         fontWeight: FontWeight.bold,
                       ),
                     ),
                   )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
