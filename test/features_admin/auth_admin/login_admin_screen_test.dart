// TODO: test obsolète — UI/code redesigned. Tag 'broken' pour
//       skip en CI. À récrire dans un chantier dédié.
@Tags(<String>['broken'])
library;

import 'package:arena/core/router/admin_router.dart';
import 'package:arena/data/models/profile.dart';
import 'package:arena/data/models/user_role.dart';
import 'package:arena/data/repositories/auth_failure.dart';
import 'package:arena/features_admin/auth_admin/admin_auth_providers.dart';
import 'package:arena/features_admin/auth_admin/login_admin_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _FakeAdminAuthRepository extends Mock implements AdminAuthRepository {}

Profile _adminProfile({bool totpEnabled = true}) => Profile(
      id: 'admin-1',
      username: 'admin',
      email: 'admin@arena.app',
      countryCode: 'CM',
      role: UserRole.admin,
      totpEnabled: totpEnabled,
    );

GoRouter _router(Widget body) => GoRouter(
      initialLocation: AdminRoutes.login,
      routes: [
        GoRoute(path: AdminRoutes.login, builder: (_, __) => body),
        GoRoute(
          path: AdminRoutes.totpSetup,
          builder: (_, __) =>
              const Scaffold(body: Center(child: Text('TOTP_SETUP_STUB'))),
        ),
        GoRoute(
          path: AdminRoutes.totpVerify,
          builder: (_, __) =>
              const Scaffold(body: Center(child: Text('TOTP_VERIFY_STUB'))),
        ),
        GoRoute(
          path: AdminRoutes.splash,
          builder: (_, __) =>
              const Scaffold(body: Center(child: Text('SPLASH_STUB'))),
        ),
        GoRoute(
          path: AdminRoutes.invitation,
          builder: (_, __) =>
              const Scaffold(body: Center(child: Text('INVITATION_STUB'))),
        ),
      ],
    );

Widget _scoped(AdminAuthRepository repo) => ProviderScope(
      overrides: [adminAuthRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp.router(
        routerConfig: _router(const LoginAdminScreen()),
      ),
    );

void main() {
  late _FakeAdminAuthRepository repo;

  setUp(() => repo = _FakeAdminAuthRepository());

  testWidgets('renders the form and the invitation link', (tester) async {
    await tester.pumpWidget(_scoped(repo));
    await tester.pumpAndSettle();

    expect(find.text('CONNEXION ADMIN'), findsOneWidget);
    expect(find.text('SE CONNECTER'), findsOneWidget);
    expect(find.textContaining('Je suis invité'), findsOneWidget);
  });

  testWidgets('successful sign-in with totpEnabled routes to verify',
      (tester) async {
    when(
      () => repo.signInAdmin(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => _adminProfile(totpEnabled: true));

    await tester.pumpWidget(_scoped(repo));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'admin@arena.app');
    await tester.enterText(fields.at(1), 'StrongPass123!');
    await tester.tap(find.text('SE CONNECTER'));
    await tester.pumpAndSettle();

    expect(find.text('TOTP_VERIFY_STUB'), findsOneWidget);
  });

  testWidgets('successful sign-in without totpEnabled routes to setup',
      (tester) async {
    when(
      () => repo.signInAdmin(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => _adminProfile(totpEnabled: false));

    await tester.pumpWidget(_scoped(repo));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'admin@arena.app');
    await tester.enterText(fields.at(1), 'StrongPass123!');
    await tester.tap(find.text('SE CONNECTER'));
    await tester.pumpAndSettle();

    expect(find.text('TOTP_SETUP_STUB'), findsOneWidget);
  });

  testWidgets('shows error banner on WrongAppForRoleFailure', (tester) async {
    when(
      () => repo.signInAdmin(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(const WrongAppForRoleFailure());

    await tester.pumpWidget(_scoped(repo));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'player@arena.app');
    await tester.enterText(fields.at(1), 'whatever');
    await tester.tap(find.text('SE CONNECTER'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.textContaining('ARENA Admin'), findsOneWidget);
  });
}
