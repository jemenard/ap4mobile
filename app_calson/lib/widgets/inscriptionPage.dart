import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../main.dart';

class InscriptionPage extends StatefulWidget {
  const InscriptionPage({super.key});

  @override
  State<InscriptionPage> createState() => _InscriptionPageState();
}

class _InscriptionPageState extends State<InscriptionPage> {
  // Contrôleurs pour récupérer les informations saisies dans les champs du formulaire d'inscription.
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  final DatabaseService _service = DatabaseService();

  /// Méthode déclenchée pour valider et envoyer les données d'inscription.
  void _validerInscription() async {
    
    String nom = _nomController.text;
    String prenom = _prenomController.text;
    String email = _emailController.text;
    String telephone = _telController.text;
    String mdp = _passController.text;
    try
    {
      // Appel du service pour inscrire l'utilisateur.
      bool result = await _service.inscription(nom: nom, prenom: prenom, email: email, telephone: telephone, mdp: mdp);
      
      // Si l'inscription réussit et que le widget est toujours monté, redirection vers l'accueil.
      if(result && mounted)
      {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MyHomePage()));
      }
    }
    catch (e) 
    {
      if(mounted)
      {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Échec : ${e.toString()}"))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Inscription")),
      // Utilisation d'un SingleChildScrollView pour éviter les débordements de pixels (overflow) 
      // lorsque le clavier apparaît à l'écran.
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nomController,
              decoration: const InputDecoration(
                labelText: "Nom",
                border: OutlineInputBorder(),
              ),
            ),
            TextField(
              controller: _prenomController,
              decoration: const InputDecoration(
                labelText: "Prénom",
                border: OutlineInputBorder(),
              ),
            ),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),
            TextField(
              controller: _telController,
              decoration: const InputDecoration(
                labelText: "Téléphone",
                border: OutlineInputBorder(),
              ),
            ),
            TextField(
              controller: _passController,
              decoration: const InputDecoration(
                labelText: "Mot de passe",
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _validerInscription,
              child: const Text("Créer mon compte"),
            ),
          ],
        ),
      ),
    );
  }
}