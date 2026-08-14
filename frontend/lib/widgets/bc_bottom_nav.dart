import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'bc_icon.dart';

class BcNavItem {
  final String icon;
  final String label;
  final int badge;

  const BcNavItem(this.icon, this.label, {this.badge = 0});
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
        boxShadow: [
          BoxShadow(
            color: Color(0x140B1512),
            blurRadius: 20,
            offset: Offset(0, -6),
          ),
        ],
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
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      BcIcon(
                        items[i].icon,
                        size: 21,
                        color: i == currentIndex
                            ? AppColors.green
                            : AppColors.sub,
                      ),
                      if (items[i].badge > 0)
                        Positioned(
                          right: -7,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            constraints: const BoxConstraints(minWidth: 14),
                            decoration: BoxDecoration(
                              color: AppColors.amber,
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Text(
                              '${items[i].badge}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    items[i].label,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: i == currentIndex
                          ? AppColors.green
                          : AppColors.sub,
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
