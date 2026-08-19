import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/api_client.dart';
import '../../data/favorite_repository.dart';
import '../../data/feed_repository.dart';
import '../../data/lead_repository.dart';
import '../../data/messaging_repository.dart';
import '../../data/report_repository.dart';
import '../../theme/amenity_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../widgets/bc_badge.dart';
import '../../widgets/bc_button.dart';
import '../../widgets/bc_chip.dart';
import '../../widgets/bc_icon.dart';
import '../../widgets/bc_mobile_frame.dart';
import '../auth/auth_helpers.dart';
import '../messaging/chat_screen.dart';

const _reportReasons = [
  ('fausse_annonce', 'Fausse annonce'),
  ('deja_loue', 'Déjà loué'),
  ('contenu_inapproprie', 'Contenu inapproprié'),
  ('autre', 'Autre'),
];

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
  final _reportRepository = ReportRepository(ApiClient());
  final _favoriteRepository = FavoriteRepository(ApiClient());
  final _messagingRepository = MessagingRepository(ApiClient());
  late Future<PublicListing> _future;
  bool _contacting = false;
  bool _messaging = false;
  bool? _favoriteOverride;

  @override
  void initState() {
    super.initState();
    _future = _feedRepository.detail(widget.listingId);
  }

  Future<void> _toggleFavorite(PublicListing listing) async {
    if (!await ensureAuthenticated(context)) return;
    final current = _favoriteOverride ?? listing.isFavorite;
    if (current) {
      await _favoriteRepository.removeByListing(listing.id);
    } else {
      await _favoriteRepository.add(listing.id);
    }
    if (!mounted) return;
    setState(() => _favoriteOverride = !current);
  }

  Future<void> _contact() async {
    if (!await ensureAuthenticated(context)) return;
    setState(() => _contacting = true);
    try {
      final result = await _leadRepository.contact(widget.listingId);
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

  /// Message en direct avec l'annonceur — en plus du contact WhatsApp, pas
  /// à sa place.
  Future<void> _openConversation() async {
    if (!await ensureAuthenticated(context)) return;
    setState(() => _messaging = true);
    try {
      final conversation = await _messagingRepository.openConversation(
        listingId: widget.listingId,
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: conversation.id,
            peerName: conversation.peerName,
            listingTitle: conversation.listingTitle,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _messaging = false);
    }
  }

  Future<void> _openReportSheet() async {
    if (!await ensureAuthenticated(context)) return;
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ReportSheet(
        repository: _reportRepository,
        listingId: widget.listingId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BcMobileFrame(
      child: Scaffold(
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
            final photos = listing.media
                .where((m) => m.mediaType == 'photo')
                .toList();
            final gradient =
                AppGradients.all[listing.id % AppGradients.all.length];

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
                                  // listing.media[].file est déjà une URL
                                  // absolue (DRF la construit via
                                  // request.build_absolute_uri).
                                  photos.first.file,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Container(
                                    decoration: BoxDecoration(
                                      gradient: gradient,
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  decoration: BoxDecoration(gradient: gradient),
                                ),
                              if (hasVideo)
                                const Center(
                                  child: CircleAvatar(
                                    radius: 28,
                                    backgroundColor: Colors.black38,
                                    child: BcIcon(
                                      'play',
                                      size: 26,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              Positioned(
                                top: 14,
                                left: 14,
                                child: _iconButton(
                                  'back',
                                  () => Navigator.of(context).pop(),
                                ),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          listing.title,
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const BcIcon(
                                              'pin',
                                              size: 13,
                                              color: AppColors.sub,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              listing.neighborhood,
                                              style: const TextStyle(
                                                color: AppColors.sub,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (listing.verified) ...[
                                    const BcVerifiedBadge(),
                                    const SizedBox(width: 8),
                                  ],
                                  InkWell(
                                    onTap: () => _toggleFavorite(listing),
                                    customBorder: const CircleBorder(),
                                    child: Container(
                                      width: 34,
                                      height: 34,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF1F5F3),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: BcIcon(
                                          'heart',
                                          size: 16,
                                          color:
                                              (_favoriteOverride ??
                                                  listing.isFavorite)
                                              ? AppColors.amber
                                              : AppColors.sub,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Text(
                                    '${listing.rentAmount} FCFA',
                                    style: const TextStyle(
                                      fontSize: 21,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const Text(
                                    ' /mois',
                                    style: TextStyle(
                                      color: AppColors.sub,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  listing.daysSinceConfirmed == 0
                                      ? "Disponibilité confirmée aujourd'hui"
                                      : 'Disponibilité confirmée il y a ${listing.daysSinceConfirmed} j',
                                  style: const TextStyle(
                                    color: AppColors.greenDark,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
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
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 11,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F3),
                                          border: Border.all(
                                            color: AppColors.line,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            11,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            BcIcon(
                                              amenityIcon(a.name),
                                              size: 17,
                                              color: AppColors.greenDark,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                a.name,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                              if (listing.terms.isNotEmpty) ...[
                                const SizedBox(height: 18),
                                const Text(
                                  'Modalités',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  listing.terms,
                                  style: const TextStyle(
                                    color: AppColors.sub,
                                    fontSize: 13,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                              if (listing.description.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                Text(
                                  listing.description,
                                  style: const TextStyle(
                                    color: AppColors.sub,
                                    fontSize: 13,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 20),
                              Center(
                                child: InkWell(
                                  onTap: _openReportSheet,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                      horizontal: 8,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const BcIcon(
                                          'flag',
                                          size: 14,
                                          color: AppColors.sub,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Signaler cette annonce',
                                          style: TextStyle(
                                            color: AppColors.sub,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                            decoration:
                                                TextDecoration.underline,
                                            decorationColor: AppColors.sub
                                                .withValues(alpha: 0.4),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
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
                    decoration: const BoxDecoration(
                      color: AppColors.paper,
                      border: Border(top: BorderSide(color: AppColors.line)),
                    ),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: _messaging ? null : _openConversation,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.line,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: _messaging
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const BcIcon(
                                      'chat',
                                      size: 19,
                                      color: AppColors.greenDark,
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: BcButton(
                            label: _contacting ? 'Un instant...' : 'Contacter',
                            icon: 'phone',
                            variant: BcButtonVariant.whatsapp,
                            onPressed: _contacting ? null : _contact,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
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
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: Center(child: BcIcon(icon, size: 16, color: Colors.white)),
      ),
    );
  }
}

/// Modale de signalement — sélection du motif + commentaire libre optionnel.
class _ReportSheet extends StatefulWidget {
  final ReportRepository repository;
  final int listingId;

  const _ReportSheet({required this.repository, required this.listingId});

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  final _descriptionController = TextEditingController();
  String _reason = _reportReasons.first.$1;
  bool _sending = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _sending = true);
    try {
      await widget.repository.report(
        widget.listingId,
        reason: _reason,
        description: _descriptionController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Merci, votre signalement a été transmis.'),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const BcIcon('flag', size: 18, color: AppColors.amber),
              const SizedBox(width: 8),
              const Text(
                'Signaler cette annonce',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            "Choisissez le motif le plus proche du problème rencontré.",
            style: TextStyle(color: AppColors.sub, fontSize: 12.5),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (value, label) in _reportReasons)
                BcChip(
                  label: label,
                  selected: _reason == value,
                  onTap: () => setState(() => _reason = value),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Détails (facultatif)',
              filled: true,
              fillColor: AppColors.bg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: AppColors.line),
              ),
            ),
          ),
          const SizedBox(height: 18),
          BcButton(
            label: _sending ? 'Envoi...' : 'Envoyer le signalement',
            icon: 'flag',
            variant: BcButtonVariant.amber,
            onPressed: _sending ? null : _submit,
          ),
        ],
      ),
    );
  }
}
