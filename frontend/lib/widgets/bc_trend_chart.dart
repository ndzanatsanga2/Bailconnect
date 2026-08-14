import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class BcTrendPoint {
  final String date;
  final int count;

  const BcTrendPoint({required this.date, required this.count});
}

/// Mini graphique en barres — tendance sur N jours, pour les KPI du
/// dashboard admin. Peint directement (pas de dépendance chart externe).
class BcTrendChart extends StatelessWidget {
  final String title;
  final List<BcTrendPoint> points;
  final Color barColor;

  const BcTrendChart({
    super.key,
    required this.title,
    required this.points,
    this.barColor = AppColors.green,
  });

  @override
  Widget build(BuildContext context) {
    final total = points.fold<int>(0, (sum, p) => sum + p.count);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Text(
                '$total sur ${points.length} j',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.sub,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 84,
            child: points.every((p) => p.count == 0)
                ? const Center(
                    child: Text(
                      'Aucune activité récente.',
                      style: TextStyle(fontSize: 12, color: AppColors.sub),
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final point in points)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Tooltip(
                              message: '${point.date} · ${point.count}',
                              child: FractionallySizedBox(
                                heightFactor: _heightFactor(point.count),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: point.count == 0
                                        ? AppColors.line
                                        : barColor,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  double _heightFactor(int count) {
    final max = points
        .map((p) => p.count)
        .fold<int>(0, (a, b) => a > b ? a : b);
    if (max == 0) return 0.02;
    return (count / max).clamp(0.03, 1.0);
  }
}
