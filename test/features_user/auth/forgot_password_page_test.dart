import 'package:arena/core/router/user_router.dart';
import 'package:arena/data/repositories/auth_repository.dart';
import 'package:arena/data/repositories/auth_failure.dart';
import 'package:arena/features_user/auth/forgot_password_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _FakeAuthRepository extends Mock implements AuthRepository {}

GoRouter _router(Widget body) => GoRouter(
      initialLocation: UserRoutes.forgotPassword,
      routes: [
        GoRoute(
          path: UserRoutes.forgotPassword,
          builder: (_, __) => body,
        ),
        GoRoute(
          path: UserRoutes.login,
          builder: (_, __) =>
              const Scaffold(body: Center(child: Text('LOGIN_STUB'))),
        ),
      ],
    );

Widget _scoped(AuthRepository repo) => ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp.router(
        routerConfig: _router(const ForgotPasswordPage()),
      ),
    );

void main() {
  late _FakeAuthRepository repo;

  setUp(() {
    repo = _FakeAuthRepository();
  });

  testWidgets('shows the request form on first render', (tester) async {
    await tester.pumpWidget(_scoped(repo));
    await tester.pumpAndSettle();

    expect(find.text('MOT DE PASSE OUBLIÉ'), findsOneWidget);
    expect(find.text('ENVOYER LE LIEN'), findsOneWidget);
  });

  testWidgets('submits and flips to success view when repo succeeds',
      (tester) async {
    when(
      () => repo.sendPasswordResetEmail(
        email: any(named: 'email'),
        redirectTo: any(named: 'redirectTo'),
      ),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(_scoped(repo));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'joueur@arena.app');
    await tester.tap(find.text('ENVOYER LE LIEN'));
    await tester.pumpAndSettle();

    expect(find.text('EMAIL ENVOYÉ'), findsOneWidget);
    expect(find.textContaining('joueur@arena.app'), findsOneWidget);
    verify(
      () => repo.sendPasswordResetEmail(
        email: 'joueur@arena.app',
        redirectTo: any(named: 'redirectTo'),
      ),
    ).called(1);
  });

  testWidgets('shows error banner when repo throws an AuthFailure',
      (tester) async {
    when(
      () => repo.sendPasswordResetEmail(
        email: any(named: 'email'),
        redirectTo: any(named: 'redirectTo'),
      ),
    ).thenThrow(const RateLimitedFailure());

    await tester.pumpWidget(_scoped(repo));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'joueur@arena.app');
    await tester.tap(find.text('ENVOYER LE LIEN'));
    await tester.pumpAndSettle();

    // Still on the request form (success view never appears).
    expect(find.text('EMAIL ENVOYÉ'), findsNothing);
    // The mapped message mentions the rate-limit hint.
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });
}
