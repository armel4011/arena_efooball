import 'package:arena/core/router/user_router.dart';
import 'package:arena/data/repositories/auth_failure.dart';
import 'package:arena/data/repositories/auth_repository.dart';
import 'package:arena/features_user/auth/forgot_password_page.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
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
          name: 'user.forgotPassword',
          builder: (_, __) => body,
        ),
        GoRoute(
          path: UserRoutes.resetPasswordCode,
          name: 'user.resetPasswordCode',
          builder: (_, state) => Scaffold(
            body: Center(
              child: Text(
                'CODE_STUB:${state.uri.queryParameters['email'] ?? ''}',
              ),
            ),
          ),
        ),
        GoRoute(
          path: UserRoutes.login,
          name: 'user.login',
          builder: (_, __) =>
              const Scaffold(body: Center(child: Text('LOGIN_STUB'))),
        ),
      ],
    );

Widget _scoped(AuthRepository repo) => ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp.router(
        routerConfig: _router(const ForgotPasswordPage()),
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
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
    expect(find.text('ENVOYER LE CODE'), findsOneWidget);
  });

  testWidgets('submits and navigates to the code page when repo succeeds',
      (tester) async {
    when(
      () => repo.sendPasswordResetEmail(email: any(named: 'email')),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(_scoped(repo));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'joueur@arena.app');
    await tester.tap(find.text('ENVOYER LE CODE'));
    await tester.pumpAndSettle();

    expect(find.text('CODE_STUB:joueur@arena.app'), findsOneWidget);
    verify(
      () => repo.sendPasswordResetEmail(email: 'joueur@arena.app'),
    ).called(1);
  });

  testWidgets('shows error banner when repo throws an AuthFailure',
      (tester) async {
    when(
      () => repo.sendPasswordResetEmail(email: any(named: 'email')),
    ).thenThrow(const RateLimitedFailure());

    await tester.pumpWidget(_scoped(repo));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'joueur@arena.app');
    await tester.tap(find.text('ENVOYER LE CODE'));
    await tester.pumpAndSettle();

    // Still on the request form (no navigation happened).
    expect(find.text('CODE_STUB:joueur@arena.app'), findsNothing);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });
}
