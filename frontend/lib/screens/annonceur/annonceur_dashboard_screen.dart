import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../data/auth_repository.dart';
import '../../data/lead_repository.dart';
import '../../data/listing_repository.dart';
import '../../data/messaging_repository.dart';
import '../../theme/app_colors.dart';
import '../auth/role_guard.dart';
import 'publish_listing_screen.dart';
import 'widgets/annonceur_mobile_dashboard.dart';
import 'widgets/annonceur_web_dashboard.dart';

const _pollInterval = Duration(seconds: 10);

class _DashboardData {
  final List<Listing> listings;
  final List<ReceivedLead> leads;
  final List<ConversationSummary> conversations;
  final AuthUser? me;

  _DashboardData(this.listings, this.leads, this.conversations, this.me);
}

/// Point d'entrée adaptatif : bascule mobile/web selon la largeur, comme le
/// prévoit le dossier de conception (section 8, « Mobile + web »). Réservé
/// aux comptes ayant la capacité annonceur (garde de route, voir role_guard).
class AnnonceurDashboardScreen extends StatefulWidget {
  const AnnonceurDashboardScreen({super.key});

  @override
  State<AnnonceurDashboardScreen> createState() =>
      _AnnonceurDashboardScreenState();
}

class _AnnonceurDashboardScreenState extends State<AnnonceurDashboardScreen> {
  final _listingRepository = ListingRepository(ApiClient());
  final _leadRepository = LeadRepository(ApiClient());
  final _messagingRepository = MessagingRepository(ApiClient());
  final _authRepository = AuthRepository(ApiClient());

  int _tabIndex = 0;
  ConversationSummary? _selectedConversation;
  late Future<_DashboardData> _dataFuture;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    guardRole(
      context,
      (u) => u.isAnnonceur,
      message: 'Devenez bailleur depuis le Profil pour accéder à cet espace.',
    );
    _dataFuture = _load();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _refresh());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<_DashboardData> _load() async {
    final listings = await _listingRepository.myListings();
    final leads = await _leadRepository.received();
    final conversations = await _messagingRepository.conversations();
    final me = await _authRepository.me();
    return _DashboardData(listings, leads, conversations, me);
  }

  void _refresh() => setState(() => _dataFuture = _load());

  void _setTab(int index) => setState(() => _tabIndex = index);

  Future<void> _openPublishForm() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const PublishListingScreen()),
    );
    if (created == true) _refresh();
  }

  Future<void> _markLeadRead(int leadId) async {
    await _leadRepository.markRead(leadId);
    _refresh();
  }

  /// Ouvre (ou crée) la conversation liée à une demande et bascule sur
  /// l'onglet Messages — point d'entrée « depuis une Demande ».
  Future<void> _replyToLead(ReceivedLead lead) async {
    final conversation = await _messagingRepository.openConversation(
      listingId: lead.listingId,
      peerId: lead.tenantId,
    );
    setState(() {
      _selectedConversation = conversation;
      _tabIndex = 2;
    });
  }

  void _openConversation(ConversationSummary conversation) {
    setState(() => _selectedConversation = conversation);
  }

  void _closeConversation() {
    setState(() => _selectedConversation = null);
    _refresh();
  }

  Future<void> _logout() async {
    await _authRepository.logout();
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: FutureBuilder<_DashboardData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Impossible de charger votre espace : ${snapshot.error}',
                style: const TextStyle(color: AppColors.sub),
              ),
            );
          }
          final data = snapshot.data!;
          return LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 860) {
                return AnnonceurWebDashboard(
                  listings: data.listings,
                  leads: data.leads,
                  conversations: data.conversations,
                  selectedConversation: _selectedConversation,
                  user: data.me,
                  currentIndex: _tabIndex,
                  onTabChanged: _setTab,
                  onNewListing: _openPublishForm,
                  repository: _listingRepository,
                  onChanged: _refresh,
                  onMarkRead: _markLeadRead,
                  onReplyToLead: _replyToLead,
                  onOpenConversation: _openConversation,
                  onCloseConversation: _closeConversation,
                  onLogout: _logout,
                );
              }
              return AnnonceurMobileDashboard(
                listings: data.listings,
                leads: data.leads,
                conversations: data.conversations,
                selectedConversation: _selectedConversation,
                user: data.me,
                currentIndex: _tabIndex,
                onTabChanged: _setTab,
                onNewListing: _openPublishForm,
                repository: _listingRepository,
                onChanged: _refresh,
                onMarkRead: _markLeadRead,
                onReplyToLead: _replyToLead,
                onOpenConversation: _openConversation,
                onCloseConversation: _closeConversation,
                onLogout: _logout,
              );
            },
          );
        },
      ),
    );
  }
}
