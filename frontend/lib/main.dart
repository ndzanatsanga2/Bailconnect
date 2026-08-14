import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'screens/admin/admin_shell.dart';
import 'screens/client/client_shell.dart';
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
      // Le back-office admin a sa propre route dédiée (kAdminRoute) — jamais
      // atteint via un bouton dans l'app client/bailleur, uniquement par
      // cette URL directe ou le routage automatique au rôle à la connexion.
      routes: {
        '/': (context) => const ClientShell(),
        kAdminRoute: (context) => const AdminShell(),
      },
    );
  }
}
