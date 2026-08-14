import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../data/auth_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bc_button.dart';
import '../../widgets/bc_icon.dart';
import '../../widgets/bc_mobile_frame.dart';
import '../../widgets/bc_password_field.dart';

/// Mot de passe oublié — étape 2 : code OTP + nouveau mot de passe, en un
/// seul envoi. Reconnecte automatiquement en cas de succès.
class ResetPasswordScreen extends StatefulWidget {
  final String identifier;

  const ResetPasswordScreen({super.key, required this.identifier});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  final _authRepository = AuthRepository(ApiClient());
  bool _loading = false;

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_codeController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      return;
    }
    setState(() => _loading = true);
    try {
      await _authRepository.resetPassword(
        identifier: widget.identifier,
        code: _codeController.text.trim(),
        newPassword: _passwordController.text,
        newPasswordConfirm: _passwordConfirmController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BcMobileFrame(
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: SingleChildScrollView(
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
                  'Nouveau mot de passe',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Code envoyé à ${widget.identifier}',
                  style: const TextStyle(fontSize: 13.5, color: AppColors.sub),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    letterSpacing: 6,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Code à 6 chiffres',
                    filled: true,
                    fillColor: AppColors.paper,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(13),
                      borderSide: const BorderSide(color: AppColors.line),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                BcPasswordField(
                  controller: _passwordController,
                  label: 'Nouveau mot de passe',
                  helperText:
                      'Au moins 8 caractères, pas uniquement des chiffres.',
                ),
                const SizedBox(height: 14),
                BcPasswordField(
                  controller: _passwordConfirmController,
                  label: 'Confirmer le mot de passe',
                ),
                const SizedBox(height: 22),
                BcButton(
                  label: _loading ? 'Un instant...' : 'Réinitialiser',
                  icon: 'check',
                  onPressed: _loading ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
