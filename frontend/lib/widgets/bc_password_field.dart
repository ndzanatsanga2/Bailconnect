import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Champ mot de passe avec bouton texte afficher/masquer (pas d'icône
/// « œil » dans le jeu d'icônes du design system) et aide optionnelle.
class BcPasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? helperText;

  const BcPasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.helperText,
  });

  @override
  State<BcPasswordField> createState() => _BcPasswordFieldState();
}

class _BcPasswordFieldState extends State<BcPasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _obscure,
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: widget.helperText,
        helperMaxLines: 2,
        filled: true,
        fillColor: AppColors.paper,
        suffixIcon: TextButton(
          onPressed: () => setState(() => _obscure = !_obscure),
          child: Text(
            _obscure ? 'Afficher' : 'Masquer',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.greenDark,
            ),
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: AppColors.line),
        ),
      ),
    );
  }
}
