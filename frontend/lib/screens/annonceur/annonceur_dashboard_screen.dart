import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../data/listing_repository.dart';
import '../../theme/app_colors.dart';
import 'publish_listing_screen.dart';
import 'widgets/annonceur_mobile_dashboard.dart';
import 'widgets/annonceur_web_dashboard.dart';

/// Point d'entrée adaptatif : bascule mobile/web selon la largeur, comme le
/// prévoit le dossier de conception (section 8, « Mobile + web »).
class AnnonceurDashboardScreen extends StatefulWidget {
  const AnnonceurDashboardScreen({super.key});

  @override
  State<AnnonceurDashboardScreen> createState() => _AnnonceurDashboardScreenState();
}

class _AnnonceurDashboardScreenState extends State<AnnonceurDashboardScreen> {
  final _listingRepository = ListingRepository(ApiClient());
  late Future<List<Listing>> _listingsFuture;

  @override
  void initState() {
    super.initState();
    _listingsFuture = _listingRepository.myListings();
  }

  void _refresh() {
    setState(() => _listingsFuture = _listingRepository.myListings());
  }

  Future<void> _openPublishForm() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const PublishListingScreen()),
    );
    if (created == true) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: FutureBuilder<List<Listing>>(
        future: _listingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Impossible de charger vos biens : ${snapshot.error}', style: const TextStyle(color: AppColors.sub)),
            );
          }
          final listings = snapshot.data ?? [];
          return LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 860) {
                return AnnonceurWebDashboard(
                  listings: listings,
                  onNewListing: _openPublishForm,
                  repository: _listingRepository,
                  onChanged: _refresh,
                );
              }
              return AnnonceurMobileDashboard(
                listings: listings,
                onNewListing: _openPublishForm,
                repository: _listingRepository,
                onChanged: _refresh,
              );
            },
          );
        },
      ),
    );
  }
}
