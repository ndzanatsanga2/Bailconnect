/// Configuration de l'application, lue depuis les variables de build
/// (--dart-define), jamais codée en dur.
///
/// Exemple : flutter run --dart-define=API_BASE_URL=http://localhost:8000
class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  /// Valeur de repli pour OTP_REQUIRED (backend/config/settings.py), utilisée
  /// uniquement si GET /api/config/ est injoignable au démarrage — voir
  /// [RemoteConfig], qui est la source de vérité lue à l'exécution. Jamais à
  /// false pour un build de production publique.
  static const otpRequired = bool.fromEnvironment(
    'OTP_REQUIRED',
    defaultValue: true,
  );
}
