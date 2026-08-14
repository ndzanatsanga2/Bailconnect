import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../data/auth_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bc_button.dart';
import '../../widgets/bc_icon.dart';
import '../admin/admin_shell.dart';
import '../annonceur/annonceur_dashboard_screen.dart';
import '../auth/auth_helpers.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _authRepository = AuthRepository(ApiClient());
  late Future<AuthUser?> _meFuture;

  @override
  void initState() {
    super.initState();
    _meFuture = _authRepository.me();
  }

  void _refresh() => setState(() => _meFuture = _authRepository.me());

  Future<void> _login() async {
    if (await ensureAuthenticated(context, role: 'locataire')) _refresh();
  }

  Future<void> _logout() async {
    await _authRepository.logout();
    _refresh();
  }

  Future<void> _openAnnonceurSpace() async {
    if (!await ensureAuthenticated(context, role: 'annonceur')) return;
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AnnonceurDashboardScreen()));
  }

  void _openAdminBackoffice() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminShell()));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<AuthUser?>(
        future: _meFuture,
        builder: (context, snapshot) {
          final user = snapshot.data;
          final authenticated = user != null;
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Profil', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
                const SizedBox(height: 20),
                if (authenticated) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.greenLight, borderRadius: BorderRadius.circular(13)),
                    child: Row(children: [
                      const BcIcon('user', size: 20, color: AppColors.greenDark),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          user.email ?? user.phoneNumber ?? 'Connecté',
                          style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.greenDark),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  BcButton(label: 'Se déconnecter', variant: BcButtonVariant.ghost, onPressed: _logout),
                  if (user.role == 'admin') ...[
                    const SizedBox(height: 12),
                    BcButton(label: 'Back-office admin', icon: 'settings', onPressed: _openAdminBackoffice),
                  ],
                ] else ...[
                  const Text('Connectez-vous pour contacter des annonceurs et sauvegarder vos favoris.', style: TextStyle(color: AppColors.sub, fontSize: 13)),
                  const SizedBox(height: 16),
                  BcButton(label: 'Se connecter', onPressed: _login),
                ],
                const SizedBox(height: 28),
                const Divider(color: AppColors.line),
                const SizedBox(height: 12),
                BcButton(label: 'Espace annonceur', icon: 'grid', variant: BcButtonVariant.ghost, onPressed: _openAnnonceurSpace),
              ],
            ),
          );
        },
      ),
    );
  }
}
