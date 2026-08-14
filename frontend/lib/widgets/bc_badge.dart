import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'bc_icon.dart';

enum BcListingStatus { validee, enRevue, rejetee, louee, expiree }

extension on BcListingStatus {
  String get label => switch (this) {
        BcListingStatus.validee => 'Validé',
        BcListingStatus.enRevue => 'En revue',
        BcListingStatus.rejetee => 'Rejeté',
        BcListingStatus.louee => 'Louée',
        BcListingStatus.expiree => 'Expirée',
      };

  Color get background => switch (this) {
        BcListingStatus.validee => AppColors.greenLight,
        BcListingStatus.enRevue => const Color(0xFFFCEEE2),
        BcListingStatus.rejetee => const Color(0xFFFCEEE2),
        BcListingStatus.louee => const Color(0xFFEEF2F0),
        BcListingStatus.expiree => const Color(0xFFEEF2F0),
      };

  Color get foreground => switch (this) {
        BcListingStatus.validee => AppColors.greenDark,
        BcListingStatus.enRevue => const Color(0xFFB24E1C),
        BcListingStatus.rejetee => const Color(0xFFB24E1C),
        BcListingStatus.louee => AppColors.sub,
        BcListingStatus.expiree => AppColors.sub,
      };
}

/// Pastille de statut — classe .st/.st.ok/.st.wait du wireframe.
class BcStatusBadge extends StatelessWidget {
  final BcListingStatus status;

  const BcStatusBadge(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: status.background, borderRadius: BorderRadius.circular(9)),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: status.foreground),
      ),
    );
  }
}

/// Badge « Vérifié Bailconnect » — classe .verified du wireframe.
class BcVerifiedBadge extends StatelessWidget {
  const BcVerifiedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: AppColors.greenLight, borderRadius: BorderRadius.circular(9)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
            child: const Padding(
              padding: EdgeInsets.all(2.5),
              child: BcIcon('check', size: 9, color: Colors.white),
            ),
          ),
          const SizedBox(width: 5),
          const Text(
            'Vérifié',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.greenDark),
          ),
        ],
      ),
    );
  }
}
