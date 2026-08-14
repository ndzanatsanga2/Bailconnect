import 'package:flutter/material.dart';

import 'screens/client/client_shell.dart';
import 'theme/app_theme.dart';

void main() {
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
      home: const ClientShell(),
    );
  }
}
