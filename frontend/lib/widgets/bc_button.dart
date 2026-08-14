import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'bc_icon.dart';

enum BcButtonVariant { primary, amber, whatsapp, ghost }

/// Bouton CTA — reprend les variantes .cta/.cta.amber/.cta.wa/.cta.ghost du wireframe.
class BcButton extends StatelessWidget {
  final String label;
  final String? icon;
  final VoidCallback? onPressed;
  final BcButtonVariant variant;
  final bool expand;

  const BcButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.variant = BcButtonVariant.primary,
    this.expand = true,
  });

  Color get _background => switch (variant) {
        BcButtonVariant.primary => AppColors.green,
        BcButtonVariant.amber => AppColors.amber,
        BcButtonVariant.whatsapp => AppColors.whatsapp,
        BcButtonVariant.ghost => AppColors.paper,
      };

  Color get _foreground => variant == BcButtonVariant.ghost ? AppColors.greenDark : Colors.white;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          BcIcon(icon!, size: 17, color: _foreground),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _foreground),
        ),
      ],
    );

    final button = ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: _background,
        foregroundColor: _foreground,
        elevation: variant == BcButtonVariant.ghost ? 0 : 2,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(13),
          side: variant == BcButtonVariant.ghost
              ? const BorderSide(color: AppColors.green, width: 1.8)
              : BorderSide.none,
        ),
      ),
      child: child,
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
