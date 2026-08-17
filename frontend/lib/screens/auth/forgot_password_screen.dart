import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../data/auth_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bc_button.dart';
import '../../widgets/bc_icon.dart';
import '../../widgets/bc_mobile_frame.dart';
import '../../widgets/bc_otp_channel_select.dart';
import 'open_auth_flow.dart';
import 'reset_password_screen.dart';

/// Mot de passe oublié — étape 1 : choix explicite du canal (SMS ou email,
/// repli si le SMS n'arrive pas) puis demande du code OTP sur l'identifiant
/// correspondant.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _phoneController = TextEditingController(text: '+237');
  final _emailController = TextEditingController();
  final _authRepository = AuthRepository(ApiClient());
  String _otpChannel = 'sms';
  bool _loading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final identifier = _otpChannel == 'email'
        ? _emailController.text.trim()
        : _phoneController.text.trim();
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
                    BcOtpChannelSelect(
                      value: _otpChannel,
                      onChanged: (v) => setState(() => _otpChannel = v),
                    ),
                    const SizedBox(height: 14),
                    if (_otpChannel == 'email')
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          filled: true,
                          fillColor: AppColors.paper,
                          prefixIcon: const Padding(
                            padding: EdgeInsets.all(13),
                            child: BcIcon('chat', size: 16, color: AppColors.sub),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(13),
                            borderSide: const BorderSide(color: AppColors.line),
                          ),
                        ),
                      )
                    else
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Numéro de téléphone',
                          filled: true,
                          fillColor: AppColors.paper,
                          prefixIcon: const Padding(
                            padding: EdgeInsets.all(13),
                            child: BcIcon('phone', size: 16, color: AppColors.sub),
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
