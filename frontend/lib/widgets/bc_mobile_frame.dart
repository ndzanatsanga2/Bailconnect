import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/breakpoints.dart';

/// Recadre un écran « mobile-first » de l'app native (espace client,
/// connexion, inscription) dans une colonne centrée de largeur raisonnable
/// sur tablette — même contenu, plus d'étirement plein écran.
///
/// Jamais appliqué sur le web : le web a sa propre mise en page plein écran
/// (landing/connexion, back-office admin, espace bailleur) — aucune
/// simulation de téléphone n'y a sa place (voir README, séparation web/mobile).
/// En dessous de [kMobileBreakpoint], rendu inchangé (déjà à la bonne taille).
class BcMobileFrame extends StatelessWidget {
  final Widget child;

  const BcMobileFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return child;
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
