import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../data/api_client.dart';
import '../../data/favorite_repository.dart';
import '../../data/feed_repository.dart';
import '../../data/lead_repository.dart';
import '../../data/listing_repository.dart' show ListingMediaItem;
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../widgets/bc_badge.dart';
import '../../widgets/bc_button.dart';
import '../../widgets/bc_icon.dart';
import '../auth/auth_helpers.dart';

// Hauteur approximative de BcBottomNav (superposée par-dessus le média, voir
// ClientShell.extendBody) — réservée pour que le bloc infos/actions ne passe
// pas dessous.
const _bottomNavReserve = 108.0;

ListingMediaItem? _videoOf(PublicListing listing) {
  for (final m in listing.media) {
    if (m.mediaType == 'video') return m;
  }
  return null;
}

enum _MediaTab { tout, videos, photos }

/// Fil d'annonces plein écran façon TikTok — une annonce par page, swipe
/// vertical pour naviguer, média (vidéo/photos) en arrière-plan bord à bord.
class FeedScreen extends StatefulWidget {
  final FeedFilters filters;

  /// Fausse quand un autre onglet de [ClientShell] est affiché — permet de
  /// couper la lecture vidéo quand le fil n'est pas visible.
  final bool active;

  const FeedScreen({
    super.key,
    this.filters = const FeedFilters(),
    this.active = true,
  });

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with WidgetsBindingObserver {
  final _feedRepository = FeedRepository(ApiClient());
  final _favoriteRepository = FavoriteRepository(ApiClient());
  final _leadRepository = LeadRepository(ApiClient());

  PageController _pageController = PageController();
  _MediaTab _tab = _MediaTab.tout;
  late Future<List<PublicListing>> _future;
  List<PublicListing>? _listings;
  int _currentIndex = 0;
  bool _contacting = false;

  final Map<int, VideoPlayerController> _videoControllers = {};
  final Set<int> _soundOn = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant FeedScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filters != widget.filters) {
      setState(() => _future = _load());
    }
    if (oldWidget.active != widget.active) {
      widget.active ? _syncPlayback() : _pauseAll();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncPlayback();
    } else {
      _pauseAll();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<List<PublicListing>> _load() async {
    final media = switch (_tab) {
      _MediaTab.tout => null,
      _MediaTab.videos => 'video',
      _MediaTab.photos => 'photo',
    };
    final listings = await _feedRepository.fetch(
      FeedFilters(
        neighborhood: widget.filters.neighborhood,
        budgetMax: widget.filters.budgetMax,
        propertyType: widget.filters.propertyType,
        amenityIds: widget.filters.amenityIds,
        media: media,
      ),
    );

    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    _videoControllers.clear();
    _soundOn.clear();
    _pageController.dispose();
    _pageController = PageController();
    _listings = listings;
    _currentIndex = 0;

    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncPlayback());
    }
    return listings;
  }

  void _setTab(_MediaTab tab) {
    if (_tab == tab) return;
    setState(() {
      _tab = tab;
      _future = _load();
    });
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    _syncPlayback();
  }

  /// Instancie/retient les contrôleurs vidéo pour [_currentIndex - 1, +1]
  /// (précharge la page suivante), libère le reste, joue uniquement la page
  /// active si le fil est visible.
  void _syncPlayback() {
    final listings = _listings;
    if (listings == null || listings.isEmpty || !mounted) return;

    final window = <int>{
      if (_currentIndex - 1 >= 0) _currentIndex - 1,
      _currentIndex,
      if (_currentIndex + 1 < listings.length) _currentIndex + 1,
    };

    for (final index
        in _videoControllers.keys.where((i) => !window.contains(i)).toList()) {
      _videoControllers.remove(index)?.dispose();
    }

    for (final index in window) {
      if (_videoControllers.containsKey(index)) continue;
      final video = _videoOf(listings[index]);
      if (video == null) continue;
      final controller =
          VideoPlayerController.networkUrl(
              // listing.media[].file est déjà une URL absolue (DRF la
              // construit via request.build_absolute_uri) — ne jamais la
              // reconcaténer avec l'origine de l'API sous peine d'URL cassée.
              Uri.parse(video.file),
            )
            ..setLooping(true)
            ..setVolume(_soundOn.contains(index) ? 1 : 0);
      _videoControllers[index] = controller;
      controller.initialize().then((_) {
        if (!mounted) return;
        if (index == _currentIndex && widget.active) controller.play();
        setState(() {});
      });
    }

    for (final entry in _videoControllers.entries) {
      if (entry.key == _currentIndex &&
          widget.active &&
          entry.value.value.isInitialized) {
        entry.value.play();
      } else {
        entry.value.pause();
      }
    }
  }

  void _pauseAll() {
    for (final controller in _videoControllers.values) {
      controller.pause();
    }
  }

  void _toggleSound(int index) {
    setState(() {
      _soundOn.contains(index) ? _soundOn.remove(index) : _soundOn.add(index);
    });
    _videoControllers[index]?.setVolume(_soundOn.contains(index) ? 1 : 0);
  }

  Future<void> _favorite(int index) async {
    final listings = _listings;
    if (listings == null) return;
    final listing = listings[index];
    if (!await ensureAuthenticated(context)) return;
    if (listing.isFavorite) {
      await _favoriteRepository.removeByListing(listing.id);
    } else {
      await _favoriteRepository.add(listing.id);
    }
    if (!mounted) return;
    setState(
      () => listings[index] = listing.copyWith(isFavorite: !listing.isFavorite),
    );
  }

  Future<void> _share(PublicListing listing) async {
    final text =
        '${listing.title} — ${listing.neighborhood} — ${listing.rentAmount} FCFA/mois';
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Détails copiés — vous pouvez les partager.'),
      ),
    );
  }

  Future<void> _contact(PublicListing listing) async {
    if (!await ensureAuthenticated(context)) return;
    setState(() => _contacting = true);
    try {
      final result = await _leadRepository.contact(listing.id);
      if (!mounted) return;
      if (result.pendingInvitation || result.whatsappNumber == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "L'annonceur a été invité à rejoindre Bailconnect — nous vous recontacterons dès qu'il aura confirmé.",
            ),
          ),
        );
        return;
      }
      final digits = result.whatsappNumber!.replaceAll(RegExp(r'[^0-9]'), '');
      final uri = Uri.parse('https://wa.me/$digits');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } finally {
      if (mounted) setState(() => _contacting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ColoredBox(
        color: Colors.black,
        child: FutureBuilder<List<PublicListing>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return _SkeletonPage(tab: _tab, onTabChanged: _setTab);
            }
            if (snapshot.hasError) {
              return _MessagePage(
                icon: 'close',
                message: 'Erreur : ${snapshot.error}',
                tab: _tab,
                onTabChanged: _setTab,
              );
            }
            final listings = snapshot.data ?? [];
            if (listings.isEmpty) {
              return _MessagePage(
                icon: 'home',
                message: 'Aucun bien disponible pour le moment.',
                tab: _tab,
                onTabChanged: _setTab,
              );
            }
            return Stack(
              children: [
                PageView.builder(
                  key: ValueKey(_tab),
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  itemCount: listings.length,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (context, index) => _FeedPage(
                    listing: listings[index],
                    gradient: AppGradients
                        .all[listings[index].id % AppGradients.all.length],
                    videoController: _videoControllers[index],
                    soundOn: _soundOn.contains(index),
                    onToggleSound: () => _toggleSound(index),
                    onFavorite: () => _favorite(index),
                    onShare: () => _share(listings[index]),
                    onContact: () => _contact(listings[index]),
                    contacting: _contacting,
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _FilterBar(tab: _tab, onChanged: _setTab),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final _MediaTab tab;
  final ValueChanged<_MediaTab> onChanged;

  const _FilterBar({required this.tab, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segment('play', _MediaTab.tout),
          _segment('video', _MediaTab.videos),
          _segment('images', _MediaTab.photos),
        ],
      ),
    );
  }

  Widget _segment(String icon, _MediaTab value) {
    final selected = tab == value;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(9),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: BcIcon(
          icon,
          size: 16,
          color: selected ? AppColors.greenDark : Colors.white70,
        ),
      ),
    );
  }
}

class _SkeletonPage extends StatelessWidget {
  final _MediaTab tab;
  final ValueChanged<_MediaTab> onTabChanged;

  const _SkeletonPage({required this.tab, required this.onTabChanged});

  @override
  Widget build(BuildContext context) {
    Widget bar(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
      ),
    );

    return Stack(
      children: [
        const ColoredBox(color: Color(0xFF11241C)),
        const Center(child: CircularProgressIndicator(color: Colors.white54)),
        Positioned(
          left: 18,
          right: 90,
          bottom: _bottomNavReserve + 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              bar(90, 20),
              const SizedBox(height: 14),
              bar(200, 20),
              const SizedBox(height: 8),
              bar(120, 14),
              const SizedBox(height: 10),
              bar(140, 22),
            ],
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 0,
          right: 0,
          child: Center(
            child: _FilterBar(tab: tab, onChanged: onTabChanged),
          ),
        ),
      ],
    );
  }
}

