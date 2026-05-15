import 'package:arena/core/router/user_router.dart';
import 'package:arena/features_user/auth/link_existing_account_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

GoRouter _router(Widget body) => GoRouter(
      initialLocation: UserRoutes.linkAccount,
      routes: [
        GoRoute(
          path: UserRoutes.linkAccount,
          builder: (_, __) => body,
        ),
        GoRoute(
          path: UserRoutes.login,
          builder: (_, __) =>
              const Scaffold(body: Center(child: Text('LOGIN_STUB'))),
        ),
      ],
    );

Widget _scoped(Widget body) => ProviderScope(
      child: MaterialApp.router(routerConfig: _router(body)),
    );

void main() {
  testWidgets('renders both link and password CTAs', (tester) async {
    await tester.pumpWidget(_scoped(const LinkExistingAccountPage()));
    await tester.pumpAndSettle();

    expect(find.text('Compte déjà existant'), findsOneWidget);
    expect(find.text('🔗 LIER LES DEUX COMPTES'), findsOneWidget);
    expect(find.text('ME CONNECTER AVEC MOT DE PASSE'), findsOneWidget);
  });

  testWidgets('shows the email hint when provided', (tester) async {
    await tester.pumpWidget(
      _scoped(
        const LinkExistingAccountPage(
          email: 'joueur@arena.app',
          providerLabel: 'Google',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('joueur@arena.app'), findsOneWidget);
  });

  testWidgets('"link" CTA shows the PHASE 2.3 deferred snackbar',
      (tester) async {
    await tester.pumpWidget(_scoped(const LinkExistingAccountPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('🔗 LIER LES DEUX COMPTES'));
    await tester.pump(); // let the snackbar mount

    expect(find.textContaining('PHASE 2.3'), findsOneWidget);
  });

  testWidgets('"password" CTA navigates to the login route', (tester) async {
    await tester.pumpWidget(_scoped(const LinkExistingAccountPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ME CONNECTER AVEC MOT DE PASSE'));
    await tester.pumpAndSettle();

    expect(find.text('LOGIN_STUB'), findsOneWidget);
  });
}
