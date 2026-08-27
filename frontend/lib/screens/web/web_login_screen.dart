import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../data/auth_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bc_button.dart';
import '../../widgets/bc_icon.dart';
import '../../widgets/bc_logo.dart';
import '../../widgets/bc_password_field.dart';
import '../auth/post_login_routing.dart';

/// Connexion web dédiée — page pleine écran (jamais le dialog centré de
/// [openAuthFlow], jamais de cadre téléphone), partagée par les deux rôles
/// admissibles sur le web : administrateur et bailleur. Le routage après
/// connexion (back-office, espace bailleur, ou refus pour un compte client
/// pur) est entièrement délégué à [routeAfterAuth].
class WebLoginScreen extends StatefulWidget {
  const WebLoginScreen({super.key});

  @override
  State<WebLoginScreen> createState() => _WebLoginScreenState();
}

class _WebLoginScreenState extends State<WebLoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authRepository = AuthRepository(ApiClient());
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
      final user = await _authRepository.login(
        identifier,
        password,
        rememberMe: true,
      );
      if (!mounted) return;
      await routeAfterAuth(context, user, authRepository: _authRepository);
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
    return Scaffold(
      backgroundColor: AppColors.greenDark,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 12,
              left: 12,
              child: InkWell(
                onTap: () => Navigator.of(context).maybePop(),
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: BcIcon('back', size: 19, color: Colors.white70),
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 32,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.paper,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: AppColors.cardShadowHover,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(child: BcLogoMark(size: 56)),
                        const SizedBox(height: 18),
                        const Text(
                          'Connexion',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Accédez à votre espace bailleur ou au back-office administrateur.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: AppColors.sub),
                        ),
                        const SizedBox(height: 26),
                        TextField(
                          controller: _identifierController,
                          decoration: InputDecoration(
                            labelText: 'Email ou numéro de téléphone',
                            filled: true,
                            fillColor: AppColors.bg,
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
                              borderSide: const BorderSide(
                                color: AppColors.line,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        BcPasswordField(
                          controller: _passwordController,
                          label: 'Mot de passe',
                        ),
                        const SizedBox(height: 22),
                        BcButton(
                          label: _loading ? 'Connexion...' : 'Se connecter',
                          onPressed: _loading ? null : _submit,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
