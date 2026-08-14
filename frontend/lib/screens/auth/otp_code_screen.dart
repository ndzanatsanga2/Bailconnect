import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bc_button.dart';
import '../../widgets/bc_icon.dart';
import '../../widgets/bc_logo.dart';
import '../../widgets/bc_mobile_frame.dart';

/// Saisie du code OTP — écran générique partagé par la connexion et les deux
/// parcours d'inscription ; le comportement de soumission est fourni par
/// l'appelant via [onSubmit] (connexion, inscription client, inscription
/// bailleur). Retourne `true` via Navigator.pop en cas de succès.
class OtpCodeScreen extends StatefulWidget {
  final String identifier;
  final Future<void> Function(String code) onSubmit;

  const OtpCodeScreen({
    super.key,
    required this.identifier,
    required this.onSubmit,
  });

  @override
  State<OtpCodeScreen> createState() => _OtpCodeScreenState();
}

class _OtpCodeScreenState extends State<OtpCodeScreen> {
  final _codeController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_codeController.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      await widget.onSubmit(_codeController.text.trim());
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
          child: Stack(
            children: [
              Positioned(
                top: 8,
                left: 8,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: BcIcon('back', size: 20, color: AppColors.ink),
                  ),
                ),
              ),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(child: BcLogoMark(size: 56)),
                        const SizedBox(height: 20),
                        const Text(
                          'Code de vérification',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Code envoyé à ${widget.identifier}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: AppColors.sub,
                          ),
                        ),
                        const SizedBox(height: 28),
                        TextField(
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            letterSpacing: 8,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Code à 6 chiffres',
                            filled: true,
                            fillColor: AppColors.paper,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(13),
                              borderSide: const BorderSide(
                                color: AppColors.line,
                              ),
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
            ],
          ),
        ),
      ),
    );
  }
}
