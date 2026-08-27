import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../data/auth_repository.dart';
import '../../theme/breakpoints.dart';
import '../admin/admin_shell.dart';
import '../annonceur/annonceur_dashboard_screen.dart';

const kAdminMobileBlockedMessage =
    "L'espace administrateur est accessible uniquement depuis un navigateur sur ordinateur (web).";

const kClientWebBlockedMessage =
    "L'espace client est accessible uniquement depuis l'application mobile.";

/// Routage automatique selon le rôle après connexion (interactive ou
/// auto-connexion au démarrage) :
/// - admin → back-office ([kAdminRoute], web uniquement) ;
/// - capacité annonceur (quel que soit le rôle de base — double casquette
///   possible) → espace bailleur, accessible web et mobile ;
/// - client pur (locataire sans capacité annonceur) → reste sur l'écran
///   courant en mobile (déjà le fil client) ; sur le web, aucun espace
///   client n'existe : la session est déconnectée avec un message clair.
///
/// Sur build mobile natif ([kIsMobileApp]), un compte admin est refusé : le
/// back-office n'existe que pour le web, jamais pour l'app mobile — la
/// session est immédiatement déconnectée plutôt que de laisser le compte
/// connecté sans espace accessible. Symétriquement, sur le web, un client
/// pur est déconnecté plutôt que laissé sur une page de connexion sans suite.
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
    return;
  }
  if (!isMobileBuild) {
    await (authRepository ?? AuthRepository(ApiClient())).logout();
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text(kClientWebBlockedMessage)));
  }
}
