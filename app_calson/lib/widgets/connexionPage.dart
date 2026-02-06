import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../main.dart';
import 'inscriptionPage.dart';

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
      // Tentative de connexion via le service dédié.
      bool result = await _databaseService.connexion(email, mdp);
      
      // Si la connexion réussit, redirection vers la page d'accueil en remplaçant la page actuelle.
      if(result){
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MyHomePage()));
      }
    }
    catch (e) 
    {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Échec : ${e.toString()}"))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Connexion")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: _mdpController,
              decoration: const InputDecoration(labelText: "Mot de passe"),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _tenterConnexion,
              child: const Text("Se connecter"),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const InscriptionPage()));
              },
              child: const Text("Pas de compte ? Inscrivez-vous"),
            )
          ],
        ),
      ),
    );
  }
}
