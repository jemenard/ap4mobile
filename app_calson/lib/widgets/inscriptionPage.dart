import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../main.dart';
import '../utils/validation_utils.dart';
import 'connexionPage.dart';

class InscriptionPage extends StatefulWidget {
  const InscriptionPage({super.key});

  @override
  State<InscriptionPage> createState() => _InscriptionPageState();
}

class _InscriptionPageState extends State<InscriptionPage> {
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  final DatabaseService _service = DatabaseService();
  bool _isLoading = false;
  PasswordValidationResult _passResult = ValidationUtils.validatePassword("");

  @override
  void initState() {
    super.initState();
    _passController.addListener(_updatePasswordStatus);
  }

  @override
  void dispose() {
    _passController.removeListener(_updatePasswordStatus);
    _passController.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _telController.dispose();
    super.dispose();
  }

  void _updatePasswordStatus() {
    setState(() {
      _passResult = ValidationUtils.validatePassword(_passController.text);
    });
  }

  /// Méthode déclenchée pour valider et envoyer les données d'inscription.
  void _validerInscription() async {
    final nom = _nomController.text.trim();
    final prenom = _prenomController.text.trim();
    final email = _emailController.text.trim();
    final telephone = _telController.text.trim();
    final mdp = _passController.text;

    // Validations locales
    if (nom.isEmpty || prenom.isEmpty || email.isEmpty || telephone.isEmpty || mdp.isEmpty) {
      _showError("Veuillez remplir tous les champs.");
      return;
    }

    if (!ValidationUtils.isValidEmail(email)) {
      _showError("Format d'e-mail invalide.");
      return;
    }

    if (!_passResult.isValid) {
      _showError("Le mot de passe ne respecte pas les critères de sécurité.");
      return;
    }

    setState(() => _isLoading = true);
    try {
      bool result = await _service.inscription(
        nom: nom, 
        prenom: prenom, 
        email: email, 
        telephone: telephone, 
        mdp: mdp
      );
      
      if (result && mounted) {
        Navigator.pushAndRemoveUntil(
          context, 
          MaterialPageRoute(builder: (context) => const MyHomePage()),
          (route) => false,
        );
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
              const Icon(Icons.person_add_alt_1_rounded, size: 60, color: Color(0xFF13293d)),
              const SizedBox(height: 16),
              const Text(
                "Créer un compte",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF13293d)),
              ),
              const SizedBox(height: 8),
              const Text(
                "Rejoignez-nous pour gérer vos réservations facilement",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 32),

              Card(
                elevation: 4,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      _buildTextField(controller: _nomController, label: "Nom", icon: Icons.person_outline),
                      const SizedBox(height: 16),
                      _buildTextField(controller: _prenomController, label: "Prénom", icon: Icons.person_outline),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _emailController, 
                        label: "Email", 
                        icon: Icons.email_outlined, 
                        keyboardType: TextInputType.emailAddress
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _telController, 
                        label: "Téléphone", 
                        icon: Icons.phone_outlined, 
                        keyboardType: TextInputType.phone
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _passController, 
                        label: "Mot de passe", 
                        icon: Icons.lock_outline, 
                        isObscure: true
                      ),
                      const SizedBox(height: 12),
                      
                      // Indicateurs de robustesse du mot de passe
                      _buildPasswordCriteria(),
                      
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _validerInscription,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF13293d),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            disabledBackgroundColor: Colors.grey,
                          ),
                          child: _isLoading 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text("Créer mon compte", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ConnexionPage()));
                     },
                     child: const Text(
                       "Connectez-vous",
                       style: TextStyle(color: Color(0xFF13293d), fontWeight: FontWeight.bold),
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

  Widget _buildPasswordCriteria() {
    return Column(
      children: [
        _buildCriteriaItem("8 caractères minimum", _passResult.hasMinLength),
        _buildCriteriaItem("Une majuscule et une minuscule", _passResult.hasUppercase && _passResult.hasLowercase),
        _buildCriteriaItem("Un chiffre", _passResult.hasDigits),
        _buildCriteriaItem("Un caractère spécial", _passResult.hasSpecialChar),
      ],
    );
  }

  Widget _buildCriteriaItem(String label, bool isValid) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(isValid ? Icons.check_circle : Icons.circle_outlined, 
               size: 14, 
               color: isValid ? Colors.green : Colors.grey),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 11, color: isValid ? Colors.green[700] : Colors.grey[600])),
        ],
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        filled: true,
        fillColor: const Color(0xFFF5F5F7),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }
}
