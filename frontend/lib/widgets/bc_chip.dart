import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Reprend la classe .chip / .chip.on du wireframe (filtres, quartiers, équipements).
class BcChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const BcChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.green : AppColors.paper,
          border: Border.all(
            color: selected ? AppColors.green : AppColors.line,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.sub,
          ),
        ),
      ),
    );
  }
}
