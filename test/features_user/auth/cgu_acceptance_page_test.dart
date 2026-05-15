import 'package:arena/core/router/user_router.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_user/auth/cgu_acceptance_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

GoRouter _router(Widget body) => GoRouter(
      initialLocation: UserRoutes.cguAcceptance,
      routes: [
        GoRoute(
          path: UserRoutes.cguAcceptance,
          builder: (_, __) => body,
        ),
        GoRoute(
          path: UserRoutes.home,
          builder: (_, __) =>
              const Scaffold(body: Center(child: Text('HOME_STUB'))),
        ),
      ],
    );

Widget _scoped() => ProviderScope(
      child: MaterialApp.router(
        routerConfig: _router(const CguAcceptancePage()),
      ),
    );

void main() {
  testWidgets('renders title, country picker, WhatsApp field and two consents',
      (tester) async {
    await tester.pumpWidget(_scoped());
    await tester.pumpAndSettle();

    expect(find.textContaining('COMPLÈTE TON'), findsOneWidget);
    expect(find.text('PAYS'), findsOneWidget);
    expect(find.textContaining('WHATSAPP'), findsOneWidget);
    expect(find.byType(Checkbox), findsNWidgets(2));
  });

  testWidgets(
    'CTA stays disabled until CGU is checked AND a valid WhatsApp is typed',
    (tester) async {
      await tester.pumpWidget(_scoped());
      await tester.pumpAndSettle();

      // Disabled at start.
      var btn = tester.widget<ArenaButton>(find.byType(ArenaButton));
      expect(btn.onPressed, isNull);

      // Tick CGU only — still disabled (no WhatsApp).
      // La page contient maintenant pays + WhatsApp + 2 doc links avant
      // les checkboxes — ensureVisible() pour que le tap atterrisse.
      await tester.ensureVisible(find.byType(Checkbox).first);
      await tester.tap(find.byType(Checkbox).first);
      await tester.pump();
      btn = tester.widget<ArenaButton>(find.byType(ArenaButton));
      expect(btn.onPressed, isNull);

      // Type a valid WhatsApp local number — CTA enables.
      await tester.enterText(find.byType(TextField).first, '0707070707');
      await tester.pump();
      btn = tester.widget<ArenaButton>(find.byType(ArenaButton));
      expect(btn.onPressed, isNotNull);
    },
  );

  testWidgets('marketing checkbox can be toggled independently',
      (tester) async {
    await tester.pumpWidget(_scoped());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byType(Checkbox).last);
    await tester.tap(find.byType(Checkbox).last);
    await tester.pump();

    // CTA still disabled (no CGU + no WhatsApp).
    final btn = tester.widget<ArenaButton>(find.byType(ArenaButton));
    expect(btn.onPressed, isNull);

    final marketingCheckbox =
        tester.widget<Checkbox>(find.byType(Checkbox).last);
    expect(marketingCheckbox.value, isTrue);
  });

  testWidgets('tapping a doc link opens a placeholder dialog', (tester) async {
    await tester.pumpWidget(_scoped());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.textContaining('Lire les Conditions'));
    await tester.tap(find.textContaining('Lire les Conditions'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);
  });
}
