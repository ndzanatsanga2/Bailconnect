import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/breakpoints.dart';

/// Recadre les écrans « mobile-first » (espace client, connexion,
/// inscription) dans une colonne centrée de largeur raisonnable sur
/// desktop/tablette — même contenu, plus d'étirement plein écran.
/// En dessous de [kMobileBreakpoint], rendu inchangé (déjà à la bonne taille).
class BcMobileFrame extends StatelessWidget {
  final Widget child;

  const BcMobileFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < kMobileBreakpoint) return child;

    return ColoredBox(
      color: const Color(0xFFE7E9E6),
      child: Center(
        child: Container(
          width: kClientFrameWidth,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.bg,
            boxShadow: AppColors.cardShadowHover,
          ),
          child: child,
        ),
      ),
    );
  }
}
