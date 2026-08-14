import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../data/auth_repository.dart';
import 'login_screen.dart';
import 'open_auth_flow.dart';

/// Vérifie qu'une session est active ; sinon propose la connexion (modale
/// sur mobile, page complète sur tablette/desktop — voir [openAuthFlow]).
/// Retourne `true` si l'utilisateur est (ou vient d'être) authentifié.
Future<bool> ensureAuthenticated(BuildContext context) async {
  final authRepository = AuthRepository(ApiClient());
  if (await authRepository.isAuthenticated) return true;
  if (!context.mounted) return false;
  final result = await openAuthFlow<bool>(context, (_) => const LoginScreen());
  return result == true;
}
