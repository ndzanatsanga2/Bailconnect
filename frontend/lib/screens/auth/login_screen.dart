import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../data/auth_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bc_button.dart';
import '../../widgets/bc_icon.dart';
import '../../widgets/bc_logo.dart';
import '../../widgets/bc_mobile_frame.dart';
import '../../widgets/bc_password_field.dart';
import 'forgot_password_screen.dart';
import 'open_auth_flow.dart';
import 'register_choice_screen.dart';

/// Connexion — identifiant unique (email OU téléphone, détecté
/// automatiquement) + mot de passe. Retourne `true` via Navigator.pop en cas
/// de succès (inscription comprise, si l'utilisateur bascule sur ce parcours).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authRepository = AuthRepository(ApiClient());
  bool _rememberMe = true;
  bool _loading = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;
    if (identifier.isEmpty || password.isEmpty) return;
    setState(() => _loading = true);
    try {
      await _authRepository.login(
        identifier,
        password,
        rememberMe: _rememberMe,
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

  Future<void> _openRegister() async {
    final registered = await openAuthFlow<bool>(
      context,
      (_) => const RegisterChoiceScreen(),
    );
    if (registered == true && mounted) Navigator.of(context).pop(true);
  }

  Future<void> _openForgotPassword() async {
    final reset = await openAuthFlow<bool>(
      context,
      (_) => const ForgotPasswordScreen(),
    );
    if (reset == true && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return BcMobileFrame(
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 24,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: BcLogoMark(size: 64)),
                      const SizedBox(height: 20),
                      const Text(
                        'Connexion',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Retrouvez votre espace Bailconnect.',
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
                            child: BcIcon(
                              'user',
                              size: 16,
                              color: AppColors.sub,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(13),
                            borderSide: const BorderSide(color: AppColors.line),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      BcPasswordField(
                        controller: _passwordController,
                        label: 'Mot de passe',
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
                            onTap: () =>
                                setState(() => _rememberMe = !_rememberMe),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Checkbox(
                                    value: _rememberMe,
                                    onChanged: (v) =>
                                        setState(() => _rememberMe = v ?? true),
                                    activeColor: AppColors.green,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Se souvenir de moi',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _openForgotPassword,
                            child: const Text(
                              'Mot de passe oublié ?',
                              style: TextStyle(
                                color: AppColors.greenDark,
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      BcButton(
                        label: _loading ? 'Connexion...' : 'Se connecter',
                        onPressed: _loading ? null : _submit,
                      ),
                      const SizedBox(height: 22),
                      Center(
                        child: TextButton(
                          onPressed: _openRegister,
                          child: const Text(
                            'Créer un compte',
                            style: TextStyle(
                              color: AppColors.greenDark,
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
