import 'package:flutter/material.dart';

import '../../data/feed_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bc_bottom_nav.dart';
import 'favorites_screen.dart';
import 'feed_screen.dart';
import 'profile_tab.dart';
import 'search_screen.dart';

/// Point d'entrée public de l'app (fil consultable sans connexion) avec la
/// navigation basse Accueil/Recherche/Favoris/Profil du wireframe Client.
class ClientShell extends StatefulWidget {
  const ClientShell({super.key});

  @override
  State<ClientShell> createState() => _ClientShellState();
}

class _ClientShellState extends State<ClientShell> {
  int _index = 0;
  FeedFilters _filters = const FeedFilters();

  void _applySearch(FeedFilters filters) {
    setState(() {
      _filters = filters;
      _index = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      FeedScreen(filters: _filters),
      SearchScreen(onSearch: _applySearch),
      const FavoritesScreen(),
      const ProfileTab(),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      extendBody: true,
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: BcBottomNav(
        currentIndex: _index,
        items: const [
          BcNavItem('home', 'Accueil'),
          BcNavItem('search', 'Recherche'),
          BcNavItem('heart', 'Favoris'),
          BcNavItem('user', 'Profil'),
        ],
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
