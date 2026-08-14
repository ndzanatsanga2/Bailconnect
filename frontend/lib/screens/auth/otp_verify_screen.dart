import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../data/auth_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bc_button.dart';

/// Écran de connexion : ne fait qu'authentifier puis renvoie `true` à
/// l'appelant (Navigator.pop) — c'est à l'appelant de décider où naviguer
/// ensuite (tableau de bord annonceur, reprise d'une action client, etc.).
class OtpVerifyScreen extends StatefulWidget {
  final String identifier;
  final String role;

  const OtpVerifyScreen({super.key, required this.identifier, this.role = 'locataire'});

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  final _codeController = TextEditingController();
  final _authRepository = AuthRepository(ApiClient());
  bool _loading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await _authRepository.verifyOtp(widget.identifier, _codeController.text.trim(), role: widget.role);
      if (!mounted) return;
      Navigator.of(context).pop(true);
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
      appBar: AppBar(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Code de vérification',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.ink),
                ),
                const SizedBox(height: 8),
                Text(
                  'Code envoyé à ${widget.identifier}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13.5, color: AppColors.sub),
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, letterSpacing: 8, fontWeight: FontWeight.w700),
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
                const SizedBox(height: 18),
                BcButton(
                  label: _loading ? 'Vérification...' : 'Vérifier',
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
