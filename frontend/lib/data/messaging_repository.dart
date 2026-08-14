import 'api_client.dart';

class ConversationSummary {
  final int id;
  final int listingId;
  final String listingTitle;
  final int peerId;
  final String peerName;
  final String? lastMessage;
  final int unreadCount;
  final String updatedAt;

  ConversationSummary({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    required this.peerId,
    required this.peerName,
    required this.lastMessage,
    required this.unreadCount,
    required this.updatedAt,
  });

  factory ConversationSummary.fromJson(Map<String, dynamic> json) =>
      ConversationSummary(
        id: json['id'] as int,
        listingId: json['listing_id'] as int,
        listingTitle: json['listing_title'] as String,
        peerId: json['peer_id'] as int,
        peerName: json['peer_name'] as String,
        lastMessage: json['last_message'] as String?,
        unreadCount: json['unread_count'] as int,
        updatedAt: json['updated_at'] as String,
      );
}

class ChatMessage {
  final int id;
  final int authorId;
  final bool isMine;
  final String text;
  final String createdAt;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.authorId,
    required this.isMine,
    required this.text,
    required this.createdAt,
    required this.isRead,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] as int,
    authorId: json['author_id'] as int,
    isMine: json['is_mine'] as bool,
    text: json['text'] as String,
    createdAt: json['created_at'] as String,
    isRead: json['is_read'] as bool,
  );
}

/// Discussions client ↔ bailleur. Rafraîchissement par polling côté appelant
/// (voir ChatView) — les méthodes elles-mêmes sont un simple aller-retour
/// HTTP, ce qui permet de les rebrancher plus tard sur un flux WebSocket
/// sans changer les écrans qui les consomment.
class MessagingRepository {
  final ApiClient _api;

  MessagingRepository(this._api);

  Future<List<ConversationSummary>> conversations() async {
    final data = await _api.get('/api/messaging/conversations/') as List;
    return data
        .map((e) => ConversationSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ConversationSummary> openConversation({
    required int listingId,
    int? peerId,
  }) async {
    final data = await _api.post('/api/messaging/conversations/', {
      'listing_id': listingId,
      'peer_id': ?peerId,
    });
    return ConversationSummary.fromJson(data as Map<String, dynamic>);
  }

  Future<List<ChatMessage>> messages(int conversationId) async {
    final data =
        await _api.get('/api/messaging/conversations/$conversationId/messages/')
            as List;
    return data
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ChatMessage> sendMessage(int conversationId, String text) async {
    final data = await _api.post(
      '/api/messaging/conversations/$conversationId/messages/',
      {'text': text},
    );
    return ChatMessage.fromJson(data as Map<String, dynamic>);
  }

  Future<void> markRead(int conversationId) {
    return _api.post(
      '/api/messaging/conversations/$conversationId/mark-read/',
      {},
    );
  }
}
