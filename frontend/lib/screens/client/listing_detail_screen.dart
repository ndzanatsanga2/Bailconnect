import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app_config.dart';
import '../../data/api_client.dart';
import '../../data/feed_repository.dart';
import '../../data/lead_repository.dart';
import '../../theme/amenity_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../widgets/bc_badge.dart';
import '../../widgets/bc_button.dart';
import '../../widgets/bc_icon.dart';
import '../auth/auth_helpers.dart';

/// Fiche bien — galerie, prix, modalités, badge Vérifié, fraîcheur, contact.
/// Fidèle au wireframe Client (écran 5), sans palier token (MVP gratuit).
class ListingDetailScreen extends StatefulWidget {
  final int listingId;

  const ListingDetailScreen({super.key, required this.listingId});

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  final _feedRepository = FeedRepository(ApiClient());
  final _leadRepository = LeadRepository(ApiClient());
  late Future<PublicListing> _future;
  bool _contacting = false;

  @override
  void initState() {
    super.initState();
    _future = _feedRepository.detail(widget.listingId);
  }

  Future<void> _contact() async {
    if (!await ensureAuthenticated(context, role: 'locataire')) return;
    setState(() => _contacting = true);
    try {
      final result = await _leadRepository.contact(widget.listingId);
      if (!mounted) return;
      if (result.pendingInvitation || result.whatsappNumber == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("L'annonceur a été invité à rejoindre Bailconnect — nous vous recontacterons dès qu'il aura confirmé.")),
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
    return Scaffold(
      body: FutureBuilder<PublicListing>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }
          final listing = snapshot.data!;
          final hasVideo = listing.media.any((m) => m.mediaType == 'video');
          final photos = listing.media.where((m) => m.mediaType == 'photo').toList();
          final gradient = AppGradients.all[listing.id % AppGradients.all.length];

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 220,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (photos.isNotEmpty)
                              Image.network(
                                '${_apiOrigin()}${photos.first.file}',
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(decoration: BoxDecoration(gradient: gradient)),
                              )
                            else
                              Container(decoration: BoxDecoration(gradient: gradient)),
                            if (hasVideo)
                              const Center(
                                child: CircleAvatar(
                                  radius: 28,
                                  backgroundColor: Colors.black38,
                                  child: BcIcon('play', size: 26, color: Colors.white),
                                ),
                              ),
                            Positioned(
                              top: 14,
                              left: 14,
                              child: _iconButton('back', () => Navigator.of(context).pop()),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(listing.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                                      const SizedBox(height: 4),
                                      Row(children: [
                                        const BcIcon('pin', size: 13, color: AppColors.sub),
                                        const SizedBox(width: 4),
                                        Text(listing.neighborhood, style: const TextStyle(color: AppColors.sub, fontSize: 12, fontWeight: FontWeight.w600)),
                                      ]),
                                    ],
                                  ),
                                ),
                                if (listing.verified) const BcVerifiedBadge(),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(children: [
                              Text('${listing.rentAmount} FCFA', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
                              const Text(' /mois', style: TextStyle(color: AppColors.sub, fontSize: 13)),
                            ]),
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                listing.daysSinceConfirmed == 0 ? "Disponibilité confirmée aujourd'hui" : 'Disponibilité confirmée il y a ${listing.daysSinceConfirmed} j',
                                style: const TextStyle(color: AppColors.greenDark, fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ),
                            if (listing.amenities.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              GridView.count(
                                crossAxisCount: 2,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                mainAxisSpacing: 9,
                                crossAxisSpacing: 9,
                                childAspectRatio: 3.4,
                                children: [
                                  for (final a in listing.amenities)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 11),
                                      decoration: BoxDecoration(color: const Color(0xFFF1F5F3), border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(11)),
                                      child: Row(children: [
                                        BcIcon(amenityIcon(a.name), size: 17, color: AppColors.greenDark),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(a.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
                                      ]),
                                    ),
                                ],
                              ),
                            ],
                            if (listing.terms.isNotEmpty) ...[
                              const SizedBox(height: 18),
                              const Text('Modalités', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 6),
                              Text(listing.terms, style: const TextStyle(color: AppColors.sub, fontSize: 13, height: 1.5)),
                            ],
                            if (listing.description.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              Text(listing.description, style: const TextStyle(color: AppColors.sub, fontSize: 13, height: 1.5)),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  decoration: const BoxDecoration(color: AppColors.paper, border: Border(top: BorderSide(color: AppColors.line))),
                  child: BcButton(
                    label: _contacting ? 'Un instant...' : 'Contacter',
                    icon: 'chat',
                    variant: BcButtonVariant.whatsapp,
                    onPressed: _contacting ? null : _contact,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _iconButton(String icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), shape: BoxShape.circle),
        child: Center(child: BcIcon(icon, size: 16, color: Colors.white)),
      ),
    );
  }

  String _apiOrigin() {
    final uri = Uri.parse(AppConfig.apiBaseUrl);
    return '${uri.scheme}://${uri.authority}';
  }
}
