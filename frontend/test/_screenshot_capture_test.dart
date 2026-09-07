import 'package:bailconnect/data/api_client.dart';
import 'package:bailconnect/data/listing_repository.dart';
import 'package:bailconnect/screens/admin/admin_publish_listing_screen.dart';
import 'package:bailconnect/screens/annonceur/widgets/freshness_actions.dart';
import 'package:bailconnect/screens/auth/register_client_screen.dart';
import 'package:bailconnect/screens/web/web_landing_screen.dart';
import 'package:bailconnect/screens/web/web_login_screen.dart';
import 'package:bailconnect/theme/app_colors.dart';
import 'package:bailconnect/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _capture(
  WidgetTester tester, {
  required Widget screen,
  required Size size,
  required String goldenName,
}) async {
  await tester.binding.setSurfaceSize(size);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(theme: AppTheme.light(), home: screen));
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));

  await expectLater(find.byType(MaterialApp), matchesGoldenFile(goldenName));
}

void main() {
  testWidgets('register client screen with SMS/Email OTP toggle', (
    tester,
  ) async {
    await _capture(
      tester,
      screen: const RegisterClientScreen(),
      size: const Size(430, 1100),
      goldenName: 'goldens/register_client.png',
    );
  });

  testWidgets('admin publish listing screen', (tester) async {
    await _capture(
      tester,
      screen: const AdminPublishListingScreen(),
      size: const Size(1300, 1400),
      goldenName: 'goldens/admin_publish_listing.png',
    );
  });

  testWidgets('web login screen', (tester) async {
    await _capture(
      tester,
      screen: const WebLoginScreen(),
      size: const Size(1300, 900),
      goldenName: 'goldens/web_login.png',
    );
  });

  testWidgets('web landing screen', (tester) async {
    await _capture(
      tester,
      screen: const WebLandingScreen(),
      size: const Size(1300, 900),
      goldenName: 'goldens/web_landing.png',
    );
  });

  testWidgets('freshness actions with expiry relance banner', (tester) async {
    await _capture(
      tester,
      screen: Scaffold(
        backgroundColor: AppColors.bg,
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: FreshnessActions(
            listing: Listing(
              id: 1,
              title: 'Studio meublé',
              neighborhood: 'Bastos',
              propertyType: 'studio',
              rentAmount: 75000,
              depositAmount: 0,
              whatsappNumber: '+237600000000',
              status: 'expiree',
              media: const [],
            ),
            repository: ListingRepository(ApiClient()),
            onChanged: () {},
          ),
        ),
      ),
      size: const Size(520, 220),
      goldenName: 'goldens/freshness_relance_banner.png',
    );
  });
}
