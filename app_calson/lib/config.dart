class Config {
  static const String apiUrlFestivals = 'http://192.168.110.16:8000/api/festivals';
  static const String apiUrlManifestations = 'http://192.168.110.16:8000/api/festival';
  static const String apiUrlDetailManifestations = 'http://192.168.110.16:8000/api/manifestation';
  static const String apiUrlConnexion = 'http://192.168.110.16:8000/api/connexion';
  static const String apiUrlConnexionStaff = 'http://192.168.110.16:8000/api/connexionstaff';
  static const String apiUrlInscription = 'http://192.168.110.16:8000/api/inscription';
  static const String apiUrlReservations = 'http://192.168.110.16:8000/api/reservations';
  static const String apiUrlReserver = 'http://192.168.110.16:8000/api/reserver';
  static const String apiUrlQrCode = 'http://192.168.110.16:8000/api/reservation';
  static const String apiUrlSendEmail = 'http://192.168.110.16:8000/api/send_email';
  static const String apiUrlNews = 'http://192.168.110.16:8000/api/actualites';
  static const String apiUrlNewsDetail = 'http://192.168.110.16:8000/api/actualite';

  /// Vérifie si une URL scannée est autorisée (whitelist)
  static bool isUrlAllowed(String url) {
    const allowedPrefix = 'http://192.168.110.16';
    const allowedPrefixHttps = 'https://192.168.110.16';
    return url.startsWith(allowedPrefix) || url.startsWith(allowedPrefixHttps);
  }
}