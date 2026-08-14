import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Carte indicateur — classe .kpi/.kpi.g du wireframe.
class BcKpiCard extends StatelessWidget {
  final String value;
  final String label;
  final bool highlighted;

  const BcKpiCard({
    super.key,
    required this.value,
    required this.label,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.amber : AppColors.paper,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w800,
              color: highlighted ? Colors.white : AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: highlighted
                  ? Colors.white.withValues(alpha: 0.9)
                  : AppColors.sub,
            ),
          ),
        ],
      ),
    );
  }
}
