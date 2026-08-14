import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'bc_icon.dart';

/// Barre supérieure du back-office admin — titre de section + action de
/// déconnexion, au-dessus du contenu de chaque onglet.
class BcTopBar extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onLogout;
  final Widget? leading;

  const BcTopBar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onLogout,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 14)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11.5, color: AppColors.sub),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onLogout,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BcIcon('user', size: 15, color: AppColors.sub),
                  const SizedBox(width: 8),
                  const Text(
                    'Admin',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(width: 1, height: 14, color: AppColors.line),
                  const SizedBox(width: 10),
                  const Text(
                    'Déconnexion',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.sub,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
