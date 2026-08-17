import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../data/auth_repository.dart';

/// Garde de route — vérifie que le compte connecté a la capacité requise
/// pour rester sur l'écran courant (espace bailleur, back-office admin…),
/// indépendamment du bouton qui a permis d'y accéder (y compris
/// l'auto-connexion au démarrage, où cet écran peut être seul sur la pile).
/// Revient en arrière avec un message si ce n'est pas le cas — ou, s'il n'y
/// a rien en dessous, renvoie vers [fallbackRoute] (l'app client par défaut ;
/// le back-office admin renvoie plutôt vers sa propre page de connexion).
/// Retourne `true` si l'accès est autorisé.
Future<bool> guardRole(
  BuildContext context,
  bool Function(AuthUser user) allowed, {
  required String message,
  String fallbackRoute = '/',
}) async {
  final user = await AuthRepository(ApiClient()).me();
  if (user != null && allowed(user)) return true;
  if (!context.mounted) return false;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  final navigator = Navigator.of(context);
  if (navigator.canPop()) {
    navigator.pop();
  } else {
    navigator.pushNamedAndRemoveUntil(fallbackRoute, (route) => false);
  }
  return false;
}
