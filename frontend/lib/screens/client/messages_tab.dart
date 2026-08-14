import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../data/auth_repository.dart';
import '../../data/messaging_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bc_button.dart';
import '../../widgets/bc_icon.dart';
import '../auth/auth_helpers.dart';
import '../messaging/chat_screen.dart';
import '../messaging/conversations_list.dart';

const _pollInterval = Duration(seconds: 10);

/// Onglet Messages côté client — boîte de conversations avec les annonceurs.
class MessagesTab extends StatefulWidget {
  final ValueChanged<int>? onUnreadChanged;

  const MessagesTab({super.key, this.onUnreadChanged});

  @override
  State<MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends State<MessagesTab> {
  final _repository = MessagingRepository(ApiClient());
  final _authRepository = AuthRepository(ApiClient());
  Timer? _pollTimer;
  bool _checkingAuth = true;
  bool _authenticated = false;
  List<ConversationSummary> _conversations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkAuth() async {
    final authenticated = await _authRepository.isAuthenticated;
    if (!mounted) return;
    setState(() {
      _authenticated = authenticated;
      _checkingAuth = false;
    });
    if (authenticated) {
      _refresh();
      _pollTimer = Timer.periodic(_pollInterval, (_) => _refresh());
    }
  }

  Future<void> _refresh() async {
    try {
      final conversations = await _repository.conversations();
      if (!mounted) return;
      setState(() {
        _conversations = conversations;
        _loading = false;
      });
      widget.onUnreadChanged?.call(
        conversations.fold(0, (sum, c) => sum + c.unreadCount),
      );
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _login() async {
    if (await ensureAuthenticated(context)) {
      setState(() => _authenticated = true);
      _refresh();
      _pollTimer = Timer.periodic(_pollInterval, (_) => _refresh());
    }
  }

  Future<void> _open(ConversationSummary conversation) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: conversation.id,
          peerName: conversation.peerName,
          listingTitle: conversation.listingTitle,
        ),
      ),
    );
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingAuth) return const Center(child: CircularProgressIndicator());

    if (!_authenticated) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BcIcon('chat', size: 36, color: AppColors.sub),
              const SizedBox(height: 14),
              const Text(
                'Connectez-vous pour voir vos messages',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
              const SizedBox(height: 18),
              BcButton(label: 'Se connecter', expand: false, onPressed: _login),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 14, 20, 4),
            child: Text(
              'Messages',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: AppColors.ink,
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ConversationsList(
                    conversations: _conversations,
                    onOpen: _open,
                  ),
          ),
        ],
      ),
    );
  }
}
