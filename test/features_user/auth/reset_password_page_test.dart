import 'package:arena/core/router/user_router.dart';
import 'package:arena/data/repositories/auth_failure.dart';
import 'package:arena/data/repositories/auth_repository.dart';
import 'package:arena/features_user/auth/reset_password_page.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _FakeAuthRepository extends Mock implements AuthRepository {}

GoRouter _router(Widget body) => GoRouter(
      initialLocation: UserRoutes.resetPassword,
      routes: [
        GoRoute(
          path: UserRoutes.resetPassword,
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
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: _router(const ResetPasswordPage()),
      ),
    );

void main() {
  late _FakeAuthRepository repo;

  setUp(() {
    repo = _FakeAuthRepository();
  });

  testWidgets('shows the form with two password fields', (tester) async {
    await tester.pumpWidget(_scoped(repo));
    await tester.pumpAndSettle();

    expect(find.text('NOUVEAU MOT DE PASSE'), findsWidgets);
    expect(find.text('METTRE À JOUR'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
  });

  testWidgets('rejects empty password', (tester) async {
    await tester.pumpWidget(_scoped(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('METTRE À JOUR'));
    await tester.pumpAndSettle();

    expect(find.text('Mot de passe requis'), findsOneWidget);
    verifyNever(() => repo.updatePassword(any()));
  });

  testWidgets('rejects passwords shorter than 8 chars', (tester) async {
    await tester.pumpWidget(_scoped(repo));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'short');
    await tester.enterText(fields.at(1), 'short');
    await tester.tap(find.text('METTRE À JOUR'));
    await tester.pumpAndSettle();

    expect(find.text('Minimum 8 caractères'), findsOneWidget);
    verifyNever(() => repo.updatePassword(any()));
  });

  testWidgets('rejects mismatched confirmation', (tester) async {
    await tester.pumpWidget(_scoped(repo));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'longenough1');
    await tester.enterText(fields.at(1), 'different1');
    await tester.tap(find.text('METTRE À JOUR'));
    await tester.pumpAndSettle();

    expect(find.text('Les mots de passe ne correspondent pas'), findsOneWidget);
    verifyNever(() => repo.updatePassword(any()));
  });

  testWidgets('submits and shows success view on repo success',
      (tester) async {
    when(() => repo.updatePassword(any())).thenAnswer((_) async {});

    await tester.pumpWidget(_scoped(repo));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'longenough1');
    await tester.enterText(fields.at(1), 'longenough1');
    await tester.tap(find.text('METTRE À JOUR'));
    await tester.pumpAndSettle();

    expect(find.text('MOT DE PASSE MIS À JOUR'), findsOneWidget);
    expect(find.text('SE CONNECTER'), findsOneWidget);
    verify(() => repo.updatePassword('longenough1')).called(1);
  });

  testWidgets('shows error banner when repo throws an AuthFailure',
      (tester) async {
    when(() => repo.updatePassword(any()))
        .thenThrow(const WeakPasswordFailure());

    await tester.pumpWidget(_scoped(repo));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'longenough1');
    await tester.enterText(fields.at(1), 'longenough1');
    await tester.tap(find.text('METTRE À JOUR'));
    await tester.pumpAndSettle();

    expect(find.text('MOT DE PASSE MIS À JOUR'), findsNothing);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });
}
