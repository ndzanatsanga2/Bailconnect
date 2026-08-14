import 'api_client.dart';
import 'feed_repository.dart';

class FavoriteItem {
  final int id;
  final PublicListing listing;

  FavoriteItem({required this.id, required this.listing});

  factory FavoriteItem.fromJson(Map<String, dynamic> json) => FavoriteItem(
        id: json['id'] as int,
        listing: PublicListing.fromJson(json['listing'] as Map<String, dynamic>),
      );
}

class FavoriteRepository {
  final ApiClient _api;

  FavoriteRepository(this._api);

  Future<List<FavoriteItem>> list() async {
    final data = await _api.get('/api/favorites/') as List;
    return data.map((e) => FavoriteItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<int> add(int listingId) async {
    final data = await _api.post('/api/favorites/', {'listing_id': listingId});
    return data['id'] as int;
  }

  Future<void> remove(int favoriteId) => _api.delete('/api/favorites/$favoriteId/');
}
