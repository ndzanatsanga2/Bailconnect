import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/admin_repository.dart';
import '../../data/api_client.dart';
import '../../data/listing_repository.dart' show ListingMediaItem;
import '../../theme/app_colors.dart';
import '../../widgets/bc_badge.dart';
import '../../widgets/bc_button.dart';
import '../../widgets/bc_icon.dart';
import '../../widgets/bc_media_stage.dart';

const _statusLabels = {
  'en_attente': 'En attente',
  'publiee': 'Publiée',
  'rejetee': 'Rejetée',
  'louee': 'Louée',
  'expiree': 'Expirée',
  'archivee': 'Archivée',
};

const _propertyTypeLabels = {
  'studio': 'Studio',
  'appartement': 'Appartement',
  'chambre': 'Chambre',
  'villa': 'Villa',
};

(Color, Color) _statusColors(String status) => switch (status) {
  'publiee' => (AppColors.greenLight, AppColors.greenDark),
  'en_attente' => (AppColors.amberLight, AppColors.amber),
  'rejetee' => (AppColors.dangerLight, AppColors.danger),
  _ => (AppColors.line, AppColors.sub),
};

/// Vue détail d'une annonce depuis le back-office — ouverte en cliquant sur
/// une ligne du tableau [AdminListingsTab]. Affiche l'intégralité des champs
/// (dont les médias) et regroupe les actions de modération déjà disponibles
/// dans le tableau (valider/rejeter/archiver/supprimer), pour éviter d'avoir
/// à y retourner pour agir sur l'annonce qu'on est en train de consulter.
class AdminListingDetailScreen extends StatefulWidget {
  final int listingId;

  const AdminListingDetailScreen({super.key, required this.listingId});

  @override
  State<AdminListingDetailScreen> createState() =>
      _AdminListingDetailScreenState();
}

class _AdminListingDetailScreenState extends State<AdminListingDetailScreen> {
  final _repository = AdminRepository(ApiClient());
  late Future<AdminListingDetail> _future;
  bool _acting = false;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _future = _repository.getListing(widget.listingId);
  }

  void _reload() {
    setState(() {
      _changed = true;
      _future = _repository.getListing(widget.listingId);
    });
  }

  Future<void> _act(Future<void> Function() action) async {
    setState(() => _acting = true);
    try {
      await action();
      if (mounted) _reload();
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _delete(AdminListingDetail listing) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette annonce ?'),
        content: Text(
          '« ${listing.title} » sera définitivement supprimée, avec ses '
          'photos et vidéos. Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _acting = true);
    await _repository.deleteListing(listing.id);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: FutureBuilder<AdminListingDetail>(
            future: _future,
            builder: (context, snapshot) {
              if (!snapshot.hasData && !snapshot.hasError) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Erreur : ${snapshot.error}'));
              }
              final listing = snapshot.data!;
              return Column(
                children: [
                  _header(listing),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 760),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (listing.media.isNotEmpty) ...[
                                _mediaGallery(listing.media),
                                const SizedBox(height: 20),
                              ],
                              _infoCard(listing),
                              const SizedBox(height: 20),
                              _actions(listing),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _header(AdminListingDetail listing) {
    final (bg, fg) = _statusColors(listing.status);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.of(context).pop(_changed),
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: BcIcon('back', size: 19, color: AppColors.ink),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              listing.title,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ),
          if (listing.verified) ...[
            const BcVerifiedBadge(),
            const SizedBox(width: 8),
          ],
          BcPill(
            label: _statusLabels[listing.status] ?? listing.status,
            background: bg,
            foreground: fg,
          ),
        ],
      ),
    );
  }

  Widget _mediaGallery(List<ListingMediaItem> media) {
    return SizedBox(
      height: 260,
      child: PageView(
        controller: PageController(viewportFraction: media.length > 1 ? 0.92 : 1),
        padEnds: false,
        children: [
          for (final item in media)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: item.mediaType == 'video'
                    ? _videoThumb(item)
                    : BcMediaStage(
                        cover: Image.network(item.file, fit: BoxFit.cover),
                        contain: Image.network(item.file, fit: BoxFit.contain),
                      ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _videoThumb(ListingMediaItem item) {
    return InkWell(
      onTap: () =>
          launchUrl(Uri.parse(item.file), mode: LaunchMode.externalApplication),
      child: Container(
        color: AppColors.ink,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white24,
                child: BcIcon('play', size: 24, color: Colors.white),
              ),
              SizedBox(height: 10),
              Text(
                'Ouvrir la vidéo',
                style: TextStyle(color: Colors.white, fontSize: 12.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard(AdminListingDetail listing) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${listing.rentAmount} FCFA',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const Text(
                ' /mois',
                style: TextStyle(color: AppColors.sub, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _infoRow('pin', listing.neighborhood),
          _infoRow(
            'home',
            _propertyTypeLabels[listing.propertyType] ?? listing.propertyType,
          ),
          _infoRow('phone', listing.whatsappNumber),
          _infoRow('user', listing.ownerDisplay),
          if (listing.depositAmount > 0)
            _infoRow('chart', 'Caution : ${listing.depositAmount} FCFA'),
          if (listing.source == 'amorce' && listing.seedContactName.isNotEmpty)
            _infoRow(
              'users',
              "Contact d'amorçage : ${listing.seedContactName} · ${listing.seedContactPhone}",
            ),
          if (listing.terms.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'Modalités',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
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
            const Text(
              'Description',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              listing.description,
              style: const TextStyle(
                color: AppColors.sub,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BcIcon(icon, size: 15, color: AppColors.sub),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions(AdminListingDetail listing) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        if (listing.status == 'en_attente') ...[
          BcButton(
            label: 'Valider',
            icon: 'check',
            expand: false,
            onPressed: _acting
                ? null
                : () => _act(() => _repository.approveListing(listing.id)),
          ),
          BcButton(
            label: 'Rejeter',
            icon: 'close',
            expand: false,
            variant: BcButtonVariant.ghost,
            onPressed: _acting
                ? null
                : () => _act(() => _repository.rejectListing(listing.id)),
          ),
        ],
        if (listing.status != 'archivee')
          BcButton(
            label: 'Archiver',
            icon: 'bookmark',
            expand: false,
            variant: BcButtonVariant.ghost,
            onPressed: _acting
                ? null
                : () => _act(() => _repository.archiveListing(listing.id)),
          ),
        BcButton(
          label: 'Supprimer',
          icon: 'close',
          expand: false,
          variant: BcButtonVariant.ghost,
          onPressed: _acting ? null : () => _delete(listing),
        ),
      ],
    );
  }
}
