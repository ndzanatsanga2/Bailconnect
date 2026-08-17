import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'bc_chip.dart';

/// Choix explicite du canal d'envoi du code OTP — SMS par défaut, email en
/// repli si le SMS n'arrive pas. Réutilisé par l'inscription (client,
/// annonceur) et le mot de passe oublié.
class BcOtpChannelSelect extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const BcOtpChannelSelect({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recevoir le code par',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: AppColors.sub,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            BcChip(
              label: 'SMS',
              selected: value == 'sms',
              onTap: () => onChanged('sms'),
            ),
            const SizedBox(width: 8),
            BcChip(
              label: 'Email',
              selected: value == 'email',
              onTap: () => onChanged('email'),
            ),
          ],
        ),
      ],
    );
  }
}
