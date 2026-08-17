import 'package:bailconnect/screens/admin/admin_login_screen.dart';
import 'package:bailconnect/screens/admin/admin_publish_listing_screen.dart';
import 'package:bailconnect/screens/auth/register_client_screen.dart';
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

  testWidgets('admin login screen', (tester) async {
    await _capture(
      tester,
      screen: const AdminLoginScreen(),
      size: const Size(1300, 900),
      goldenName: 'goldens/admin_login.png',
    );
  });
}
