import 'package:arena/features_user/draughts/engine/draughts_engine.dart';
import 'package:arena/features_user/draughts/ui/draughts_board_view.dart';
import 'package:arena/features_user/draughts/ui/draughts_clock.dart';
import 'package:arena/features_user/draughts/ui/draughts_game_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatClock', () {
    test('formate mm:ss', () {
      expect(formatClock(null), '--:--');
      expect(formatClock(600000), '10:00');
      expect(formatClock(65000), '01:05');
      expect(formatClock(0), '00:00');
    });
  });

  testWidgets('DraughtsBoardView se construit et peint le damier',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 360,
            child: DraughtsBoardView(
              state: DraughtsGameState.initial(),
              onMove: (_) {},
            ),
          ),
        ),
      ),
    );
    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.byType(DraughtsBoardView), findsOneWidget);
  });

  testWidgets('DraughtsGameScreen se construit sans crash', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DraughtsGameScreen()));
    await tester.pump();
    expect(find.byType(DraughtsBoardView), findsOneWidget);
    // Démonte l'écran pour annuler le Timer périodique de l'horloge.
    await tester.pumpWidget(const SizedBox());
  });
}
