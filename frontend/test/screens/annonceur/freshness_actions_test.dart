import 'package:bailconnect/data/api_client.dart';
import 'package:bailconnect/data/listing_repository.dart';
import 'package:bailconnect/screens/annonceur/widgets/freshness_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Listing _listing(String status) => Listing(
  id: 1,
  title: 'Studio meublé',
  neighborhood: 'Bastos',
  propertyType: 'studio',
  rentAmount: 75000,
  depositAmount: 0,
  whatsappNumber: '+237600000000',
  status: status,
  media: const [],
);

void main() {
  const relanceText =
      'Annonce expirée — confirmez sa disponibilité, sinon elle sera archivée automatiquement.';

  testWidgets('affiche la relance quand l\'annonce est expirée', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FreshnessActions(
            listing: _listing('expiree'),
            repository: ListingRepository(ApiClient()),
            onChanged: () {},
          ),
        ),
      ),
    );

    expect(find.text(relanceText), findsOneWidget);
  });

  testWidgets('pas de relance pour une annonce publiée', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FreshnessActions(
            listing: _listing('publiee'),
            repository: ListingRepository(ApiClient()),
            onChanged: () {},
          ),
        ),
      ),
    );

    expect(find.text(relanceText), findsNothing);
  });
}
