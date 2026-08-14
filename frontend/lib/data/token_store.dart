import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stockage du token d'authentification — deux modes selon « Se souvenir de
/// moi » :
/// - persistant : stockage sécurisé, survit à la fermeture de l'app/onglet.
/// - en mémoire seule : simple variable du process, perdue à la fermeture
///   (et, sur le web, à tout rechargement de page — limite de la plateforme).
class TokenStore {
  static const _storage = FlutterSecureStorage();
  static const _key = 'auth_token';
  static String? _memoryToken;

  static Future<void> save(String token, {required bool persist}) async {
    if (persist) {
      await _storage.write(key: _key, value: token);
      _memoryToken = null;
    } else {
      _memoryToken = token;
      await _storage.delete(key: _key);
    }
  }

  static Future<String?> read() async {
    if (_memoryToken != null) return _memoryToken;
    return _storage.read(key: _key);
  }

  static Future<void> clear() async {
    _memoryToken = null;
    await _storage.delete(key: _key);
  }
}
