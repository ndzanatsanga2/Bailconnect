import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../data/auth_repository.dart';
import '../../theme/breakpoints.dart';
import '../admin/admin_shell.dart';
import '../annonceur/annonceur_dashboard_screen.dart';

const kAdminMobileBlockedMessage =
    "L'espace administrateur est accessible uniquement depuis un navigateur sur ordinateur (web).";

/// Routage automatique selon le rôle après connexion (interactive ou
/// auto-connexion au démarrage) — un admin est envoyé directement sur la
/// route dédiée du back-office ([kAdminRoute], espace totalement séparé),
/// un compte à capacité annonceur dans son espace bailleur. Un client reste
/// sur l'écran courant.
///
/// Sur build mobile natif ([kIsMobileApp]), un compte admin est refusé : le
/// back-office n'existe que pour le web, jamais pour l'app mobile — la
/// session est immédiatement déconnectée plutôt que de laisser le compte
/// connecté sans espace accessible.
///
/// [authRepository] et [isMobileBuild] ne sont overridables que pour les
/// tests ; en usage normal les valeurs par défaut s'appliquent toujours.
Future<void> routeAfterAuth(
  BuildContext context,
  AuthUser? user, {
  AuthRepository? authRepository,
  bool isMobileBuild = kIsMobileApp,
}) async {
  if (user == null) return;
  if (user.role == 'admin') {
    if (isMobileBuild) {
      await (authRepository ?? AuthRepository(ApiClient())).logout();
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(kAdminMobileBlockedMessage)));
      return;
    }
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
