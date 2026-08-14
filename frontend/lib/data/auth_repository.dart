import 'api_client.dart';

class AuthUser {
  final int id;
  final String? phoneNumber;
  final String? email;
  final String fullName;
  final String role;
  final bool isAnnonceur;
  final String city;
  final String whatsappNumber;
  final String annonceurType;

  AuthUser({
    required this.id,
    this.phoneNumber,
    this.email,
    required this.fullName,
    required this.role,
    required this.isAnnonceur,
    required this.city,
    required this.whatsappNumber,
    required this.annonceurType,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: json['id'] as int,
    phoneNumber: json['phone_number'] as String?,
    email: json['email'] as String?,
    fullName: json['full_name'] as String? ?? '',
    role: json['role'] as String,
    isAnnonceur: json['is_annonceur'] as bool,
    city: json['city'] as String? ?? '',
    whatsappNumber: json['whatsapp_number'] as String? ?? '',
    annonceurType: json['annonceur_type'] as String? ?? '',
  );
}

/// true si l'identifiant ressemble à un email plutôt qu'à un téléphone.
bool isEmailIdentifier(String identifier) => identifier.contains('@');

class AuthRepository {
  final ApiClient _api;

  AuthRepository(this._api);

  Map<String, dynamic> _identifierPayload(String identifier) {
    return isEmailIdentifier(identifier)
        ? {'email': identifier}
        : {'phone_number': identifier};
  }

  /// OTP — utilisé pour vérifier un compte à l'inscription et pour la
  /// réinitialisation du mot de passe (jamais pour se connecter directement).
  Future<void> requestOtp(String identifier) {
    return _api.post(
      '/api/auth/otp/request/',
      _identifierPayload(identifier),
      auth: false,
    );
  }

  /// Connexion par mot de passe. [rememberMe] pilote le stockage du token
  /// (persistant si vrai, en mémoire seule sinon — voir [TokenStore]).
  Future<AuthUser> login(
    String identifier,
    String password, {
    required bool rememberMe,
  }) async {
    final data = await _api.post('/api/auth/login/', {
      ..._identifierPayload(identifier),
      'password': password,
    }, auth: false);
    await _api.saveToken(data['token'] as String, remember: rememberMe);
    return AuthUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  /// Inscription client (locataire) — OTP envoyé par SMS au numéro fourni,
  /// mot de passe défini dès l'inscription.
  Future<AuthUser> registerClient({
    required String phoneNumber,
    required String email,
    required String fullName,
    required String city,
    required String password,
    required String passwordConfirm,
    required String code,
  }) async {
    final data = await _api.post('/api/auth/register/', {
      'role': 'locataire',
      'phone_number': phoneNumber,
      'email': email,
      'full_name': fullName,
      'city': city,
      'password': password,
      'password_confirm': passwordConfirm,
      'code': code,
    }, auth: false);
    await _api.saveToken(data['token'] as String);
    return AuthUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  /// Inscription bailleur/agent (annonceur) — OTP envoyé par SMS au numéro fourni.
  Future<AuthUser> registerAnnonceur({
    required String phoneNumber,
    required String email,
    required String fullName,
    required String whatsappNumber,
    required String annonceurType,
    required String password,
    required String passwordConfirm,
    required String code,
  }) async {
    final data = await _api.post('/api/auth/register/', {
      'role': 'annonceur',
      'phone_number': phoneNumber,
      'email': email,
      'full_name': fullName,
      'whatsapp_number': whatsappNumber,
      'annonceur_type': annonceurType,
      'password': password,
      'password_confirm': passwordConfirm,
      'code': code,
    }, auth: false);
    await _api.saveToken(data['token'] as String);
    return AuthUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  /// Réinitialisation du mot de passe — code OTP (envoyé via [requestOtp])
  /// puis nouveau mot de passe. Reconnecte automatiquement.
  Future<AuthUser> resetPassword({
    required String identifier,
    required String code,
    required String newPassword,
    required String newPasswordConfirm,
  }) async {
    final data = await _api.post('/api/auth/password/reset/confirm/', {
      ..._identifierPayload(identifier),
      'code': code,
      'new_password': newPassword,
      'new_password_confirm': newPasswordConfirm,
    }, auth: false);
    await _api.saveToken(data['token'] as String);
    return AuthUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  /// Ajoute la capacité annonceur à un compte déjà connecté (double casquette).
  Future<AuthUser> becomeAnnonceur({
    required String whatsappNumber,
    required String annonceurType,
  }) async {
    final data = await _api.post('/api/auth/capacity/annonceur/', {
      'whatsapp_number': whatsappNumber,
      'annonceur_type': annonceurType,
    });
    return AuthUser.fromJson(data as Map<String, dynamic>);
  }

  /// Défensif : une erreur de lecture du stockage (ex. plateforme sans
  /// implémentation, cas des tests) est traitée comme « non connecté »
  /// plutôt que de faire planter l'appelant.
  Future<bool> get isAuthenticated async {
    try {
      return (await _api.token) != null;
    } catch (_) {
      return false;
    }
  }

  Future<AuthUser?> me() async {
    try {
      if (await _api.token == null) return null;
      final data = await _api.get('/api/auth/me/');
      return AuthUser.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() => _api.clearToken();
}
