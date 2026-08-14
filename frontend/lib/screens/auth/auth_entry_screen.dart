import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../data/auth_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bc_button.dart';
import '../../widgets/bc_logo.dart';
import 'otp_verify_screen.dart';

enum _Channel { phone, email }

/// Écran de connexion — téléphone OU email, au choix, pour les 3 rôles.
/// Retourne `true` via Navigator.pop en cas de succès.
class AuthEntryScreen extends StatefulWidget {
  final String role;

  const AuthEntryScreen({super.key, this.role = 'locataire'});

  @override
  State<AuthEntryScreen> createState() => _AuthEntryScreenState();
}

class _AuthEntryScreenState extends State<AuthEntryScreen> {
  _Channel _channel = _Channel.phone;
  final _controller = TextEditingController(text: '+237');
  final _authRepository = AuthRepository(ApiClient());
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _switchChannel(_Channel channel) {
    setState(() {
      _channel = channel;
      _controller.text = channel == _Channel.phone ? '+237' : '';
    });
  }

  Future<void> _submit() async {
    final raw = _controller.text.trim();
    final identifier = _channel == _Channel.phone ? raw.replaceAll(RegExp(r'\s+'), '') : raw;
    if (identifier.isEmpty) return;

    setState(() => _loading = true);
    try {
      await _authRepository.requestOtp(identifier);
      if (!mounted) return;
      final verified = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => OtpVerifyScreen(identifier: identifier, role: widget.role)),
      );
      if (verified == true && mounted) {
        Navigator.of(context).pop(true);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: BcLogoMark(size: 64)),
                  const SizedBox(height: 20),
                  const Text(
                    'Connexion',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.ink),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Recevez un code de vérification, sans mot de passe.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13.5, color: AppColors.sub),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: const Color(0xFFEEF2F0), borderRadius: BorderRadius.circular(13)),
                    child: Row(
                      children: [
                        Expanded(child: _channelTab('Téléphone', _Channel.phone)),
                        Expanded(child: _channelTab('Email', _Channel.email)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _controller,
                    keyboardType: _channel == _Channel.phone ? TextInputType.phone : TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: _channel == _Channel.phone ? 'Numéro de téléphone' : 'Adresse email',
                      filled: true,
                      fillColor: AppColors.paper,
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
    );
  }

  Widget _channelTab(String label, _Channel channel) {
    final selected = _channel == channel;
    return InkWell(
      onTap: () => _switchChannel(channel),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(color: selected ? AppColors.paper : Colors.transparent, borderRadius: BorderRadius.circular(10)),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: selected ? AppColors.ink : AppColors.sub),
        ),
      ),
    );
  }
}
