import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'bc_icon.dart';

class BcNavItem {
  final String icon;
  final String label;

  const BcNavItem(this.icon, this.label);
}

/// Barre de navigation basse — classe .nav du wireframe.
class BcBottomNav extends StatelessWidget {
  final List<BcNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BcBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      padding: const EdgeInsets.fromLTRB(6, 10, 6, 13),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (var i = 0; i < items.length; i++)
            InkWell(
              onTap: () => onTap(i),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BcIcon(
                    items[i].icon,
                    size: 21,
                    color: i == currentIndex ? AppColors.green : AppColors.sub,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    items[i].label,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: i == currentIndex ? AppColors.green : AppColors.sub,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
