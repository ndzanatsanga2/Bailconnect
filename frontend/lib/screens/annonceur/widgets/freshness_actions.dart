import 'package:flutter/material.dart';

import '../../../data/listing_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/bc_icon.dart';

/// Boutons « Toujours disponible » / « Marquer louée » — non prévus au
/// wireframe statique, ajoutés pour la fraîcheur des annonces (spec J4).
class FreshnessActions extends StatefulWidget {
  final Listing listing;
  final ListingRepository repository;
  final VoidCallback onChanged;
  final bool compact;

  const FreshnessActions({
    super.key,
    required this.listing,
    required this.repository,
    required this.onChanged,
    this.compact = false,
  });

  @override
  State<FreshnessActions> createState() => _FreshnessActionsState();
}

class _FreshnessActionsState extends State<FreshnessActions> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      widget.onChanged();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final confirmTap = _busy
        ? null
        : () =>
              _run(() => widget.repository.confirmAvailable(widget.listing.id));
    final rentedTap = _busy
        ? null
        : () => _run(() => widget.repository.markRented(widget.listing.id));

    if (widget.compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: 'Toujours disponible',
            child: _iconOnlyButton('check', confirmTap),
          ),
          const SizedBox(width: 6),
          Tooltip(
            message: 'Marquer louée',
            child: _iconOnlyButton('close', rentedTap),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: _actionButton(
              icon: 'check',
              label: 'Toujours disponible',
              onTap: confirmTap,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _actionButton(
              icon: 'close',
              label: 'Marquer louée',
              onTap: rentedTap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconOnlyButton(String icon, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.line),
          shape: BoxShape.circle,
        ),
        child: Center(child: BcIcon(icon, size: 13, color: AppColors.sub)),
      ),
    );
  }

  Widget _actionButton({
    required String icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            BcIcon(icon, size: 13, color: AppColors.sub),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.sub,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
