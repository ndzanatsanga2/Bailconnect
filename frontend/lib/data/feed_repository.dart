import 'api_client.dart';
import 'listing_repository.dart' show ListingMediaItem;

class AmenityItem {
  final int id;
  final String name;
  final String icon;

  AmenityItem({required this.id, required this.name, required this.icon});

  factory AmenityItem.fromJson(Map<String, dynamic> json) => AmenityItem(
    id: json['id'] as int,
    name: json['name'] as String,
    icon: json['icon'] as String? ?? '',
  );
}

class PublicListing {
  final int id;
  final String title;
  final String description;
  final String neighborhood;
  final String propertyType;
  final int rentAmount;
  final int depositAmount;
  final String terms;
  final List<AmenityItem> amenities;
  final List<ListingMediaItem> media;
  final bool verified;
  final int daysSinceConfirmed;
  final bool isFavorite;

  PublicListing({
    required this.id,
    required this.title,
    required this.description,
    required this.neighborhood,
    required this.propertyType,
    required this.rentAmount,
    required this.depositAmount,
    required this.terms,
    required this.amenities,
    required this.media,
    required this.verified,
    required this.daysSinceConfirmed,
    required this.isFavorite,
  });

  factory PublicListing.fromJson(Map<String, dynamic> json) => PublicListing(
    id: json['id'] as int,
    title: json['title'] as String,
    description: json['description'] as String? ?? '',
    neighborhood: json['neighborhood'] as String,
    propertyType: json['property_type'] as String,
    rentAmount: json['rent_amount'] as int,
    depositAmount: json['deposit_amount'] as int? ?? 0,
    terms: json['terms'] as String? ?? '',
    amenities: (json['amenities'] as List)
        .map((e) => AmenityItem.fromJson(e as Map<String, dynamic>))
        .toList(),
    media: (json['media'] as List)
        .map((e) => ListingMediaItem.fromJson(e as Map<String, dynamic>))
        .toList(),
    verified: json['verified'] as bool,
    daysSinceConfirmed: json['days_since_confirmed'] as int,
    isFavorite: json['is_favorite'] as bool,
  );

  PublicListing copyWith({bool? isFavorite}) => PublicListing(
    id: id,
    title: title,
    description: description,
    neighborhood: neighborhood,
    propertyType: propertyType,
    rentAmount: rentAmount,
    depositAmount: depositAmount,
    terms: terms,
    amenities: amenities,
    media: media,
    verified: verified,
    daysSinceConfirmed: daysSinceConfirmed,
    isFavorite: isFavorite ?? this.isFavorite,
  );
}

class FeedFilters {
  final String? neighborhood;
  final int? budgetMax;
  final String? propertyType;
  final List<int> amenityIds;
  final String? media;

  const FeedFilters({
    this.neighborhood,
    this.budgetMax,
    this.propertyType,
    this.amenityIds = const [],
    this.media,
  });
}

class FeedRepository {
  final ApiClient _api;

  FeedRepository(this._api);

  Future<List<PublicListing>> fetch([
    FeedFilters filters = const FeedFilters(),
  ]) async {
    final data =
        await _api.get(
              '/api/feed/',
              query: {
                if (filters.neighborhood != null &&
                    filters.neighborhood!.isNotEmpty)
                  'neighborhood': filters.neighborhood,
                if (filters.budgetMax != null) 'budget_max': filters.budgetMax,
                if (filters.propertyType != null)
                  'property_type': filters.propertyType,
                if (filters.amenityIds.isNotEmpty)
                  'amenity': filters.amenityIds,
                if (filters.media != null) 'media': filters.media,
              },
            )
            as List;
    return data
        .map((e) => PublicListing.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PublicListing> detail(int id) async {
    final data = await _api.get('/api/feed/$id/');
    return PublicListing.fromJson(data as Map<String, dynamic>);
  }
}
