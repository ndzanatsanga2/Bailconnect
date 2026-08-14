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
    BcListingStatus.enRevue => AppColors.amberLight,
    BcListingStatus.rejetee => AppColors.dangerLight,
    BcListingStatus.louee => AppColors.line,
    BcListingStatus.expiree => AppColors.line,
  };

  Color get foreground => switch (this) {
    BcListingStatus.validee => AppColors.greenDark,
    BcListingStatus.enRevue => AppColors.amber,
    BcListingStatus.rejetee => AppColors.danger,
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
      decoration: BoxDecoration(
        color: status.background,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: status.foreground,
        ),
      ),
    );
  }
}

/// Pastille générique à couleurs libres — pour les statuts du back-office
/// admin (annonces, rôles, signalements) qui ne rentrent pas dans
/// [BcListingStatus].
class BcPill extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const BcPill({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: foreground,
        ),
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
      decoration: BoxDecoration(
        color: AppColors.greenLight,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: const BoxDecoration(
              color: AppColors.green,
              shape: BoxShape.circle,
            ),
            child: const Padding(
              padding: EdgeInsets.all(2.5),
              child: BcIcon('check', size: 9, color: Colors.white),
            ),
          ),
          const SizedBox(width: 5),
          const Text(
            'Vérifié',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.greenDark,
            ),
          ),
        ],
      ),
    );
  }
}
