import 'api_client.dart';

class ContactResult {
  final int leadId;
  final String? whatsappNumber;
  final bool pendingInvitation;

  ContactResult({
    required this.leadId,
    required this.whatsappNumber,
    required this.pendingInvitation,
  });

  factory ContactResult.fromJson(Map<String, dynamic> json) => ContactResult(
    leadId: json['lead_id'] as int,
    whatsappNumber: json['whatsapp_number'] as String?,
    pendingInvitation: json['pending_invitation'] as bool,
  );
}

class ReceivedLead {
  final int id;
  final int listingId;
  final String listingTitle;
  final String neighborhood;
  final int tenantId;
  final String tenantIdentifier;
  final String createdAt;
  final bool isRead;

  ReceivedLead({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    required this.neighborhood,
    required this.tenantId,
    required this.tenantIdentifier,
    required this.createdAt,
    required this.isRead,
  });

  factory ReceivedLead.fromJson(Map<String, dynamic> json) => ReceivedLead(
    id: json['id'] as int,
    listingId: json['listing_id'] as int,
    listingTitle: json['listing_title'] as String,
    neighborhood: json['neighborhood'] as String,
    tenantId: json['tenant_id'] as int,
    tenantIdentifier: json['tenant_identifier'] as String,
    createdAt: json['created_at'] as String,
    isRead: json['is_read'] as bool,
  );
}

class LeadRepository {
  final ApiClient _api;

  LeadRepository(this._api);

  Future<ContactResult> contact(int listingId) async {
    final data = await _api.post('/api/leads/', {'listing_id': listingId});
    return ContactResult.fromJson(data as Map<String, dynamic>);
  }

  /// Demandes reçues par l'annonceur connecté, tous biens confondus.
  Future<List<ReceivedLead>> received() async {
    final data = await _api.get('/api/leads/received/') as List;
    return data
        .map((e) => ReceivedLead.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ReceivedLead> markRead(int leadId) async {
    final data = await _api.post('/api/leads/received/$leadId/mark_read/', {});
    return ReceivedLead.fromJson(data as Map<String, dynamic>);
  }
}
