import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'data/remote_config.dart';
import 'screens/admin/admin_shell.dart';
import 'screens/client/client_shell.dart';
import 'screens/web/web_landing_screen.dart';
import 'screens/web/web_login_screen.dart';
import 'theme/app_theme.dart';
import 'theme/breakpoints.dart';

Future<void> main() async {
  usePathUrlStrategy();
  await RemoteConfig.load();
  runApp(const BailconnectApp());
}

class BailconnectApp extends StatelessWidget {
  const BailconnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bailconnect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialRoute: '/',
      // Séparation stricte des accès : le web large (desktop) est le
      // back-office (landing + connexion, jamais l'espace client) ; l'app
      // mobile native ET le web étroit (PWA installée sur téléphone, voir
      // [isMobileLayout]) sont l'espace client (fil, recherche, favoris —
      // jamais le back-office).
      // Le back-office admin a sa propre route dédiée (kAdminRoute) — jamais
      // atteint via un bouton dans l'espace bailleur, uniquement par cette
      // URL directe ou le routage automatique au rôle à la connexion.
      routes: {
        '/': (context) => const _HomeGate(),
        kAdminRoute: (context) => const AdminShell(),
        kAdminLoginRoute: (context) => const WebLoginScreen(),
      },
    );
  }
}

/// Bascule entre l'espace client et la landing web selon [isMobileLayout] —
/// réactive : un redimensionnement de fenêtre (ou changement d'orientation)
/// reconstruit ce widget via [MediaQuery] et peut donc faire basculer l'app
/// d'un espace à l'autre en direct.
class _HomeGate extends StatelessWidget {
  const _HomeGate();

  @override
  Widget build(BuildContext context) {
    return isMobileLayout(context)
        ? const ClientShell()
        : const WebLandingScreen();
  }
}
