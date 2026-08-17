import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../data/auth_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/breakpoints.dart';
import '../../widgets/bc_button.dart';
import '../../widgets/bc_content_bounds.dart';
import '../../widgets/bc_icon.dart';
import '../../widgets/bc_logo.dart';
import '../../widgets/bc_top_bar.dart';
import '../auth/role_guard.dart';
import 'admin_dashboard_tab.dart';
import 'admin_invitations_tab.dart';
import 'admin_listings_tab.dart';
import 'admin_reports_tab.dart';
import 'admin_users_tab.dart';

/// Route dédiée du back-office admin — séparée de l'app client/bailleur
/// (jamais de bouton d'accès admin ailleurs, uniquement cette URL ou le
/// routage automatique au rôle à la connexion).
const kAdminRoute = '/admin-bailconnect';

/// Page de connexion propre au back-office (jamais le dialog mobile de
/// l'app client) — destination de repli quand [kAdminRoute] est atteint
/// sans session admin valide.
const kAdminLoginRoute = '/admin-bailconnect/login';

const _tabs = [
  ('chart', 'Dashboard', 'Vue d\'ensemble de la plateforme'),
  ('home', 'Annonces', 'Modération des annonces'),
  ('users', 'Utilisateurs', 'Comptes clients, annonceurs et admins'),
  ('inbox', 'Amorçage & invitations', 'Amorçage manuel des annonceurs'),
  ('flag', 'Signalements', 'Annonces signalées par les utilisateurs'),
  ('user', 'Profil', 'Informations du compte administrateur'),
];

/// Back-office admin — section web de l'app Flutter, même design system que
/// le reste (fidèle au wireframe Admin, section 8). Django Admin n'est qu'un
/// outil de debug interne, jamais lié depuis l'app. Espace totalement
/// séparé du reste de l'app : accessible uniquement via [kAdminRoute] ou le
/// routage automatique au rôle à la connexion — jamais de bouton dans le
/// profil client/bailleur.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  final _authRepository = AuthRepository(ApiClient());
  int _index = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late Future<AuthUser?> _meFuture;

  @override
  void initState() {
    super.initState();
    guardRole(
      context,
      (u) => u.role == 'admin',
      message: "Accès réservé aux administrateurs.",
      fallbackRoute: kAdminLoginRoute,
    );
    _meFuture = _authRepository.me();
  }

  Future<void> _logout() async {
    await _authRepository.logout();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  void _selectTab(int index) {
    setState(() => _index = index);
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bodies = [
      AdminDashboardTab(onViewPendingListings: () => _selectTab(1)),
      const AdminListingsTab(),
      const AdminUsersTab(),
      const AdminInvitationsTab(),
      const AdminReportsTab(),
      FutureBuilder<AuthUser?>(
        future: _meFuture,
        builder: (context, snapshot) =>
            _AdminProfilBody(user: snapshot.data, onLogout: _logout),
      ),
    ];
    final (_, title, subtitle) = _tabs[_index];
    final compact = MediaQuery.of(context).size.width < kTabletBreakpoint;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.bg,
      drawer: compact ? Drawer(child: _sidebar()) : null,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!compact) _sidebar(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BcTopBar(
                  title: title,
                  subtitle: subtitle,
                  onLogout: _logout,
                  leading: compact
                      ? Builder(
                          builder: (context) => InkWell(
                            onTap: () => Scaffold.of(context).openDrawer(),
                            borderRadius: BorderRadius.circular(9),
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: BcIcon(
                                'grid',
                                size: 19,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                        )
                      : null,
                ),
                Expanded(child: BcContentBounds(child: bodies[_index])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebar() {
    return Container(
      width: 240,
      color: AppColors.greenDark,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BcLogoLockup(
            markSize: 26,
            fontSize: 15,
            textColor: Colors.white,
          ),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.only(left: 2),
            child: Text(
              'Admin',
              style: TextStyle(
                color: Color(0xFFA7CDBB),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(height: 22),
          for (var i = 0; i < _tabs.length; i++) _navItem(i),
        ],
      ),
    );
  }

  Widget _navItem(int index) {
    final active = index == _index;
    final (icon, label, _) = _tabs[index];
    return InkWell(
      onTap: () => _selectTab(index),
      borderRadius: BorderRadius.circular(11),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: active ? AppColors.amber : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          children: [
            BcIcon(
              icon,
              size: 18,
              color: active ? Colors.white : const Color(0xFFA7CDBB),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : const Color(0xFFA7CDBB),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Informations du compte admin, avant le bouton de déconnexion (spec).
class _AdminProfilBody extends StatelessWidget {
  final AuthUser? user;
  final VoidCallback onLogout;

  const _AdminProfilBody({required this.user, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final u = user;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.paper,
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.greenLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: BcIcon('user', size: 19, color: AppColors.greenDark),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (u?.fullName.isNotEmpty ?? false)
                            ? u!.fullName
                            : (u?.email ?? 'Administrateur'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Administrateur',
                        style: TextStyle(color: AppColors.sub, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.paper,
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                _infoRow(
                  'user',
                  'Nom',
                  (u?.fullName.isEmpty ?? true) ? '—' : u!.fullName,
                ),
                _infoRow('chat', 'Email', u?.email ?? '—'),
                _infoRow('settings', 'Rôle', 'Admin', showDivider: false),
              ],
            ),
          ),
          const SizedBox(height: 20),
          BcButton(
            label: 'Se déconnecter',
            variant: BcButtonVariant.ghost,
            onPressed: onLogout,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    String icon,
    String label,
    String value, {
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              BcIcon(icon, size: 15, color: AppColors.sub),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.sub,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1, color: AppColors.line),
      ],
    );
  }
}
