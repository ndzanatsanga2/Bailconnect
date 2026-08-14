import 'api_client.dart';

class ReportRepository {
  final ApiClient _api;

  ReportRepository(this._api);

  Future<void> report(int listingId, {required String reason, String description = ''}) {
    return _api.post('/api/reports/', {
      'listing': listingId,
      'reason': reason,
      'description': description,
    });
  }
}
