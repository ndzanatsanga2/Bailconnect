import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'bc_badge.dart';
import 'bc_icon.dart';

/// Carte annonce du tableau de bord annonceur — classe .lcard du wireframe.
class BcListingCard extends StatelessWidget {
  final Gradient thumbnailGradient;
  final String neighborhood;
  final String? durationLabel;
  final String title;
  final BcListingStatus status;
  final List<String> pills;
  final VoidCallback? onTap;

  const BcListingCard({
    super.key,
    required this.thumbnailGradient,
    required this.neighborhood,
    this.durationLabel,
    required this.title,
    required this.status,
    required this.pills,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.paper,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(17),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.07),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 132,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(gradient: thumbnailGradient),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _pillTag(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const BcIcon('pin', size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            neighborhood,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (durationLabel != null)
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: _pillTag(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const BcIcon(
                              'video',
                              size: 11,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              durationLabel!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      BcStatusBadge(status),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final pill in pills)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.greenLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            pill,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.greenDark,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pillTag({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    );
  }
}