class _MessagePage extends StatelessWidget {
  final String icon;
  final String message;
  final _MediaTab tab;
  final ValueChanged<_MediaTab> onTabChanged;

  const _MessagePage({
    required this.icon,
    required this.message,
    required this.tab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const ColoredBox(color: AppColors.ink),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BcIcon(icon, size: 34, color: Colors.white54),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 0,
          right: 0,
          child: Center(
            child: _FilterBar(tab: tab, onChanged: onTabChanged),
          ),
        ),
      ],
    );
  }
}

class _FeedPage extends StatelessWidget {
  final PublicListing listing;
  final Gradient gradient;
  final VideoPlayerController? videoController;
  final bool soundOn;
  final VoidCallback onToggleSound;
  final VoidCallback onFavorite;
  final VoidCallback onShare;
  final VoidCallback onContact;
  final bool contacting;

  const _FeedPage({
    required this.listing,
    required this.gradient,
    required this.videoController,
    required this.soundOn,
    required this.onToggleSound,
    required this.onFavorite,
    required this.onShare,
    required this.onContact,
    required this.contacting,
  });

  @override
  Widget build(BuildContext context) {
    final photos = listing.media.where((m) => m.mediaType == 'photo').toList();
    final hasVideo = _videoOf(listing) != null;
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (hasVideo)
          GestureDetector(
            onTap: onToggleSound,
            child: _VideoBackground(
              controller: videoController,
              gradient: gradient,
            ),
          )
        else if (photos.isNotEmpty)
          _PhotoCarousel(photos: photos, gradient: gradient)
        else
          Container(decoration: BoxDecoration(gradient: gradient)),
        const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  Color(0xE6000000),
                ],
                stops: [0, 0.45, 1],
              ),
            ),
          ),
        ),
        if (hasVideo && !soundOn)
          const Positioned(
            top: 100,
            right: 18,
            child: IgnorePointer(child: _SoundHint()),
          ),
        Positioned(
          left: 18,
          right: 90,
          bottom: _bottomNavReserve + bottomSafe,
          child: _InfoBlock(
            listing: listing,
            contacting: contacting,
            onContact: onContact,
          ),
        ),
        Positioned(
          right: 14,
          bottom: _bottomNavReserve + bottomSafe + 6,
          child: _ActionRail(
            listing: listing,
            onFavorite: onFavorite,
            onShare: onShare,
          ),
        ),
      ],
    );
  }
}

