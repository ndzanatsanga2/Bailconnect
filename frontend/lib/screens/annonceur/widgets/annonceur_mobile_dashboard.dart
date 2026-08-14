import 'package:flutter/material.dart';

import '../../../data/listing_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_gradients.dart';
import '../../../widgets/bc_badge.dart';
import '../../../widgets/bc_bottom_nav.dart';
import '../../../widgets/bc_icon.dart';
import '../../../widgets/bc_listing_card.dart';
import 'freshness_actions.dart';

/// Tableau de bord annonceur mobile — fidèle à la vue « Mobile · Tableau de
/// bord » du dossier de conception (section 8, Bailleur).
class AnnonceurMobileDashboard extends StatelessWidget {
  final List<Listing> listings;
  final VoidCallback onNewListing;
  final ListingRepository repository;
  final VoidCallback onChanged;

  const AnnonceurMobileDashboard({
    super.key,
    required this.listings,
    required this.onNewListing,
    required this.repository,
    required this.onChanged,
  });

  BcListingStatus _statusFor(String status) => switch (status) {
        'publiee' => BcListingStatus.validee,
        'rejetee' => BcListingStatus.rejetee,
        'louee' => BcListingStatus.louee,
        'expiree' => BcListingStatus.expiree,
        _ => BcListingStatus.enRevue,
      };

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Mes biens', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
                InkWell(
                  onTap: onNewListing,
                  borderRadius: BorderRadius.circular(11),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(color: AppColors.green, borderRadius: BorderRadius.circular(11)),
                    child: const Center(child: BcIcon('plus', size: 18, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(
              children: [
                Expanded(child: _kpi('${listings.length}', 'Annonces')),
                const SizedBox(width: 10),
                Expanded(child: _kpi('0', 'Demandes')),
                const SizedBox(width: 10),
                Expanded(child: _kpi('0', 'Non lues', highlighted: true)),
              ],
            ),
          ),
          Expanded(
            child: listings.isEmpty
                ? _emptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: listings.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final listing = listings[index];
                      final media = listing.media.isNotEmpty ? listing.media.first : null;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          BcListingCard(
                            thumbnailGradient: AppGradients.all[listing.id % AppGradients.all.length],
                            neighborhood: listing.neighborhood,
                            durationLabel: media?.mediaType == 'video' ? 'Vidéo' : null,
                            title: listing.title,
                            status: _statusFor(listing.status),
                            pills: ['${listing.rentAmount} F'],
                          ),
                          if (listing.status == 'publiee' || listing.status == 'expiree')
                            FreshnessActions(listing: listing, repository: repository, onChanged: onChanged),
                        ],
                      );
                    },
                  ),
          ),
          BcBottomNav(
            currentIndex: 0,
            items: const [
              BcNavItem('grid', 'Biens'),
              BcNavItem('inbox', 'Demandes'),
              BcNavItem('chart', 'Stats'),
              BcNavItem('user', 'Profil'),
            ],
            onTap: (_) {},
          ),
        ],
      ),
    );
  }

  Widget _kpi(String value, String label, {bool highlighted = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.green : AppColors.paper,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: highlighted ? Colors.white : AppColors.ink)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: highlighted ? Colors.white70 : AppColors.sub, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BcIcon('grid', size: 40, color: AppColors.sub),
            const SizedBox(height: 14),
            const Text('Aucun bien publié pour l\'instant', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text(
              'Publiez votre premier bien pour le rendre visible dans le fil.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: AppColors.sub),
            ),
          ],
        ),
      ),
    );
  }
}
