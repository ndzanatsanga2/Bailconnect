import 'api_client.dart';

class AdminDashboard {
  final int clientsCount;
  final int annonceursCount;
  final int listingsPendingCount;
  final int listingsPublishedCount;
  final int reportsOpenCount;

  AdminDashboard({
    required this.clientsCount,
    required this.annonceursCount,
    required this.listingsPendingCount,
    required this.listingsPublishedCount,
    required this.reportsOpenCount,
  });

  factory AdminDashboard.fromJson(Map<String, dynamic> json) => AdminDashboard(
        clientsCount: json['clients_count'] as int,
        annonceursCount: json['annonceurs_count'] as int,
        listingsPendingCount: json['listings_pending_count'] as int,
        listingsPublishedCount: json['listings_published_count'] as int,
        reportsOpenCount: json['reports_open_count'] as int,
      );
}

class AdminListing {
  final int id;
  final String title;
  final String neighborhood;
  final String propertyType;
  final int rentAmount;
  final String status;
  final String source;
  final bool verified;
  final String ownerDisplay;

  AdminListing({
    required this.id,
    required this.title,
    required this.neighborhood,
    required this.propertyType,
    required this.rentAmount,
    required this.status,
    required this.source,
    required this.verified,
    required this.ownerDisplay,
  });

  factory AdminListing.fromJson(Map<String, dynamic> json) => AdminListing(
        id: json['id'] as int,
        title: json['title'] as String,
        neighborhood: json['neighborhood'] as String,
        propertyType: json['property_type'] as String,
        rentAmount: json['rent_amount'] as int,
        status: json['status'] as String,
        source: json['source'] as String,
        verified: json['verified'] as bool,
        ownerDisplay: json['owner_display'] as String,
      );
}

class AdminUser {
  final int id;
  final String? phoneNumber;
  final String? email;
  final String fullName;
  final String role;

  AdminUser({required this.id, this.phoneNumber, this.email, required this.fullName, required this.role});

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
        id: json['id'] as int,
        phoneNumber: json['phone_number'] as String?,
        email: json['email'] as String?,
        fullName: json['full_name'] as String? ?? '',
        role: json['role'] as String,
      );
}

class AdminInvitation {
  final int id;
  final String phoneNumber;
  final String? listingTitle;
  final String? usedAt;
  final String expiresAt;

  AdminInvitation({required this.id, required this.phoneNumber, this.listingTitle, this.usedAt, required this.expiresAt});

  factory AdminInvitation.fromJson(Map<String, dynamic> json) => AdminInvitation(
        id: json['id'] as int,
        phoneNumber: json['phone_number'] as String,
        listingTitle: json['listing_title'] as String?,
        usedAt: json['used_at'] as String?,
        expiresAt: json['expires_at'] as String,
      );
}

class AdminReport {
  final int id;
  final String listingTitle;
  final String reporterIdentifier;
  final String reason;
  final String description;
  final String status;

  AdminReport({
    required this.id,
    required this.listingTitle,
    required this.reporterIdentifier,
    required this.reason,
    required this.description,
    required this.status,
  });

  factory AdminReport.fromJson(Map<String, dynamic> json) => AdminReport(
        id: json['id'] as int,
        listingTitle: json['listing_title'] as String,
        reporterIdentifier: json['reporter_identifier'] as String,
        reason: json['reason'] as String,
        description: json['description'] as String? ?? '',
        status: json['status'] as String,
      );
}

class AdminRepository {
  final ApiClient _api;

  AdminRepository(this._api);

  Future<AdminDashboard> dashboard() async {
    final data = await _api.get('/api/admin/dashboard/');
    return AdminDashboard.fromJson(data as Map<String, dynamic>);
  }

  Future<List<AdminListing>> listings({String? status}) async {
    final data = await _api.get('/api/admin/listings/', query: {'status': ?status}) as List;
    return data.map((e) => AdminListing.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> approveListing(int id) => _api.post('/api/admin/listings/$id/approve/', {});
  Future<void> rejectListing(int id) => _api.post('/api/admin/listings/$id/reject/', {});

  Future<List<AdminUser>> users({String? role}) async {
    final data = await _api.get('/api/admin/users/', query: {'role': ?role}) as List;
    return data.map((e) => AdminUser.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<AdminInvitation>> invitations() async {
    final data = await _api.get('/api/admin/invitations/') as List;
    return data.map((e) => AdminInvitation.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> sendInvitation({required String phoneNumber, int? listingId}) {
    return _api.post('/api/admin/invitations/', {
      'phone_number': phoneNumber,
      'listing_id': ?listingId,
    });
  }

  Future<List<AdminReport>> reports({String? status}) async {
    final data = await _api.get('/api/admin/reports/', query: {'status': ?status}) as List;
    return data.map((e) => AdminReport.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> resolveReport(int id, String status) {
    return _api.post('/api/admin/reports/$id/resolve/', {'status': status});
  }
}
