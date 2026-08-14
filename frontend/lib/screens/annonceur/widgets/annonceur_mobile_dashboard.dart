import 'package:flutter/material.dart';

import '../../../data/auth_repository.dart';
import '../../../data/lead_repository.dart';
import '../../../data/listing_repository.dart';
import '../../../data/messaging_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_gradients.dart';
import '../../../widgets/bc_badge.dart';
import '../../../widgets/bc_bottom_nav.dart';
import '../../../widgets/bc_icon.dart';
import '../../../widgets/bc_listing_card.dart';
import '../../messaging/chat_view.dart';
import '../../messaging/conversations_list.dart';
import 'annonceur_common.dart';
import 'freshness_actions.dart';

const _tabTitles = [
  'Mes biens',
  'Demandes',
  'Messages',
  'Statistiques',
  'Profil',
];

/// Tableau de bord annonceur mobile — fidèle à la vue « Mobile · Tableau de
/// bord » du dossier de conception (section 8, Bailleur), avec navigation
/// interne réelle (Biens/Demandes/Messages/Statistiques/Profil).
class AnnonceurMobileDashboard extends StatelessWidget {
  final List<Listing> listings;
  final List<ReceivedLead> leads;
  final List<ConversationSummary> conversations;
  final ConversationSummary? selectedConversation;
  final AuthUser? user;
  final int currentIndex;
  final ValueChanged<int> onTabChanged;
  final VoidCallback onNewListing;
  final ListingRepository repository;
  final VoidCallback onChanged;
  final ValueChanged<int> onMarkRead;
  final void Function(ReceivedLead lead) onReplyToLead;
  final void Function(ConversationSummary conversation) onOpenConversation;
  final VoidCallback onCloseConversation;
  final VoidCallback onLogout;

  const AnnonceurMobileDashboard({
    super.key,
    required this.listings,
    required this.leads,
    required this.conversations,
    required this.selectedConversation,
    required this.user,
    required this.currentIndex,
    required this.onTabChanged,
    required this.onNewListing,
    required this.repository,
    required this.onChanged,
    required this.onMarkRead,
    required this.onReplyToLead,
    required this.onOpenConversation,
    required this.onCloseConversation,
    required this.onLogout,
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
    final unreadLeads = leads.where((l) => !l.isRead).length;
    final unreadMessages = conversations.fold<int>(
      0,
      (sum, c) => sum + c.unreadCount,
    );
    final showTopBar = !(currentIndex == 2 && selectedConversation != null);

    return SafeArea(
      child: Column(
        children: [
          if (showTopBar)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _tabTitles[currentIndex],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  if (currentIndex == 0)
                    InkWell(
                      onTap: onNewListing,
                      borderRadius: BorderRadius.circular(11),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppColors.green,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Center(
                          child: BcIcon('plus', size: 18, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          if (currentIndex == 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Row(
                children: [
                  Expanded(child: _kpi('${listings.length}', 'Annonces')),
                  const SizedBox(width: 10),
                  Expanded(child: _kpi('${leads.length}', 'Demandes')),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _kpi(
                      '$unreadLeads',
                      'Non lues',
                      highlighted: unreadLeads > 0,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(child: _body(context)),
          BcBottomNav(
            currentIndex: currentIndex,
            items: [
              const BcNavItem('grid', 'Biens'),
              BcNavItem('inbox', 'Demandes', badge: unreadLeads),
              BcNavItem('chat', 'Messages', badge: unreadMessages),
              const BcNavItem('chart', 'Stats'),
              const BcNavItem('user', 'Profil'),
            ],
            onTap: onTabChanged,
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    return switch (currentIndex) {
      0 => listings.isEmpty ? _emptyState() : _biensList(),
      1 => AnnonceurDemandesList(
        leads: leads,
        onMarkRead: onMarkRead,
        onReply: onReplyToLead,
      ),
      2 =>
        selectedConversation == null
            ? ConversationsList(
                conversations: conversations,
                onOpen: onOpenConversation,
              )
            : ChatView(
                conversationId: selectedConversation!.id,
                peerName: selectedConversation!.peerName,
                listingTitle: selectedConversation!.listingTitle,
                onBack: onCloseConversation,
              ),
      3 => AnnonceurStatsView(listings: listings, leads: leads),
      _ => AnnonceurProfilView(
        user: user,
        onLogout: onLogout,
        onBackToClient: () => Navigator.of(context).pop(),
      ),
    };
  }

  Widget _biensList() {
    return ListView.separated(
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
              thumbnailGradient:
                  AppGradients.all[listing.id % AppGradients.all.length],
              neighborhood: listing.neighborhood,
              durationLabel: media?.mediaType == 'video' ? 'Vidéo' : null,
              title: listing.title,
              status: _statusFor(listing.status),
              pills: ['${listing.rentAmount} F'],
            ),
            if (listing.status == 'publiee' || listing.status == 'expiree')
              FreshnessActions(
                listing: listing,
                repository: repository,
                onChanged: onChanged,
              ),
          ],
        );
      },
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
          Text(
            value,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: highlighted ? Colors.white : AppColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: highlighted ? Colors.white70 : AppColors.sub,
              fontWeight: FontWeight.w600,
            ),
          ),
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
            const Text(
              'Aucun bien publié pour l\'instant',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
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
