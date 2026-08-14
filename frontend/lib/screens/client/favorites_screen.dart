import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../data/auth_repository.dart';
import '../../data/favorite_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../widgets/bc_button.dart';
import '../../widgets/bc_icon.dart';
import '../auth/auth_helpers.dart';
import 'listing_detail_screen.dart';

/// Liste des biens favoris du locataire connecté.
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _authRepository = AuthRepository(ApiClient());
  final _favoriteRepository = FavoriteRepository(ApiClient());
  bool _checkingAuth = true;
  bool _authenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final authenticated = await _authRepository.isAuthenticated;
    if (mounted) setState(() { _authenticated = authenticated; _checkingAuth = false; });
  }

  Future<void> _login() async {
    if (await ensureAuthenticated(context, role: 'locataire')) {
      setState(() => _authenticated = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingAuth) return const Center(child: CircularProgressIndicator());

    if (!_authenticated) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BcIcon('heart', size: 36, color: AppColors.sub),
              const SizedBox(height: 14),
              const Text('Connectez-vous pour retrouver vos favoris', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              const SizedBox(height: 18),
              BcButton(label: 'Se connecter', expand: false, onPressed: _login),
            ],
          ),
        ),
      );
    }

    return FutureBuilder<List<FavoriteItem>>(
      future: _favoriteRepository.list(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final favorites = snapshot.data ?? [];
        if (favorites.isEmpty) {
          return const Center(child: Text('Aucun favori pour l\'instant.', style: TextStyle(color: AppColors.sub)));
        }
        return SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: favorites.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final favorite = favorites[index];
              return InkWell(
                borderRadius: BorderRadius.circular(15),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ListingDetailScreen(listingId: favorite.listing.id)),
                ),
                child: Container(
                  decoration: BoxDecoration(color: AppColors.paper, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(15)),
                  child: Row(
                    children: [
                      Container(
                        width: 84,
                        height: 74,
                        decoration: BoxDecoration(
                          gradient: AppGradients.all[favorite.listing.id % AppGradients.all.length],
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(15)),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(favorite.listing.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text(favorite.listing.neighborhood, style: const TextStyle(color: AppColors.sub, fontSize: 11)),
                              const SizedBox(height: 6),
                              Text('${favorite.listing.rentAmount} FCFA', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.greenDark)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
