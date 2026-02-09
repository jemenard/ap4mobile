/// Utilitaires pour la validation des entrées utilisateur.
class ValidationUtils {
  /// Valide un e-mail avec une expression régulière simple.
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  /// Valide la robustesse d'un mot de passe.
  /// Critères : 8 caractères, 1 Majuscule, 1 Chiffre, 1 Caractère spécial.
  static PasswordValidationResult validatePassword(String password) {
    return PasswordValidationResult(
      hasMinLength: password.length >= 8,
      hasUppercase: password.contains(RegExp(r'[A-Z]')),
      hasLowercase: password.contains(RegExp(r'[a-z]')),
      hasDigits: password.contains(RegExp(r'[0-9]')),
      hasSpecialChar: password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
    );
  }

  /// Vérifie si tous les critères de validation du mot de passe sont remplis.
  static bool isPasswordRobust(String password) {
    return validatePassword(password).isValid;
  }
}

/// Résultat détaillé de la validation d'un mot de passe.
class PasswordValidationResult {
  final bool hasMinLength;
  final bool hasUppercase;
  final bool hasLowercase;
  final bool hasDigits;
  final bool hasSpecialChar;

  PasswordValidationResult({
    required this.hasMinLength,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasDigits,
    required this.hasSpecialChar,
  });

  /// True si tous les critères requis sont remplis.
  bool get isValid => 
      hasMinLength && 
      hasUppercase && 
      hasLowercase && 
      hasDigits && 
      hasSpecialChar;
}
