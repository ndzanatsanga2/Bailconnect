import 'api_client.dart';
import 'feed_repository.dart' show AmenityItem;

class AdminTrendPoint {
  final String date;
  final int count;

  AdminTrendPoint({required this.date, required this.count});

  factory AdminTrendPoint.fromJson(Map<String, dynamic> json) =>
      AdminTrendPoint(
        date: json['date'] as String,
        count: json['count'] as int,
      );
}

class AdminDashboard {
  final int clientsCount;
  final int annonceursCount;
  final int listingsPendingCount;
  final int listingsPublishedCount;
  final int reportsOpenCount;
  final List<AdminTrendPoint> listingsPublishedByDay;
  final List<AdminTrendPoint> signupsByDay;

  AdminDashboard({
    required this.clientsCount,
    required this.annonceursCount,
    required this.listingsPendingCount,
    required this.listingsPublishedCount,
    required this.reportsOpenCount,
    required this.listingsPublishedByDay,
    required this.signupsByDay,
  });

  factory AdminDashboard.fromJson(Map<String, dynamic> json) => AdminDashboard(
    clientsCount: json['clients_count'] as int,
    annonceursCount: json['annonceurs_count'] as int,
    listingsPendingCount: json['listings_pending_count'] as int,
    listingsPublishedCount: json['listings_published_count'] as int,
    reportsOpenCount: json['reports_open_count'] as int,
    listingsPublishedByDay: (json['listings_published_by_day'] as List)
        .map((e) => AdminTrendPoint.fromJson(e as Map<String, dynamic>))
        .toList(),
    signupsByDay: (json['signups_by_day'] as List)
        .map((e) => AdminTrendPoint.fromJson(e as Map<String, dynamic>))
        .toList(),
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

  AdminUser({
    required this.id,
    this.phoneNumber,
    this.email,
    required this.fullName,
    required this.role,
  });

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

  AdminInvitation({
    required this.id,
    required this.phoneNumber,
    this.listingTitle,
    this.usedAt,
    required this.expiresAt,
  });

  factory AdminInvitation.fromJson(Map<String, dynamic> json) =>
      AdminInvitation(
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

/// Page de résultats DRF ({count, results}) — utilisée par les tableaux du
/// back-office pour piloter la pagination côté serveur.
class AdminPage<T> {
  final List<T> items;
  final int count;

  const AdminPage({required this.items, required this.count});
}

class AdminRepository {
  final ApiClient _api;

  static const _pageSize = 10;

  AdminRepository(this._api);

  Future<AdminDashboard> dashboard() async {
    final data = await _api.get('/api/admin/dashboard/');
    return AdminDashboard.fromJson(data as Map<String, dynamic>);
  }

  Future<AdminPage<AdminListing>> listingsPage({
    String? status,
    String? search,
    String? ordering,
    int page = 1,
  }) async {
    final data =
        await _api.get(
              '/api/admin/listings/',
              query: {
                'status': ?status,
                'search': ?search,
                'ordering': ?ordering,
                'page': page,
                'page_size': _pageSize,
              },
            )
            as Map<String, dynamic>;
    return AdminPage(
      items: (data['results'] as List)
          .map((e) => AdminListing.fromJson(e as Map<String, dynamic>))
          .toList(),
      count: data['count'] as int,
    );
  }

  /// Aperçu compact pour le dashboard (5 plus récentes en attente).
  Future<List<AdminListing>> pendingListingsPreview() async {
    final page = await listingsPage(status: 'en_attente', page: 1);
    return page.items.take(5).toList();
  }

  Future<void> approveListing(int id) =>
      _api.post('/api/admin/listings/$id/approve/', {});
  Future<void> rejectListing(int id) =>
      _api.post('/api/admin/listings/$id/reject/', {});

  Future<List<AmenityItem>> amenities() async {
    final data = await _api.get('/api/amenities/') as List;
    return data
        .map((e) => AmenityItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Création directe par l'admin — auto-validée et publiée côté serveur
  /// (amorçage, sans annonceur inscrit à ce stade).
  Future<AdminListing> createListing({
    required String title,
    required String description,
    required String neighborhood,
    required String propertyType,
    required int rentAmount,
    required int depositAmount,
    required String terms,
    required String whatsappNumber,
    List<int> amenityIds = const [],
    String seedContactName = '',
    String seedContactPhone = '',
  }) async {
    final data = await _api.post('/api/admin/listings/', {
      'title': title,
      'description': description,
      'neighborhood': neighborhood,
      'property_type': propertyType,
      'rent_amount': rentAmount,
      'deposit_amount': depositAmount,
      'terms': terms,
      'whatsapp_number': whatsappNumber,
      'amenity_ids': amenityIds,
      'seed_contact_name': seedContactName,
      'seed_contact_phone': seedContactPhone,
    });
    return AdminListing.fromJson(data as Map<String, dynamic>);
  }

  Future<void> uploadListingMedia({
    required int listingId,
    required String mediaType,
    required List<int> bytes,
    required String filename,
  }) {
    return _api.uploadFile(
      '/api/admin/listings/$listingId/upload_media/',
      fieldName: 'file',
      bytes: bytes,
      filename: filename,
      fields: {'media_type': mediaType},
    );
  }

  Future<AdminPage<AdminUser>> usersPage({
    String? role,
    String? search,
    String? ordering,
    int page = 1,
  }) async {
    final data =
        await _api.get(
              '/api/admin/users/',
              query: {
                'role': ?role,
                'search': ?search,
                'ordering': ?ordering,
                'page': page,
                'page_size': _pageSize,
              },
            )
            as Map<String, dynamic>;
    return AdminPage(
      items: (data['results'] as List)
          .map((e) => AdminUser.fromJson(e as Map<String, dynamic>))
          .toList(),
      count: data['count'] as int,
    );
  }

  Future<AdminPage<AdminInvitation>> invitationsPage({int page = 1}) async {
    final data =
        await _api.get(
              '/api/admin/invitations/',
              query: {'page': page, 'page_size': _pageSize},
            )
            as Map<String, dynamic>;
    return AdminPage(
      items: (data['results'] as List)
          .map((e) => AdminInvitation.fromJson(e as Map<String, dynamic>))
          .toList(),
      count: data['count'] as int,
    );
  }

  Future<void> sendInvitation({required String phoneNumber, int? listingId}) {
    return _api.post('/api/admin/invitations/', {
      'phone_number': phoneNumber,
      'listing_id': ?listingId,
    });
  }

  Future<AdminPage<AdminReport>> reportsPage({
    String? status,
    String? search,
    String? ordering,
    int page = 1,
  }) async {
    final data =
        await _api.get(
              '/api/admin/reports/',
              query: {
                'status': ?status,
                'search': ?search,
                'ordering': ?ordering,
                'page': page,
                'page_size': _pageSize,
              },
            )
            as Map<String, dynamic>;
    return AdminPage(
      items: (data['results'] as List)
          .map((e) => AdminReport.fromJson(e as Map<String, dynamic>))
          .toList(),
      count: data['count'] as int,
    );
  }

  Future<void> resolveReport(int id, String status) {
    return _api.post('/api/admin/reports/$id/resolve/', {'status': status});
  }
}
