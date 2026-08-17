import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../data/auth_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bc_button.dart';
import '../../widgets/bc_chip.dart';
import '../../widgets/bc_icon.dart';
import '../../widgets/bc_mobile_frame.dart';
import '../../widgets/bc_otp_channel_select.dart';
import '../../widgets/bc_password_field.dart';
import 'open_auth_flow.dart';
import 'otp_code_screen.dart';

const _annonceurTypes = [('bailleur', 'Bailleur'), ('agent', 'Agent')];

/// Inscription bailleur/agent (annonceur) — prénom, email, téléphone,
/// WhatsApp de contact des annonces, type de compte. Vérifiée par OTP SMS
/// ou email au choix.
class RegisterAnnonceurScreen extends StatefulWidget {
  const RegisterAnnonceurScreen({super.key});

  @override
  State<RegisterAnnonceurScreen> createState() =>
      _RegisterAnnonceurScreenState();
}

class _RegisterAnnonceurScreenState extends State<RegisterAnnonceurScreen> {
  final _authRepository = AuthRepository(ApiClient());
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController(text: '+237');
  final _whatsappController = TextEditingController(text: '+237');
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  String _type = 'bailleur';
  String _otpChannel = 'sms';
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _whatsappController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Merci de remplir tous les champs.')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final phone = _phoneController.text.trim();
      final email = _emailController.text.trim();
      final identifier = _otpChannel == 'email' ? email : phone;
      await _authRepository.requestOtp(identifier);
      if (!mounted) return;
      final verified = await openAuthFlow<bool>(
        context,
        (_) => OtpCodeScreen(
          identifier: identifier,
          onSubmit: (code) => _authRepository.registerAnnonceur(
            phoneNumber: phone,
            email: email,
            fullName: _nameController.text.trim(),
            whatsappNumber: _whatsappController.text.trim(),
            annonceurType: _type,
            password: _passwordController.text,
            passwordConfirm: _passwordConfirmController.text,
            code: code,
            otpChannel: _otpChannel,
          ),
        ),
      );
      if (verified == true && mounted) Navigator.of(context).pop(true);
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
                  'Compte bailleur',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Pour publier des annonces et recevoir des contacts.',
                  style: TextStyle(fontSize: 13.5, color: AppColors.sub),
                ),
                const SizedBox(height: 24),
                _field(_nameController, label: 'Prénom', icon: 'user'),
                const SizedBox(height: 14),
                _field(
                  _emailController,
                  label: 'Email',
                  icon: 'chat',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),
                _field(
                  _phoneController,
                  label: 'Numéro de téléphone',
                  icon: 'phone',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 14),
                _field(
                  _whatsappController,
                  label: 'Numéro WhatsApp (contact annonces)',
                  icon: 'chat',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Vous êtes',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.sub,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final t in _annonceurTypes) ...[
                      BcChip(
                        label: t.$2,
                        selected: _type == t.$1,
                        onTap: () => setState(() => _type = t.$1),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                BcPasswordField(
                  controller: _passwordController,
                  label: 'Mot de passe',
                  helperText:
                      'Au moins 8 caractères, pas uniquement des chiffres.',
                ),
                const SizedBox(height: 14),
                BcPasswordField(
                  controller: _passwordConfirmController,
                  label: 'Confirmer le mot de passe',
                ),
                const SizedBox(height: 16),
                BcOtpChannelSelect(
                  value: _otpChannel,
                  onChanged: (v) => setState(() => _otpChannel = v),
                ),
                const SizedBox(height: 22),
                BcButton(
                  label: _loading ? 'Envoi...' : 'Recevoir le code',
                  onPressed: _loading ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller, {
    required String label,
    required String icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.paper,
        prefixIcon: Padding(
          padding: const EdgeInsets.all(13),
          child: BcIcon(icon, size: 16, color: AppColors.sub),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: AppColors.line),
        ),
      ),
    );
  }
}
