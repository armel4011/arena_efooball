import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/features_shared/widgets/empty_state.dart';
import 'package:arena/features_shared/widgets/error_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: arenaUserTheme,
      home: Scaffold(body: child),
    );

void main() {
  group('EmptyState', () {
    testWidgets('renders title only when no description / action',
        (tester) async {
      await tester.pumpWidget(_wrap(const EmptyState(title: 'Vide')));
      expect(find.text('Vide'), findsOneWidget);
    });

    testWidgets('renders title, description and CTA', (tester) async {
      var actionTaps = 0;
      await tester.pumpWidget(
        _wrap(
          EmptyState(
            title: 'Pas de matchs',
            description: 'Aucun match prévu.',
            actionLabel: 'Actualiser',
            onAction: () => actionTaps++,
          ),
        ),
      );

      expect(find.text('Pas de matchs'), findsOneWidget);
      expect(find.text('Aucun match prévu.'), findsOneWidget);

      await tester.tap(find.text('Actualiser'));
      await tester.pumpAndSettle();

      expect(actionTaps, 1);
    });
  });

  group('ErrorState', () {
    testWidgets('default title when none provided', (tester) async {
      await tester.pumpWidget(_wrap(const ErrorState()));
      expect(find.text('Une erreur est survenue'), findsOneWidget);
    });

    testWidgets('retry CTA fires onRetry', (tester) async {
      var retries = 0;
      await tester.pumpWidget(_wrap(ErrorState(onRetry: () => retries++)));

      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();

      expect(retries, 1);
    });

    testWidgets('hides retry CTA when onRetry is null', (tester) async {
      await tester.pumpWidget(_wrap(const ErrorState()));
      expect(find.text('Réessayer'), findsNothing);
    });
  });
}
