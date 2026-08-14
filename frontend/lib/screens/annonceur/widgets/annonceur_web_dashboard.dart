import 'package:flutter/material.dart';

import '../../../data/auth_repository.dart';
import '../../../data/lead_repository.dart';
import '../../../data/listing_repository.dart';
import '../../../data/messaging_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_gradients.dart';
import '../../../widgets/bc_badge.dart';
import '../../../widgets/bc_button.dart';
import '../../../widgets/bc_content_bounds.dart';
import '../../../widgets/bc_icon.dart';
import '../../../widgets/bc_kpi_card.dart';
import '../../../widgets/bc_logo.dart';
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

/// Espace annonceur web — fidèle à la vue « Web · Espace bailleur » du
/// dossier de conception (section 8, Bailleur), avec navigation interne
/// réelle (Biens/Demandes/Messages/Statistiques/Profil).
class AnnonceurWebDashboard extends StatelessWidget {
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

  const AnnonceurWebDashboard({
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 220,
          color: AppColors.ink,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BcLogoLockup(
                markSize: 26,
                fontSize: 15,
                textColor: Colors.white,
              ),
              const SizedBox(height: 22),
              _navItem(context, 'grid', 'Mes biens', index: 0),
              _navItem(
                context,
                'inbox',
                'Demandes',
                index: 1,
                badge: unreadLeads,
              ),
              _navItem(
                context,
                'chat',
                'Messages',
                index: 2,
                badge: unreadMessages,
              ),
              _navItem(context, 'chart', 'Statistiques', index: 3),
              _navItem(context, 'settings', 'Profil', index: 4),
              const Spacer(),
              InkWell(
                onTap: onLogout,
                borderRadius: BorderRadius.circular(11),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  child: Row(
                    children: [
                      const BcIcon('close', size: 18, color: Color(0xFF9DB8AC)),
                      const SizedBox(width: 11),
                      const Text(
                        'Déconnexion',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF9DB8AC),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: BcContentBounds(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _tabTitles[currentIndex],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _body(context),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _body(BuildContext context) {
    return switch (currentIndex) {
      0 => _biensBody(),
      1 => SizedBox(
        height: 560,
        child: AnnonceurDemandesList(
          leads: leads,
          onMarkRead: onMarkRead,
          onReply: onReplyToLead,
        ),
      ),
      2 => SizedBox(
        height: 560,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(14),
          ),
          clipBehavior: Clip.antiAlias,
          child: selectedConversation == null
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
        ),
      ),
      3 => AnnonceurStatsView(listings: listings, leads: leads),
      _ => SizedBox(
        width: 380,
        child: AnnonceurProfilView(
          user: user,
          onLogout: onLogout,
          onBackToClient: () => Navigator.of(context).pop(),
        ),
      ),
    };
  }

  Widget _biensBody() {
    final actives = listings.where((l) => l.status == 'publiee').length;
    final enValidation = listings.where((l) => l.status == 'en_attente').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: BcKpiCard(value: '$actives', label: 'Annonces actives'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: BcKpiCard(
                value: '${leads.length}',
                label: 'Demandes reçues',
                highlighted: leads.isNotEmpty,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: BcKpiCard(value: '$enValidation', label: 'En validation'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColors.paper,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Annonces',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                  BcButton(
                    label: 'Nouveau bien',
                    icon: 'plus',
                    expand: false,
                    onPressed: onNewListing,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (listings.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Aucune annonce pour l\'instant.',
                    style: TextStyle(color: AppColors.sub),
                  ),
                )
              else
                _table(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _navItem(
    BuildContext context,
    String icon,
    String label, {
    required int index,
    int badge = 0,
  }) {
    final active = currentIndex == index;
    return InkWell(
      onTap: () => onTabChanged(index),
      borderRadius: BorderRadius.circular(11),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: active ? AppColors.green : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          children: [
            BcIcon(
              icon,
              size: 18,
              color: active ? Colors.white : const Color(0xFF9DB8AC),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : const Color(0xFF9DB8AC),
                ),
              ),
            ),
            if (badge > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.amber,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$badge',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _table() {
    return Table(
      columnWidths: const {
        0: FixedColumnWidth(96),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(1.4),
        3: FlexColumnWidth(1.2),
        4: FlexColumnWidth(1.2),
        5: FlexColumnWidth(1.8),
      },
      children: [
        _tableHeaderRow(),
        for (final listing in listings) _tableRow(listing),
      ],
    );
  }

  TableRow _tableHeaderRow() {
    TextStyle style = const TextStyle(
      fontSize: 10.5,
      fontWeight: FontWeight.w700,
      color: AppColors.sub,
      letterSpacing: 0.4,
    );
    Widget cell(String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Text(text.toUpperCase(), style: style),
    );
    return TableRow(
      children: [
        cell('Aperçu'),
        cell('Bien'),
        cell('Quartier'),
        cell('Loyer'),
        cell('Statut'),
        cell(''),
      ],
    );
  }

  TableRow _tableRow(Listing listing) {
    final gradient = AppGradients.all[listing.id % AppGradients.all.length];
    Widget cell(Widget child) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: DefaultTextStyle(
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
        child: child,
      ),
    );
    return TableRow(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      children: [
        cell(
          Container(
            width: 68,
            height: 42,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        cell(Text(listing.title)),
        cell(Text(listing.neighborhood)),
        cell(Text('${listing.rentAmount} F')),
        cell(BcStatusBadge(_statusFor(listing.status))),
        cell(
          listing.status == 'publiee' || listing.status == 'expiree'
              ? FreshnessActions(
                  listing: listing,
                  repository: repository,
                  onChanged: onChanged,
                  compact: true,
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
