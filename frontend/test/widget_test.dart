import 'package:bailconnect/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Démarre sur le fil public, consultable sans connexion', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const BailconnectApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Accueil'), findsOneWidget);
    expect(find.text('Recherche'), findsOneWidget);
    expect(find.text('Favoris'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);
  });
}
