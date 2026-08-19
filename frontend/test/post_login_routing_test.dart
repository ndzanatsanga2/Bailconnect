import 'package:bailconnect/data/api_client.dart';
import 'package:bailconnect/data/auth_repository.dart';
import 'package:bailconnect/screens/admin/admin_shell.dart';
import 'package:bailconnect/screens/auth/post_login_routing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake — évite tout appel réel au stockage sécurisé (indisponible dans
/// l'environnement de test) tout en observant si la déconnexion a eu lieu.
class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository() : super(ApiClient());

  bool loggedOut = false;

  @override
  Future<void> logout() async {
    loggedOut = true;
  }
}

AuthUser _user({required String role, bool isAnnonceur = false}) => AuthUser(
  id: 1,
  phoneNumber: '+237600000000',
  email: 'user@example.com',
  fullName: 'Test User',
  role: role,
  isAnnonceur: isAnnonceur,
  city: '',
  whatsappNumber: '',
  annonceurType: '',
);

Widget _appUnderTest(Widget Function(BuildContext) triggerBuilder) {
  return MaterialApp(
    initialRoute: '/',
    routes: {
      '/': (context) => Scaffold(body: Builder(builder: triggerBuilder)),
      kAdminRoute: (context) => const Text('ADMIN-SHELL'),
    },
  );
}

void main() {
  group('routeAfterAuth — exclusion admin sur mobile', () {
    testWidgets(
      'admin + build mobile : déconnecté immédiatement avec message clair, pas d\'accès au back-office',
      (tester) async {
        final fakeRepo = _FakeAuthRepository();
        late BuildContext capturedContext;

        await tester.pumpWidget(
          _appUnderTest((context) {
            capturedContext = context;
            return const SizedBox.shrink();
          }),
        );
        await tester.pump();

        await routeAfterAuth(
          capturedContext,
          _user(role: 'admin'),
          authRepository: fakeRepo,
          isMobileBuild: true,
        );
        await tester.pump();

        expect(fakeRepo.loggedOut, isTrue);
        expect(find.text(kAdminMobileBlockedMessage), findsOneWidget);
        expect(find.text('ADMIN-SHELL'), findsNothing);
      },
    );

    testWidgets('admin + build web : accès normal au back-office, pas de déconnexion', (
      tester,
    ) async {
      final fakeRepo = _FakeAuthRepository();
      late BuildContext capturedContext;

      await tester.pumpWidget(
        _appUnderTest((context) {
          capturedContext = context;
          return const SizedBox.shrink();
        }),
      );
      await tester.pump();

      await routeAfterAuth(
        capturedContext,
        _user(role: 'admin'),
        authRepository: fakeRepo,
        isMobileBuild: false,
      );
      await tester.pumpAndSettle();

      expect(fakeRepo.loggedOut, isFalse);
      expect(find.text('ADMIN-SHELL'), findsOneWidget);
    });

    testWidgets('compte client (non-admin) sur mobile : comportement inchangé', (tester) async {
      final fakeRepo = _FakeAuthRepository();
      late BuildContext capturedContext;

      await tester.pumpWidget(
        _appUnderTest((context) {
          capturedContext = context;
          return const SizedBox.shrink();
        }),
      );
      await tester.pump();

      await routeAfterAuth(
        capturedContext,
        _user(role: 'locataire'),
        authRepository: fakeRepo,
        isMobileBuild: true,
      );
      await tester.pump();

      expect(fakeRepo.loggedOut, isFalse);
      expect(find.text(kAdminMobileBlockedMessage), findsNothing);
      expect(find.text('ADMIN-SHELL'), findsNothing);
    });
  });
}
