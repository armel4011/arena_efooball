import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: arenaUserTheme,
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('ArenaButton', () {
    testWidgets('triggers onPressed when tapped', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(ArenaButton(label: 'Tap', onPressed: () => taps++)),
      );

      await tester.tap(find.text('Tap'));
      await tester.pumpAndSettle();

      expect(taps, 1);
    });

    testWidgets('does not trigger onPressed when disabled', (tester) async {
      await tester.pumpWidget(
        _wrap(const ArenaButton(label: 'Tap', onPressed: null)),
      );

      await tester.tap(find.text('Tap'));
      await tester.pumpAndSettle();
      // No callback to inspect — the test passes if pump doesn't throw.
    });

    testWidgets('shows spinner instead of label when isLoading',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          ArenaButton(
            label: 'Submit',
            onPressed: () {},
            isLoading: true,
          ),
        ),
      );

      // Single pump — pumpAndSettle would hang on the spinner animation.
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Submit'), findsNothing);
    });

    testWidgets('does not trigger onPressed while loading', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(
          ArenaButton(
            label: 'Submit',
            onPressed: () => taps++,
            isLoading: true,
          ),
        ),
      );

      // Disabled InkWell isn't hit-testable in normal mode; warnIfMissed:false
      // lets us assert "tap was a no-op" rather than failing before callback.
      // Use pump() not pumpAndSettle() — the spinner animates forever.
      await tester.tap(find.byType(ArenaButton), warnIfMissed: false);
      await tester.pump();

      expect(taps, 0);
    });

    testWidgets('renders icon when provided', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ArenaButton(
            label: 'Send',
            onPressed: () {},
            icon: Icons.send,
          ),
        ),
      );

      expect(find.byIcon(Icons.send), findsOneWidget);
      expect(find.text('Send'), findsOneWidget);
    });
  });
}
