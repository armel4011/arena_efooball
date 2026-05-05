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
  testWidgets('renders title, doc links and the two consent tiles',
      (tester) async {
    await tester.pumpWidget(_scoped());
    await tester.pumpAndSettle();

    expect(find.text('CONDITIONS GÉNÉRALES'), findsOneWidget);
    expect(find.textContaining('Conditions Générales'), findsWidgets);
    expect(find.textContaining('politique de confidentialité'), findsWidgets);
    expect(find.byType(Checkbox), findsNWidgets(2));
  });

  testWidgets('"accept" button is disabled until the CGU checkbox is checked',
      (tester) async {
    await tester.pumpWidget(_scoped());
    await tester.pumpAndSettle();

    final btn = tester.widget<ArenaButton>(find.byType(ArenaButton));
    expect(btn.onPressed, isNull, reason: 'CTA must start disabled');

    // Tick the first (mandatory) checkbox.
    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();

    final btnAfter = tester.widget<ArenaButton>(find.byType(ArenaButton));
    expect(btnAfter.onPressed, isNotNull);
  });

  testWidgets('marketing checkbox can be toggled independently',
      (tester) async {
    await tester.pumpWidget(_scoped());
    await tester.pumpAndSettle();

    // Tap second checkbox alone.
    await tester.tap(find.byType(Checkbox).last);
    await tester.pump();

    // Submit is still disabled — only marketing was ticked.
    final btn = tester.widget<ArenaButton>(find.byType(ArenaButton));
    expect(btn.onPressed, isNull);

    // The marketing tile checkbox is now checked.
    final marketingCheckbox =
        tester.widget<Checkbox>(find.byType(Checkbox).last);
    expect(marketingCheckbox.value, isTrue);
  });

  testWidgets('tapping a doc link opens a placeholder dialog', (tester) async {
    await tester.pumpWidget(_scoped());
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining("Lire les Conditions"));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);
  });
}
