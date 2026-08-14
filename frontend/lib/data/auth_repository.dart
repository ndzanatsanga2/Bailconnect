import 'api_client.dart';

class AuthUser {
  final int id;
  final String? phoneNumber;
  final String? email;
  final String fullName;
  final String role;

  AuthUser({required this.id, this.phoneNumber, this.email, required this.fullName, required this.role});

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as int,
        phoneNumber: json['phone_number'] as String?,
        email: json['email'] as String?,
        fullName: json['full_name'] as String? ?? '',
        role: json['role'] as String,
      );
}

/// true si l'identifiant ressemble à un email plutôt qu'à un téléphone.
bool isEmailIdentifier(String identifier) => identifier.contains('@');

class AuthRepository {
  final ApiClient _api;

  AuthRepository(this._api);

  Map<String, dynamic> _identifierPayload(String identifier) {
    return isEmailIdentifier(identifier) ? {'email': identifier} : {'phone_number': identifier};
  }

  Future<void> requestOtp(String identifier) {
    return _api.post('/api/auth/otp/request/', _identifierPayload(identifier), auth: false);
  }

  Future<AuthUser> verifyOtp(String identifier, String code, {String? role}) async {
    final data = await _api.post(
      '/api/auth/otp/verify/',
      {
        ..._identifierPayload(identifier),
        'code': code,
        'role': ?role,
      },
      auth: false,
    );
    await _api.saveToken(data['token'] as String);
    return AuthUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<bool> get isAuthenticated async => (await _api.token) != null;

  Future<AuthUser?> me() async {
    if (await _api.token == null) return null;
    try {
      final data = await _api.get('/api/auth/me/');
      return AuthUser.fromJson(data as Map<String, dynamic>);
    } on ApiException {
      return null;
    }
  }

  Future<void> logout() => _api.clearToken();
}
