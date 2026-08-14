import 'package:flutter/material.dart';

import '../theme/breakpoints.dart';

/// Borne la largeur du contenu dans les espaces bailleur/admin (desktop),
/// centré avec des marges, pour éviter l'étirement plein écran sur les
/// grands moniteurs — sans casser le défilement du contenu qu'il enveloppe.
class BcContentBounds extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const BcContentBounds({
    super.key,
    required this.child,
    this.maxWidth = kDesktopContentMaxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
