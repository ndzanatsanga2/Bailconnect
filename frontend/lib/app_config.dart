/// Configuration de l'application, lue depuis les variables de build
/// (--dart-define), jamais codée en dur.
///
/// Exemple : flutter run --dart-define=API_BASE_URL=http://localhost:8000
class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  /// Miroir front de OTP_REQUIRED (backend/config/settings.py) — doit être
  /// gardé synchronisé avec le backend visé par [apiBaseUrl] : à false,
  /// l'inscription saute l'étape du code et « mot de passe oublié » est
  /// masqué (voir README, section OTP_REQUIRED). Jamais à false pour un
  /// build de production publique.
  static const otpRequired = bool.fromEnvironment(
    'OTP_REQUIRED',
    defaultValue: true,
  );
}
