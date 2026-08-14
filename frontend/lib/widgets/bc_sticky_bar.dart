import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Barre d'action fixe en bas d'écran — classe .stickybar du wireframe.
class BcStickyBar extends StatelessWidget {
  final Widget child;

  const BcStickyBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: SafeArea(top: false, child: child),
    );
  }
}
