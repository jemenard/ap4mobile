import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../main.dart';
import 'connexionPage.dart';

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
      backgroundColor: const Color(0xFFF5F5F7), // Light grey background
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              const Icon(
                Icons.person_add_alt_1_rounded,
                size: 60,
                color: Color(0xFF13293d),
              ),
              const SizedBox(height: 16),
              const Text(
                "Créer un compte",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF13293d),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Rejoignez-nous pour profiter de tout les avantages",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),

              // Form
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
                      _buildTextField(
                        controller: _nomController,
                        label: "Nom",
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _prenomController,
                        label: "Prénom",
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _emailController,
                        label: "Email",
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _telController,
                        label: "Téléphone",
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _passController,
                        label: "Mot de passe",
                        icon: Icons.lock_outline,
                        isObscure: true,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _validerInscription,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF13293d),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Créer mon compte",
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
                   const Text("Déjà un compte ? "),
                   GestureDetector(
                     onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const ConnexionPage()),
                        );
                     },
                     child: const Text(
                       "Connectez-vous",
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isObscure = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: const Color(0xFFF5F5F7),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }
}