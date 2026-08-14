import 'package:flutter/material.dart';

import '../../app_config.dart';
import '../../data/api_client.dart';
import '../../data/favorite_repository.dart';
import '../../data/feed_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../widgets/bc_badge.dart';
import '../../widgets/bc_icon.dart';
import '../auth/auth_helpers.dart';
import 'listing_detail_screen.dart';

/// Fil d'actualité mixte vidéo/photo — consultable sans connexion.
/// Fidèle au wireframe Client (section 8, écrans 1-2).
class FeedScreen extends StatefulWidget {
  final FeedFilters filters;

  const FeedScreen({super.key, this.filters = const FeedFilters()});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

enum _MediaTab { tout, videos, photos }

class _FeedScreenState extends State<FeedScreen> {
  final _feedRepository = FeedRepository(ApiClient());
  final _favoriteRepository = FavoriteRepository(ApiClient());
  _MediaTab _tab = _MediaTab.tout;
  late Future<List<PublicListing>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  @override
  void didUpdateWidget(covariant FeedScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filters != widget.filters) {
      setState(() => _future = _fetch());
    }
  }

  Future<List<PublicListing>> _fetch() {
    final media = switch (_tab) {
      _MediaTab.tout => null,
      _MediaTab.videos => 'video',
      _MediaTab.photos => 'photo',
    };
    return _feedRepository.fetch(FeedFilters(
      neighborhood: widget.filters.neighborhood,
      budgetMax: widget.filters.budgetMax,
      propertyType: widget.filters.propertyType,
      amenityIds: widget.filters.amenityIds,
      media: media,
    ));
  }

  void _setTab(_MediaTab tab) {
    setState(() {
      _tab = tab;
      _future = _fetch();
    });
  }

  Future<void> _favorite(PublicListing listing) async {
    if (listing.isFavorite) return;
    if (!await ensureAuthenticated(context, role: 'locataire')) return;
    await _favoriteRepository.add(listing.id);
    if (mounted) setState(() => _future = _fetch());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PublicListing>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erreur : ${snapshot.error}', style: const TextStyle(color: AppColors.sub)));
        }
        final listings = snapshot.data ?? [];
        if (listings.isEmpty) {
          return Stack(
            children: [
              const Center(
                child: Text('Aucun bien disponible pour le moment.', style: TextStyle(color: AppColors.sub)),
              ),
              _segmentedControl(),
            ],
          );
        }
        return Stack(
          children: [
            PageView.builder(
              scrollDirection: Axis.vertical,
              itemCount: listings.length,
              itemBuilder: (context, index) => _FeedCard(
                listing: listings[index],
                gradient: AppGradients.all[listings[index].id % AppGradients.all.length],
                onFavorite: () => _favorite(listings[index]),
                onOpen: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ListingDetailScreen(listingId: listings[index].id)),
                ),
              ),
            ),
            _segmentedControl(),
          ],
        );
      },
    );
  }

  Widget _segmentedControl() {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.45), borderRadius: BorderRadius.circular(20)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _segment('Tout', _MediaTab.tout),
              _segment('Vidéos', _MediaTab.videos),
              _segment('Photos', _MediaTab.photos),
            ],
          ),
        ),
      ),
    );
  }

  Widget _segment(String label, _MediaTab tab) {
    final selected = _tab == tab;
    return InkWell(
      onTap: () => _setTab(tab),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(color: selected ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(16)),
        child: Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: selected ? AppColors.ink : Colors.white70),
        ),
      ),
    );
  }
}

class _FeedCard extends StatelessWidget {
  final PublicListing listing;
  final Gradient gradient;
  final VoidCallback onFavorite;
  final VoidCallback onOpen;

  const _FeedCard({required this.listing, required this.gradient, required this.onFavorite, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final photos = listing.media.where((m) => m.mediaType == 'photo').toList();
    final photo = photos.isEmpty ? null : photos.first;
    final hasVideo = listing.media.any((m) => m.mediaType == 'video');

    return Stack(
      fit: StackFit.expand,
      children: [
        if (photo != null)
          Image.network('${_apiOrigin()}${photo.file}', fit: BoxFit.cover, errorBuilder: (_, _, _) => Container(decoration: BoxDecoration(gradient: gradient)))
        else
          Container(decoration: BoxDecoration(gradient: gradient)),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black.withValues(alpha: 0.25), Colors.transparent, Colors.black.withValues(alpha: 0.82)],
              stops: const [0, 0.32, 1],
            ),
          ),
        ),
        if (hasVideo)
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), shape: BoxShape.circle, border: Border.all(color: Colors.white70, width: 2)),
              child: const BcIcon('play', color: Colors.white, size: 28),
            ),
          ),
        Positioned(
          top: 60,
          left: 16,
          child: _tag(child: Row(mainAxisSize: MainAxisSize.min, children: [
            const BcIcon('pin', size: 13, color: Colors.white),
            const SizedBox(width: 5),
            Text(listing.neighborhood, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
          ])),
        ),
        Positioned(
          right: 14,
          bottom: 132,
          child: Column(
            children: [
              _sideAction(icon: 'heart', filled: listing.isFavorite, onTap: onFavorite),
              const SizedBox(height: 15),
              _sideAction(icon: 'share', onTap: () {}),
              const SizedBox(height: 15),
              _sideAction(icon: 'bookmark', onTap: () {}),
            ],
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 18,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                if (listing.verified) ...[const BcVerifiedBadge(), const SizedBox(width: 8)],
                _tag(child: Text(
                  listing.daysSinceConfirmed == 0 ? "Dispo confirmée aujourd'hui" : 'Dispo confirmée il y a ${listing.daysSinceConfirmed} j',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                )),
              ]),
              const SizedBox(height: 8),
              Text(listing.title, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
              const SizedBox(height: 9),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final a in listing.amenities.take(3))
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(9)),
                    child: Text(a.name, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
              ]),
              const SizedBox(height: 12),
              InkWell(
                onTap: onOpen,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${listing.rentAmount} FCFA', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.ink)),
                      Row(mainAxisSize: MainAxisSize.min, children: const [
                        Text('Voir', style: TextStyle(color: AppColors.greenDark, fontWeight: FontWeight.w800, fontSize: 12)),
                        BcIcon('chevron', size: 14, color: AppColors.greenDark),
                      ]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tag({required Widget child}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(11)),
        child: child,
      );

  Widget _sideAction({required String icon, bool filled = false, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.35))),
        child: Center(child: BcIcon(icon, size: 19, color: filled ? AppColors.amber : Colors.white)),
      ),
    );
  }

  String _apiOrigin() {
    final uri = Uri.parse(AppConfig.apiBaseUrl);
    return '${uri.scheme}://${uri.authority}';
  }
}
