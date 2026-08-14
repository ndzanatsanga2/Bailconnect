import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../data/auth_repository.dart';
import '../../data/feed_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bc_bottom_nav.dart';
import '../../widgets/bc_mobile_frame.dart';
import '../auth/post_login_routing.dart';
import 'favorites_screen.dart';
import 'feed_screen.dart';
import 'messages_tab.dart';
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
  int _unreadMessages = 0;

  @override
  void initState() {
    super.initState();
    // Auto-connexion au démarrage si une session persistante existe déjà
    // (« Se souvenir de moi ») — route directement vers l'espace du rôle.
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoRoute());
  }

  Future<void> _autoRoute() async {
    final user = await AuthRepository(ApiClient()).me();
    if (!mounted) return;
    await routeAfterAuth(context, user);
  }

  void _applySearch(FeedFilters filters) {
    setState(() {
      _filters = filters;
      _index = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      FeedScreen(filters: _filters, active: _index == 0),
      SearchScreen(onSearch: _applySearch),
      const FavoritesScreen(),
      MessagesTab(
        onUnreadChanged: (count) => setState(() => _unreadMessages = count),
      ),
      const ProfileTab(),
    ];

    return BcMobileFrame(
      child: Scaffold(
        backgroundColor: AppColors.bg,
        extendBody: true,
        body: IndexedStack(index: _index, children: tabs),
        bottomNavigationBar: BcBottomNav(
          currentIndex: _index,
          items: [
            const BcNavItem('home', 'Accueil'),
            const BcNavItem('search', 'Recherche'),
            const BcNavItem('heart', 'Favoris'),
            BcNavItem('chat', 'Messages', badge: _unreadMessages),
            const BcNavItem('user', 'Profil'),
          ],
          onTap: (i) => setState(() => _index = i),
        ),
      ),
    );
  }
}
