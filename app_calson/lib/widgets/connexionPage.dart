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
  // 1. Déclarer les contrôleurs pour récupérer le texte
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mdpController = TextEditingController();
  
  final DatabaseService _databaseService = DatabaseService();

  void _tenterConnexion() async {
    // On récupère les valeurs
    String email = _emailController.text;
    String mdp = _mdpController.text;

    try
    {
      // Appeler DatabaseService
      bool result = await _databaseService.connexion(email, mdp);
      // Naviguer vers la page d'accueil
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
