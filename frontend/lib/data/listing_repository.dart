import 'api_client.dart';

class ListingMediaItem {
  final int id;
  final String mediaType;
  final String file;

  ListingMediaItem({
    required this.id,
    required this.mediaType,
    required this.file,
  });

  factory ListingMediaItem.fromJson(Map<String, dynamic> json) =>
      ListingMediaItem(
        id: json['id'] as int,
        mediaType: json['media_type'] as String,
        file: json['file'] as String,
      );
}

class Listing {
  final int id;
  final String title;
  final String neighborhood;
  final String propertyType;
  final int rentAmount;
  final int depositAmount;
  final String whatsappNumber;
  final String status;
  final List<ListingMediaItem> media;

  Listing({
    required this.id,
    required this.title,
    required this.neighborhood,
    required this.propertyType,
    required this.rentAmount,
    required this.depositAmount,
    required this.whatsappNumber,
    required this.status,
    required this.media,
  });

  factory Listing.fromJson(Map<String, dynamic> json) => Listing(
    id: json['id'] as int,
    title: json['title'] as String,
    neighborhood: json['neighborhood'] as String,
    propertyType: json['property_type'] as String,
    rentAmount: json['rent_amount'] as int,
    depositAmount: json['deposit_amount'] as int,
    whatsappNumber: json['whatsapp_number'] as String,
    status: json['status'] as String,
    media: (json['media'] as List)
        .map((e) => ListingMediaItem.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class ListingRepository {
  final ApiClient _api;

  ListingRepository(this._api);

  Future<List<Listing>> myListings() async {
    final data = await _api.get('/api/listings/') as List;
    return data
        .map((e) => Listing.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Listing> create({
    required String title,
    required String description,
    required String neighborhood,
    required String propertyType,
    required int rentAmount,
    required int depositAmount,
    required String terms,
    required String whatsappNumber,
  }) async {
    final data = await _api.post('/api/listings/', {
      'title': title,
      'description': description,
      'neighborhood': neighborhood,
      'property_type': propertyType,
      'rent_amount': rentAmount,
      'deposit_amount': depositAmount,
      'terms': terms,
      'whatsapp_number': whatsappNumber,
    });
    return Listing.fromJson(data as Map<String, dynamic>);
  }

  Future<Listing> confirmAvailable(int listingId) async {
    final data = await _api.post(
      '/api/listings/$listingId/confirm_available/',
      {},
    );
    return Listing.fromJson(data as Map<String, dynamic>);
  }

  Future<Listing> markRented(int listingId) async {
    final data = await _api.post('/api/listings/$listingId/mark_rented/', {});
    return Listing.fromJson(data as Map<String, dynamic>);
  }

  Future<ListingMediaItem> uploadMedia({
    required int listingId,
    required String mediaType,
    required List<int> bytes,
    required String filename,
  }) async {
    final data = await _api.uploadFile(
      '/api/listings/$listingId/upload_media/',
      fieldName: 'file',
      bytes: bytes,
      filename: filename,
      fields: {'media_type': mediaType},
    );
    return ListingMediaItem.fromJson(data as Map<String, dynamic>);
  }
}
