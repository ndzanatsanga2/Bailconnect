import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Logo Bailconnect officiel (fourni par l'utilisateur) — couleurs et forme
/// d'origine conservées telles quelles, jamais retintées.
class BcLogoMark extends StatelessWidget {
  final double size;

  const BcLogoMark({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Image.asset('assets/logo/mark.png', width: size, height: size);
  }
}

class BcWordmark extends StatelessWidget {
  final double fontSize;
  final Color color;

  const BcWordmark({super.key, this.fontSize = 22, this.color = AppColors.ink});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: color,
        ),
        children: [
          const TextSpan(text: 'bailconnect'),
          TextSpan(
            text: '.',
            style: TextStyle(color: AppColors.amber),
          ),
        ],
      ),
    );
  }
}

class BcLogoLockup extends StatelessWidget {
  final double markSize;
  final double fontSize;
  final Color textColor;

  const BcLogoLockup({
    super.key,
    this.markSize = 32,
    this.fontSize = 19,
    this.textColor = AppColors.ink,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BcLogoMark(size: markSize),
        const SizedBox(width: 10),
        BcWordmark(fontSize: fontSize, color: textColor),
      ],
    );
  }
}

/// Logo complet (icône + nom + accroche) tel que fourni — pour les contextes
/// où la place permet d'afficher l'identité complète (splash, connexion).
class BcLogoFull extends StatelessWidget {
  final double width;

  const BcLogoFull({super.key, this.width = 260});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logo/lockup.png',
      width: width,
      fit: BoxFit.contain,
    );
  }
}
