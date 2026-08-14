import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../data/auth_repository.dart';
import 'auth_entry_screen.dart';

/// Vérifie qu'une session est active ; sinon propose la connexion OTP.
/// Retourne `true` si l'utilisateur est (ou vient d'être) authentifié.
Future<bool> ensureAuthenticated(BuildContext context, {required String role}) async {
  final authRepository = AuthRepository(ApiClient());
  if (await authRepository.isAuthenticated) return true;
  if (!context.mounted) return false;
  final result = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => AuthEntryScreen(role: role)),
  );
  return result == true;
}
