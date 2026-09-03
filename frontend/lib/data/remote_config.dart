import '../app_config.dart';
import 'api_client.dart';

/// Config runtime lue depuis GET /api/config/ au démarrage — reflète
/// OTP_REQUIRED côté backend (backend/config/settings.py) sans dépendre
/// d'un flag de build (--dart-define) qui pourrait diverger du backend
/// ciblé. [AppConfig.otpRequired] sert de valeur de repli si l'appel
/// échoue (ex. backend injoignable au lancement).
class RemoteConfig {
  static bool otpRequired = AppConfig.otpRequired;

  static Future<void> load() async {
    try {
      final response = await ApiClient()
          .get('/api/config/')
          .timeout(const Duration(seconds: 3));
      if (response is Map && response['otp_required'] is bool) {
        otpRequired = response['otp_required'] as bool;
      }
    } catch (_) {
      // Backend injoignable au démarrage : on garde la valeur de repli.
    }
  }
}
