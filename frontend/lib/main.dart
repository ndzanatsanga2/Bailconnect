import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'screens/admin/admin_shell.dart';
import 'screens/client/client_shell.dart';
import 'screens/web/web_landing_screen.dart';
import 'screens/web/web_login_screen.dart';
import 'theme/app_theme.dart';

void main() {
  usePathUrlStrategy();
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
      // Séparation stricte des accès : le web est le back-office (landing +
      // connexion, jamais l'espace client) ; l'app mobile native est
      // l'espace client (fil, recherche, favoris — jamais le back-office).
      // Le back-office admin a sa propre route dédiée (kAdminRoute) — jamais
      // atteint via un bouton dans l'espace bailleur, uniquement par cette
      // URL directe ou le routage automatique au rôle à la connexion.
      routes: {
        '/': (context) => kIsWeb ? const WebLandingScreen() : const ClientShell(),
        kAdminRoute: (context) => const AdminShell(),
        kAdminLoginRoute: (context) => const WebLoginScreen(),
      },
    );
  }
}
