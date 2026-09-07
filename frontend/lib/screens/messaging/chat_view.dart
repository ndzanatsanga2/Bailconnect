import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/api_client.dart';
import '../../data/messaging_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bc_button.dart';
import '../../widgets/bc_icon.dart';

const _pollInterval = Duration(seconds: 3);

/// Fil de discussion d'une conversation — bulles + champ de saisie, rafraîchi
/// par polling (toutes les 3 s) tant que l'écran est affiché. Réutilisé tel
/// quel côté client (dans [ChatScreen], poussé en route) et côté bailleur
/// (intégré directement dans l'onglet Messages de son espace).
class ChatView extends StatefulWidget {
  final int conversationId;
  final String peerName;
  final String listingTitle;

  /// Si fourni, affiche un bouton retour en haut (utilisé côté bailleur où
  /// l'écran est intégré, sans route à dépiler).
  final VoidCallback? onBack;

  /// Pilote l'affichage du bandeau rendez-vous (section E) : l'annonceur
  /// voit un bouton pour confirmer, le client voit le numéro une fois
  /// confirmé — jamais les deux à la fois dans la même conversation.
  final bool isAnnonceur;

  const ChatView({
    super.key,
    required this.conversationId,
    required this.peerName,
    required this.listingTitle,
    this.onBack,
    required this.isAnnonceur,
  });

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final _repository = MessagingRepository(ApiClient());
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _pollTimer;
  List<ChatMessage> _messages = [];
  ConversationSummary? _conversation;
  bool _loading = true;
  bool _sending = false;
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    _load(initial: true);
    _pollTimer = Timer.periodic(_pollInterval, (_) => _load());
  }

  @override
  void didUpdateWidget(covariant ChatView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conversationId != widget.conversationId) {
      _messages = [];
      _load(initial: true);
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load({bool initial = false}) async {
    try {
      final messages = await _repository.messages(widget.conversationId);
      final conversation = await _repository.getConversation(
        widget.conversationId,
      );
      if (!mounted) return;
      final grew = messages.length > _messages.length;
      setState(() {
        _messages = messages;
        _conversation = conversation;
        _loading = false;
      });
      if (initial || grew) {
        await _repository.markRead(widget.conversationId);
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmAppointment() async {
    setState(() => _confirming = true);
    try {
      final conversation = await _repository.confirmAppointment(
        widget.conversationId,
      );
      if (mounted) setState(() => _conversation = conversation);
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _textController.clear();
    try {
      final message = await _repository.sendMessage(
        widget.conversationId,
        text,
      );
      if (!mounted) return;
      setState(() => _messages = [..._messages, message]);
      _scrollToBottom();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: AppColors.paper,
            border: Border(bottom: BorderSide(color: AppColors.line)),
          ),
          child: Row(
            children: [
              if (widget.onBack != null) ...[
                InkWell(
                  onTap: widget.onBack,
                  borderRadius: BorderRadius.circular(18),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: BcIcon('back', size: 18, color: AppColors.ink),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.peerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      widget.listingTitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.sub,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_appointmentBanner() != null) _appointmentBanner()!,
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _messages.isEmpty
              ? const Center(
                  child: Text(
                    'Envoyez le premier message.',
                    style: TextStyle(color: AppColors.sub),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) => _bubble(_messages[index]),
                ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: const BoxDecoration(
            color: AppColors.paper,
            border: Border(top: BorderSide(color: AppColors.line)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Écrire un message…',
                      filled: true,
                      fillColor: AppColors.bg,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _sending ? null : _send,
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _sending ? AppColors.line : AppColors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: BcIcon('play', size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Bandeau rendez-vous (section E) : côté annonceur, une invite à
  /// confirmer tant que ce n'est pas fait ; côté client, le numéro de
  /// l'annonceur une fois la confirmation reçue. Jamais les deux à la fois,
  /// et rien tant que la conversation n'est pas encore chargée.
  Widget? _appointmentBanner() {
    final conversation = _conversation;
    if (conversation == null) return null;
    if (widget.isAnnonceur) {
      if (conversation.appointmentConfirmed) return null;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: AppColors.greenLight,
        child: Row(
          children: [
            const BcIcon('check', size: 16, color: AppColors.greenDark),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Vous êtes convenus d\'un rendez-vous ?',
                style: TextStyle(fontSize: 12.5, color: AppColors.greenDark),
              ),
            ),
            BcButton(
              label: _confirming ? 'Un instant…' : 'Confirmer le rendez-vous',
              expand: false,
              onPressed: _confirming ? null : _confirmAppointment,
            ),
          ],
        ),
      );
    }
    final phone = conversation.contactPhone;
    if (!conversation.appointmentConfirmed || phone == null) return null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.greenLight,
      child: Row(
        children: [
          const BcIcon('phone', size: 16, color: AppColors.greenDark),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Rendez-vous confirmé — numéro de l\'annonceur : $phone',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.greenDark,
              ),
            ),
          ),
          InkWell(
            onTap: () => launchUrl(Uri.parse('tel:$phone')),
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: BcIcon('phone', size: 16, color: AppColors.greenDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(ChatMessage message) {
    return Align(
      alignment: message.isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: message.isMine ? AppColors.green : AppColors.paper,
          border: message.isMine ? null : Border.all(color: AppColors.line),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(message.isMine ? 14 : 2),
            bottomRight: Radius.circular(message.isMine ? 2 : 14),
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isMine ? Colors.white : AppColors.ink,
            fontSize: 13,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}
