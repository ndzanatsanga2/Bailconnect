/// Configuration de l'application, lue depuis les variables de build
/// (--dart-define), jamais codée en dur.
///
/// Exemple : flutter run --dart-define=API_BASE_URL=http://localhost:8000
class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );
}
