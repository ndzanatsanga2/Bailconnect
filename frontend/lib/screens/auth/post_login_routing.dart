import 'package:flutter/material.dart';

import '../../data/auth_repository.dart';
import '../admin/admin_shell.dart';
import '../annonceur/annonceur_dashboard_screen.dart';

/// Routage automatique selon le rôle après connexion (interactive ou
/// auto-connexion au démarrage) — un admin est envoyé directement sur la
/// route dédiée du back-office ([kAdminRoute], espace totalement séparé),
/// un compte à capacité annonceur dans son espace bailleur. Un client reste
/// sur l'écran courant.
Future<void> routeAfterAuth(BuildContext context, AuthUser? user) async {
  if (user == null) return;
  if (user.role == 'admin') {
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(kAdminRoute, (route) => false);
    return;
  }
  if (user.isAnnonceur) {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AnnonceurDashboardScreen()));
  }
}