class _SoundHint extends StatelessWidget {
  const _SoundHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(9),
      ),
      child: const Text(
        'Son coupé · touchez l\'écran',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _VideoBackground extends StatelessWidget {
  final VideoPlayerController? controller;
  final Gradient gradient;

  const _VideoBackground({required this.controller, required this.gradient});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    if (c == null || !c.value.isInitialized) {
      return Container(decoration: BoxDecoration(gradient: gradient));
    }
    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: c.value.size.width,
        height: c.value.size.height,
        child: VideoPlayer(c),
      ),
    );
  }
}

class _PhotoCarousel extends StatefulWidget {
  final List<ListingMediaItem> photos;
  final Gradient gradient;

  const _PhotoCarousel({required this.photos, required this.gradient});

  @override
  State<_PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<_PhotoCarousel> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _controller,
          scrollDirection: Axis.horizontal,
          itemCount: widget.photos.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (context, i) => Image.network(
            // listing.media[].file est déjà une URL absolue (DRF la
            // construit via request.build_absolute_uri).
            widget.photos[i].file,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                Container(decoration: BoxDecoration(gradient: widget.gradient)),
          ),
        ),
        if (widget.photos.length > 1)
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.photos.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _index ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _index
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ActionRail extends StatelessWidget {
  final PublicListing listing;
  final VoidCallback onFavorite;
  final VoidCallback onShare;

  const _ActionRail({
    required this.listing,
    required this.onFavorite,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _button(icon: 'heart', active: listing.isFavorite, onTap: onFavorite),
        const SizedBox(height: 16),
        _button(icon: 'share', onTap: onShare),
      ],
    );
  }

  Widget _button({
    required String icon,
    bool active = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.42),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: BcIcon(
            icon,
            size: 21,
            color: active ? AppColors.amber : Colors.white,
          ),
        ),
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final PublicListing listing;
  final bool contacting;
  final VoidCallback onContact;

  const _InfoBlock({
    required this.listing,
    required this.contacting,
    required this.onContact,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (listing.verified) ...[
              const BcVerifiedBadge(),
              const SizedBox(width: 6),
            ],
            _freshnessPill(),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          listing.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const BcIcon('pin', size: 13, color: Colors.white70),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                listing.neighborhood,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 19,
            ),
            children: [
              TextSpan(text: '${listing.rentAmount} FCFA'),
              const TextSpan(
                text: ' /mois',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
        if (listing.amenities.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final a in listing.amenities.take(4))
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    a.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: 14),
        BcButton(
          label: contacting ? 'Un instant...' : 'Contacter',
          icon: 'chat',
          variant: BcButtonVariant.whatsapp,
          expand: false,
          onPressed: contacting ? null : onContact,
        ),
      ],
    );
  }

  Widget _freshnessPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            listing.daysSinceConfirmed == 0
                ? "Dispo aujourd'hui"
                : 'Dispo il y a ${listing.daysSinceConfirmed} j',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
