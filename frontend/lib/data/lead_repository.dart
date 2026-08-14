import 'api_client.dart';

class ContactResult {
  final int leadId;
  final String? whatsappNumber;
  final bool pendingInvitation;

  ContactResult({required this.leadId, required this.whatsappNumber, required this.pendingInvitation});

  factory ContactResult.fromJson(Map<String, dynamic> json) => ContactResult(
        leadId: json['lead_id'] as int,
        whatsappNumber: json['whatsapp_number'] as String?,
        pendingInvitation: json['pending_invitation'] as bool,
      );
}

class LeadRepository {
  final ApiClient _api;

  LeadRepository(this._api);

  Future<ContactResult> contact(int listingId) async {
    final data = await _api.post('/api/leads/', {'listing_id': listingId});
    return ContactResult.fromJson(data as Map<String, dynamic>);
  }
}
