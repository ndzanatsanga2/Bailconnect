import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../data/auth_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bc_button.dart';
import '../../widgets/bc_card.dart';
import '../../widgets/bc_chip.dart';
import '../../widgets/bc_icon.dart';
import '../annonceur/annonceur_dashboard_screen.dart';
import '../auth/login_screen.dart';
import '../auth/open_auth_flow.dart';
import '../auth/post_login_routing.dart';

const _annonceurTypes = [('bailleur', 'Bailleur'), ('agent', 'Agent')];

/// Profil — infos du compte et bascule entre espace client et espace
/// bailleur selon les capacités du compte (double casquette).
class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _authRepository = AuthRepository(ApiClient());
  late Future<AuthUser?> _meFuture;
  bool _showBecomeAnnonceurForm = false;
  final _whatsappController = TextEditingController(text: '+237');
  String _annonceurType = 'bailleur';
  bool _submittingCapacity = false;

  @override
  void initState() {
    super.initState();
    _meFuture = _authRepository.me();
  }

  @override
  void dispose() {
    _whatsappController.dispose();
    super.dispose();
  }

  void _refresh() => setState(() => _meFuture = _authRepository.me());

  /// Connexion — puis routage automatique selon le rôle du compte : un admin
  /// est envoyé directement au back-office (espace totalement séparé, aucun
  /// bouton dans ce profil), un compte à capacité annonceur dans son espace
  /// bailleur. Un client reste ici.
  Future<void> _login() async {
    final result = await openAuthFlow<bool>(
      context,
      (_) => const LoginScreen(),
    );
    if (result != true) return;
    final user = await _authRepository.me();
    if (!mounted) return;
    await routeAfterAuth(context, user);
    _refresh();
  }

  Future<void> _logout() async {
    await _authRepository.logout();
    _refresh();
  }

  Future<void> _openAnnonceurSpace() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AnnonceurDashboardScreen()));
  }

  Future<void> _becomeAnnonceur() async {
    if (_whatsappController.text.trim().isEmpty) return;
    setState(() => _submittingCapacity = true);
    try {
      await _authRepository.becomeAnnonceur(
        whatsappNumber: _whatsappController.text.trim(),
        annonceurType: _annonceurType,
      );
      if (!mounted) return;
      setState(() => _showBecomeAnnonceurForm = false);
      _refresh();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _submittingCapacity = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<AuthUser?>(
        future: _meFuture,
        builder: (context, snapshot) {
          final user = snapshot.data;
          final authenticated = user != null;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Profil',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 20),
                if (authenticated) ...[
                  _accountCard(user),
                  const SizedBox(height: 16),
                  _infoCard(user),
                  const SizedBox(height: 22),
                  const Text(
                    'Espace actif',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.sub,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _spaceSwitch(user),
                  if (_showBecomeAnnonceurForm) ...[
                    const SizedBox(height: 14),
                    _becomeAnnonceurCard(),
                  ],
                  const SizedBox(height: 24),
                  BcButton(
                    label: 'Se déconnecter',
                    variant: BcButtonVariant.ghost,
                    onPressed: _logout,
                  ),
                ] else ...[
                  const Text(
                    'Connectez-vous pour contacter des annonceurs et sauvegarder vos favoris.',
                    style: TextStyle(color: AppColors.sub, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  BcButton(label: 'Se connecter', onPressed: _login),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _accountCard(AuthUser user) {
    return BcCard(
      padding: const EdgeInsets.all(16),
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
                  user.fullName.isEmpty
                      ? (user.email ?? user.phoneNumber ?? 'Connecté')
                      : user.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email ?? user.phoneNumber ?? '',
                  style: const TextStyle(color: AppColors.sub, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(AuthUser user) {
    return Container(
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
            'Prénom',
            user.fullName.isEmpty ? '—' : user.fullName,
          ),
          _infoRow('chat', 'Email', user.email ?? '—'),
          _infoRow('phone', 'Téléphone', user.phoneNumber ?? '—'),
          _infoRow(
            'pin',
            'Ville',
            user.city.isEmpty ? '—' : user.city,
            showDivider: false,
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

  Widget _spaceSwitch(AuthUser user) {
    return Row(
      children: [
        Expanded(
          child: _spaceOption(
            icon: 'home',
            label: 'Espace client',
            active: true,
            onTap: () {},
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: user.isAnnonceur
              ? _spaceOption(
                  icon: 'grid',
                  label: 'Espace bailleur',
                  active: false,
                  onTap: _openAnnonceurSpace,
                )
              : _spaceOption(
                  icon: 'plus',
                  label: 'Devenir bailleur',
                  active: false,
                  onTap: () => setState(
                    () => _showBecomeAnnonceurForm = !_showBecomeAnnonceurForm,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _spaceOption({
    required String icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: active ? AppColors.green : AppColors.paper,
          border: Border.all(
            color: active ? AppColors.green : AppColors.line,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Column(
          children: [
            BcIcon(
              icon,
              size: 18,
              color: active ? Colors.white : AppColors.greenDark,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _becomeAnnonceurCard() {
    return BcCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Devenir bailleur',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ajoutez la capacité annonceur à votre compte pour publier des biens.',
            style: TextStyle(fontSize: 12, color: AppColors.sub),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _whatsappController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Numéro WhatsApp',
              isDense: true,
              filled: true,
              fillColor: AppColors.bg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final t in _annonceurTypes) ...[
                BcChip(
                  label: t.$2,
                  selected: _annonceurType == t.$1,
                  onTap: () => setState(() => _annonceurType = t.$1),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 14),
          BcButton(
            label: _submittingCapacity ? 'Un instant...' : 'Confirmer',
            expand: false,
            onPressed: _submittingCapacity ? null : _becomeAnnonceur,
          ),
        ],
      ),
    );
  }
}
