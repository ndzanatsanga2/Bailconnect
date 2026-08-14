import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Carte de base du design system — fond blanc, coins arrondis (16px),
/// ombre douce et diffuse (jamais de bordure dure). Légère élévation au
/// survol lorsqu'elle est interactive (web/desktop).
class BcCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const BcCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  @override
  State<BcCard> createState() => _BcCardState();
}

class _BcCardState extends State<BcCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: widget.padding,
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _hovering ? AppColors.cardShadowHover : AppColors.cardShadow,
      ),
      child: widget.child,
    );

    if (widget.onTap == null) return card;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: card,
      ),
    );
  }
}
