import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/breakpoints.dart';

/// Point d'entrée unique pour ouvrir un écran d'authentification (connexion,
/// inscription, mot de passe oublié, code OTP) : sur mobile, une modale
/// centrée à l'arrière-plan flouté/assombri ; sur tablette/desktop, la page
/// complète habituelle (comportement inchangé — [Navigator.push] classique).
/// Utilisé uniformément par tous les écrans d'auth pour que le style reste
/// cohérent quelle que soit la profondeur de l'enchaînement.
Future<T?> openAuthFlow<T>(BuildContext context, WidgetBuilder builder) {
  final isMobile = MediaQuery.of(context).size.width < kMobileBreakpoint;
  if (!isMobile) {
    return Navigator.of(context).push<T>(MaterialPageRoute(builder: builder));
  }

  return showGeneralDialog<T>(
    context: context,
    barrierLabel: 'auth',
    barrierDismissible: true,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final scale = Tween(
        begin: 0.96,
        end: 1.0,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
      return Stack(
        children: [
          // Flou + assombrissement de l'arrière-plan — sigma constant, seule
          // l'opacité s'anime (évite de recalculer le flou à chaque frame).
          Positioned.fill(
            child: FadeTransition(
              opacity: animation,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).maybePop(),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(color: Colors.black.withValues(alpha: 0.4)),
                ),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: ScaleTransition(
                scale: scale,
                child: FadeTransition(
                  opacity: animation,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 400,
                      maxHeight: MediaQuery.of(context).size.height * 0.85,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.bg,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: AppColors.cardShadowHover,
                          ),
                          child: child,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
