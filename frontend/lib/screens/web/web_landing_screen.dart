import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../data/auth_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/breakpoints.dart';
import '../../widgets/bc_button.dart';
import '../../widgets/bc_icon.dart';
import '../../widgets/bc_logo.dart';
import '../auth/post_login_routing.dart';
import 'web_login_screen.dart';

const _features = [
  (
    'grid',
    'Publiez vos annonces',
    'Ajoutez photos et vidéos de vos biens en quelques minutes.',
  ),
  (
    'inbox',
    'Recevez les demandes',
    'Les locataires intéressés vous contactent directement.',
  ),
  (
    'chart',
    'Suivez vos biens',
    'Statut, fraîcheur et statistiques de vos annonces au même endroit.',
  ),
];

/// Point d'entrée web de Bailconnect — landing du back-office (jamais l'app
/// client, mobile uniquement). Vérifie d'abord une session existante :
/// un admin ou un bailleur déjà connecté est routé directement vers son
/// espace ([routeAfterAuth]) sans repasser par cette page.
class WebLandingScreen extends StatefulWidget {
  const WebLandingScreen({super.key});

  @override
  State<WebLandingScreen> createState() => _WebLandingScreenState();
}

const kClientMobileOnlyMessage =
    "L'espace locataire se trouve sur l'application mobile Bailconnect — recherchez et contactez des annonceurs depuis votre téléphone.";

class _WebLandingScreenState extends State<WebLandingScreen> {
  final _authRepository = AuthRepository(ApiClient());
  bool _showClientNotice = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoRoute());
  }

  Future<void> _autoRoute() async {
    final user = await _authRepository.me();
    if (!mounted) return;
    await routeAfterAuth(
      context,
      user,
      authRepository: _authRepository,
      isMobileBuild: isMobileLayout(context),
    );
  }

  void _openLogin() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const WebLoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _topBar(),
                    const SizedBox(height: 56),
                    _hero(context),
                    const SizedBox(height: 56),
                    _roleChoice(context),
                    const SizedBox(height: 64),
                    _featureGrid(context),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const BcLogoLockup(),
        BcButton(
          label: 'Se connecter',
          expand: false,
          onPressed: _openLogin,
        ),
      ],
    );
  }

  Widget _hero(BuildContext context) {
    final narrow = MediaQuery.of(context).size.width < 760;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.amberLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Espace bailleurs & équipe Bailconnect',
            style: TextStyle(
              color: AppColors.amber,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Gérez vos annonces Bailconnect\ndepuis votre navigateur',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: narrow ? 28 : 40,
            fontWeight: FontWeight.w800,
            height: 1.2,
            letterSpacing: -0.6,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: const Text(
            "Publiez vos biens, répondez aux demandes de locataires et suivez "
            "vos annonces. La recherche de logement se fait sur l'application "
            'mobile Bailconnect.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: AppColors.sub, height: 1.5),
          ),
        ),
        const SizedBox(height: 28),
        BcButton(
          label: 'Se connecter',
          icon: 'chevron',
          expand: false,
          onPressed: _openLogin,
        ),
      ],
    );
  }

  void _selectRole(String role) {
    if (role == 'client') {
      setState(() => _showClientNotice = true);
      return;
    }
    setState(() => _showClientNotice = false);
    _openLogin();
  }

  Widget _roleChoice(BuildContext context) {
    final narrow = MediaQuery.of(context).size.width < 760;
    const roles = [
      ('client', 'home', 'Locataire', 'Cherchez un logement et échangez avec des annonceurs.'),
      ('bailleur', 'grid', 'Bailleur', 'Publiez vos biens et suivez vos demandes.'),
      ('admin', 'settings', 'Administrateur', 'Modérez les annonces et gérez la plateforme.'),
    ];
    final cards = [for (final r in roles) _roleCard(r)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Vous êtes...',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.sub,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 16),
        narrow
            ? Column(
                children: [
                  for (final card in cards) ...[
                    card,
                    const SizedBox(height: 12),
                  ],
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    Expanded(child: cards[i]),
                    if (i != cards.length - 1) const SizedBox(width: 16),
                  ],
                ],
              ),
        if (_showClientNotice) ...[
          const SizedBox(height: 16),
          _clientNoticePanel(),
        ],
      ],
    );
  }

  Widget _roleCard((String, String, String, String) role) {
    final (id, icon, title, description) = role;
    final active = id == 'client' && _showClientNotice;
    return InkWell(
      onTap: () => _selectRole(id),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.paper,
          border: Border.all(
            color: active ? AppColors.amber : AppColors.line,
            width: active ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.greenLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: BcIcon(icon, size: 18, color: AppColors.greenDark),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.sub,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _clientNoticePanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.amberLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const BcIcon('phone', size: 18, color: AppColors.amber),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              kClientMobileOnlyMessage,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.ink,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureGrid(BuildContext context) {
    final narrow = MediaQuery.of(context).size.width < 760;
    final cards = [for (final f in _features) _featureCard(f)];
    if (narrow) {
      return Column(
        children: [
          for (final card in cards) ...[
            card,
            const SizedBox(height: 14),
          ],
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          Expanded(child: cards[i]),
          if (i != cards.length - 1) const SizedBox(width: 16),
        ],
      ],
    );
  }

  Widget _featureCard((String, String, String) feature) {
    final (icon, title, description) = feature;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.greenLight,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Center(
              child: BcIcon(icon, size: 19, color: AppColors.greenDark),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.sub,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
