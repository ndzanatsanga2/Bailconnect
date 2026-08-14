import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../data/auth_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bc_button.dart';
import '../../widgets/bc_icon.dart';
import '../../widgets/bc_mobile_frame.dart';
import 'open_auth_flow.dart';
import 'reset_password_screen.dart';

/// Mot de passe oublié — étape 1 : demande du code OTP sur l'identifiant
/// (email ou téléphone), envoyé par SMS ou email selon le canal détecté.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _identifierController = TextEditingController();
  final _authRepository = AuthRepository(ApiClient());
  bool _loading = false;

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final identifier = _identifierController.text.trim();
    if (identifier.isEmpty) return;
    setState(() => _loading = true);
    try {
      await _authRepository.requestOtp(identifier);
      if (!mounted) return;
      final reset = await openAuthFlow<bool>(
        context,
        (_) => ResetPasswordScreen(identifier: identifier),
      );
      if (reset == true && mounted) Navigator.of(context).pop(true);
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
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(20),
                      child: const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.all(4),
                          child: BcIcon('back', size: 20, color: AppColors.ink),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Mot de passe oublié',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Recevez un code de vérification pour définir un nouveau mot de passe.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13.5, color: AppColors.sub),
                    ),
                    const SizedBox(height: 28),
                    TextField(
                      controller: _identifierController,
                      decoration: InputDecoration(
                        labelText: 'Email ou numéro de téléphone',
                        filled: true,
                        fillColor: AppColors.paper,
                        prefixIcon: const Padding(
                          padding: EdgeInsets.all(13),
                          child: BcIcon('user', size: 16, color: AppColors.sub),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13),
                          borderSide: const BorderSide(color: AppColors.line),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    BcButton(
                      label: _loading ? 'Envoi...' : 'Recevoir le code',
                      onPressed: _loading ? null : _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
