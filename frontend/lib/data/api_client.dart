import 'dart:convert';

import 'package:http/http.dart' as http;

import '../app_config.dart';
import 'token_store.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

/// Client HTTP minimal pour l'API Bailconnect : gère le token DRF et le
/// décodage JSON. L'URL de base vient de [AppConfig], jamais codée en dur.
class ApiClient {
  Future<String?> get token => TokenStore.read();

  /// [remember] pilote « Se souvenir de moi » : stockage persistant
  /// (survit à la fermeture) si vrai, en mémoire seule sinon.
  Future<void> saveToken(String token, {bool remember = true}) {
    return TokenStore.save(token, persist: remember);
  }

  Future<void> clearToken() => TokenStore.clear();

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(
      queryParameters: {
        ...uri.queryParameters,
        for (final entry in query.entries)
          entry.key: entry.value is List
              ? (entry.value as List).map((e) => e.toString()).toList()
              : entry.value.toString(),
      },
    );
  }

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final t = await token;
      if (t != null) headers['Authorization'] = 'Token $t';
    }
    return headers;
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    final response = await http.get(
      _uri(path, query),
      headers: await _headers(),
    );
    return _handle(response, authenticated: true);
  }

  Future<dynamic> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    final response = await http.post(
      _uri(path),
      headers: await _headers(auth: auth),
      body: jsonEncode(body),
    );
    return _handle(response, authenticated: auth);
  }

  Future<dynamic> delete(String path) async {
    final response = await http.delete(_uri(path), headers: await _headers());
    return _handle(response, authenticated: true);
  }

  Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    final response = await http.patch(
      _uri(path),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _handle(response, authenticated: true);
  }

  Future<dynamic> uploadFile(
    String path, {
    required String fieldName,
    required List<int> bytes,
    required String filename,
    Map<String, String> fields = const {},
  }) async {
    final request = http.MultipartRequest('POST', _uri(path));
    final t = await token;
    if (t != null) request.headers['Authorization'] = 'Token $t';
    request.fields.addAll(fields);
    request.files.add(
      http.MultipartFile.fromBytes(fieldName, bytes, filename: filename),
    );
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _handle(response, authenticated: true);
  }

  dynamic _handle(http.Response response, {required bool authenticated}) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }
    // Token invalide/expiré sur un appel authentifié : déconnexion propre
    // côté client (le prochain écran retrouvera un état non connecté).
    if (response.statusCode == 401 && authenticated) {
      TokenStore.clear();
    }
    var message = 'Erreur réseau (${response.statusCode}).';
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['detail'] != null) {
        message = decoded['detail'].toString();
      } else if (decoded is Map && decoded.isNotEmpty) {
        message = decoded.values.first is List
            ? decoded.values.first.first.toString()
            : decoded.values.first.toString();
      }
    } catch (_) {
      // Réponse non-JSON : on garde le message générique.
    }
    throw ApiException(response.statusCode, message);
  }
}
