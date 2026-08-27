import 'package:bailconnect/app_config.dart';
import 'package:bailconnect/screens/auth/login_screen.dart';
import 'package:bailconnect/screens/auth/register_annonceur_screen.dart';
import 'package:bailconnect/screens/auth/register_client_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ces écrans lisent [AppConfig.otpRequired] (bool.fromEnvironment, fixé à
/// la compilation) pour savoir s'il faut afficher l'étape du code OTP.
/// Comme la valeur est figée pour tout le run de test, ces assertions sont
/// écrites pour rester vraies quelle que soit sa valeur ; pour vérifier
/// réellement les deux modes, lancer :
///   flutter test test/screens/auth/otp_optional_mode_test.dart
///   flutter test test/screens/auth/otp_optional_mode_test.dart --dart-define=OTP_REQUIRED=false
void main() {
  group('LoginScreen — lien mot de passe oublié', () {
    testWidgets('visible seulement si OTP_REQUIRED', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
      await tester.pump();

      final finder = find.text('Mot de passe oublié ?');
      expect(finder, AppConfig.otpRequired ? findsOneWidget : findsNothing);
    });
  });

  group('RegisterClientScreen — étape OTP', () {
    testWidgets('sélecteur de canal et libellé du bouton suivent OTP_REQUIRED', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: RegisterClientScreen()),
      );
      await tester.pump();

      final channelSelectFinder = find.text('SMS');
      expect(
        channelSelectFinder,
        AppConfig.otpRequired ? findsOneWidget : findsNothing,
      );

      final buttonLabel = AppConfig.otpRequired
          ? 'Recevoir le code'
          : 'Créer le compte';
      expect(find.text(buttonLabel), findsOneWidget);
    });
  });

  group('RegisterAnnonceurScreen — étape OTP', () {
    testWidgets('sélecteur de canal et libellé du bouton suivent OTP_REQUIRED', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: RegisterAnnonceurScreen()),
      );
      await tester.pump();

      final channelSelectFinder = find.text('SMS');
      expect(
        channelSelectFinder,
        AppConfig.otpRequired ? findsOneWidget : findsNothing,
      );

      final buttonLabel = AppConfig.otpRequired
          ? 'Recevoir le code'
          : 'Créer le compte';
      expect(find.text(buttonLabel), findsOneWidget);
    });
  });
}
