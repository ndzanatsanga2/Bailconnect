import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../data/auth_repository.dart';
import '../../data/neighborhoods.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bc_button.dart';
import '../../widgets/bc_icon.dart';
import '../../widgets/bc_mobile_frame.dart';
import '../../widgets/bc_password_field.dart';
import 'open_auth_flow.dart';
import 'otp_code_screen.dart';

/// Inscription client (locataire) — prénom, email, téléphone, ville (liste
/// déroulante centralisée). Vérifiée par OTP SMS sur le numéro fourni.
class RegisterClientScreen extends StatefulWidget {
  const RegisterClientScreen({super.key});

  @override
  State<RegisterClientScreen> createState() => _RegisterClientScreenState();
}

class _RegisterClientScreenState extends State<RegisterClientScreen> {
  final _authRepository = AuthRepository(ApiClient());
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController(text: '+237');
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  String? _city;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _city == null ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Merci de remplir tous les champs.')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final phone = _phoneController.text.trim();
      await _authRepository.requestOtp(phone);
      if (!mounted) return;
      final verified = await openAuthFlow<bool>(
        context,
        (_) => OtpCodeScreen(
          identifier: phone,
          onSubmit: (code) => _authRepository.registerClient(
            phoneNumber: phone,
            email: _emailController.text.trim(),
            fullName: _nameController.text.trim(),
            city: _city!,
            password: _passwordController.text,
            passwordConfirm: _passwordConfirmController.text,
            code: code,
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
                  'Compte client',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Pour chercher un logement et contacter les annonceurs.',
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
                _citySelect(),
                const SizedBox(height: 14),
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

  Widget _citySelect() {
    return DropdownButtonFormField<String>(
      initialValue: _city,
      items: [
        for (final c in kCityChoices)
          DropdownMenuItem(value: c, child: Text(c)),
      ],
      onChanged: (v) => setState(() => _city = v),
      decoration: InputDecoration(
        labelText: 'Ville',
        filled: true,
        fillColor: AppColors.paper,
        prefixIcon: const Padding(
          padding: EdgeInsets.all(13),
          child: BcIcon('pin', size: 16, color: AppColors.sub),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: AppColors.line),
        ),
      ),
    );
  }
}
