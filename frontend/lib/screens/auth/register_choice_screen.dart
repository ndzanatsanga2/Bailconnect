import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/bc_card.dart';
import '../../widgets/bc_icon.dart';
import '../../widgets/bc_mobile_frame.dart';
import 'open_auth_flow.dart';
import 'register_annonceur_screen.dart';
import 'register_client_screen.dart';

/// Choix du type de compte à créer — deux cartes, chacune vers son
/// formulaire d'inscription dédié.
class RegisterChoiceScreen extends StatelessWidget {
  const RegisterChoiceScreen({super.key});

  Future<void> _open(BuildContext context, WidgetBuilder builder) async {
    final created = await openAuthFlow<bool>(context, builder);
    if (created == true && context.mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return BcMobileFrame(
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: BcIcon('back', size: 20, color: AppColors.ink),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Créer un compte',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Choisissez le type de compte qui vous correspond.',
                  style: TextStyle(fontSize: 13.5, color: AppColors.sub),
                ),
                const SizedBox(height: 28),
                BcCard(
                  onTap: () =>
                      _open(context, (_) => const RegisterClientScreen()),
                  padding: const EdgeInsets.all(20),
                  child: _choiceRow(
                    icon: 'home',
                    title: 'Je cherche un logement',
                    subtitle:
                        'Parcourez le fil, contactez des annonceurs, sauvegardez vos favoris.',
                  ),
                ),
                const SizedBox(height: 14),
                BcCard(
                  onTap: () =>
                      _open(context, (_) => const RegisterAnnonceurScreen()),
                  padding: const EdgeInsets.all(20),
                  child: _choiceRow(
                    icon: 'grid',
                    title: 'Je propose un logement',
                    subtitle:
                        'Publiez vos annonces et recevez les demandes par WhatsApp.',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _choiceRow({
    required String icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.greenLight,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Center(
            child: BcIcon(icon, size: 21, color: AppColors.greenDark),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.sub,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const BcIcon('chevron', size: 16, color: AppColors.sub),
      ],
    );
  }
}
