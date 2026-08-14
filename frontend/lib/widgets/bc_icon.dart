import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Icône vectorielle reprise à l'identique du sprite SVG du dossier de
/// conception (viewBox 24x24, trait 2px arrondi) — voir assets/icons/.
class BcIcon extends StatelessWidget {
  final String name;
  final double size;
  final Color? color;

  const BcIcon(this.name, {super.key, this.size = 20, this.color});

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? IconTheme.of(context).color ?? Theme.of(context).colorScheme.onSurface;
    return SvgPicture.asset(
      'assets/icons/$name.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(resolvedColor, BlendMode.srcIn),
    );
  }
}
