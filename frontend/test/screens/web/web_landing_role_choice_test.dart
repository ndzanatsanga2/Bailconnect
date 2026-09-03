import 'package:bailconnect/screens/web/web_landing_screen.dart';
import 'package:bailconnect/screens/web/web_login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpLanding(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1300, 900));
    tester.view.physicalSize = const Size(1300, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: WebLandingScreen()));
    await tester.pumpAndSettle();
  }

  testWidgets('choisir Locataire affiche le message mobile-only sans naviguer', (
    tester,
  ) async {
    await pumpLanding(tester);

    expect(find.text(kClientMobileOnlyMessage), findsNothing);
    await tester.tap(find.text('Locataire'));
    await tester.pumpAndSettle();

    expect(find.text(kClientMobileOnlyMessage), findsOneWidget);
    expect(find.byType(WebLoginScreen), findsNothing);
  });

  testWidgets('choisir Bailleur ouvre la connexion web', (tester) async {
    await pumpLanding(tester);

    await tester.tap(find.text('Bailleur'));
    await tester.pumpAndSettle();

    expect(find.byType(WebLoginScreen), findsOneWidget);
  });

  testWidgets('choisir Administrateur ouvre la connexion web', (tester) async {
    await pumpLanding(tester);

    await tester.tap(find.text('Administrateur'));
    await tester.pumpAndSettle();

    expect(find.byType(WebLoginScreen), findsOneWidget);
  });
}
