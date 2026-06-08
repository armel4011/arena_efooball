import 'package:arena/features_user/draughts/engine/draughts_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('endgameCategory (classification matériel)', () {
    DraughtsEndgame catOf(String fen) =>
        DraughtsGameState.endgameCategory(DraughtsGameState.fromFen(fen).board);

    test('roi vs roi → 5 coups', () {
      expect(catOf('W:WK1:BK50'), DraughtsEndgame.fiveMove);
    });
    test('2 dames vs roi → 5 coups', () {
      expect(catOf('W:WK1,K2:BK50'), DraughtsEndgame.fiveMove);
    });
    test('1 dame + 1 pion vs roi → 5 coups', () {
      expect(catOf('W:WK1,5:BK50'), DraughtsEndgame.fiveMove);
    });
    test('3 dames vs roi → 16 coups', () {
      expect(catOf('W:WK1,K2,K3:BK50'), DraughtsEndgame.sixteenMove);
    });
    test('1 dame + 2 pions vs roi → 16 coups', () {
      expect(catOf('W:WK1,5,6:BK50'), DraughtsEndgame.sixteenMove);
    });
    test('3 pions (sans dame) vs roi → none', () {
      expect(catOf('W:W5,6,7:BK50'), DraughtsEndgame.none);
    });
    test('position d ouverture → none', () {
      expect(
        DraughtsGameState.endgameCategory(DraughtsGameState.initial().board),
        DraughtsEndgame.none,
      );
    });
  });

  group('Nulle — endgames accélérés', () {
    test('16 coups : nulle à 32 demi-coups, pas avant', () {
      const fen = 'W:WK1,K2,K3:BK50';
      expect(
        DraughtsGameState.fromFen(fen, endgamePlies: 31).outcome(),
        DraughtsOutcome.ongoing,
      );
      expect(
        DraughtsGameState.fromFen(fen, endgamePlies: 32).outcome(),
        DraughtsOutcome.draw,
      );
    });

    test('5 coups : nulle à 10 demi-coups', () {
      const fen = 'W:WK1,K2:BK50';
      expect(
        DraughtsGameState.fromFen(fen, endgamePlies: 9).outcome(),
        DraughtsOutcome.ongoing,
      );
      expect(
        DraughtsGameState.fromFen(fen, endgamePlies: 10).outcome(),
        DraughtsOutcome.draw,
      );
    });

    test('apply incrémente le compteur d endgame', () {
      final s = DraughtsGameState.fromFen('W:WK1,K2,K3:BK50');
      final move = s.legalMoves().firstWhere((m) => !m.isCapture);
      final next = s.apply(move);
      expect(next.endgamePlies, 1); // entré dans la config 16-coups
      expect(
        DraughtsGameState.endgameCategory(next.board),
        DraughtsEndgame.sixteenMove,
      );
    });
  });

  group('Nulle — répétition triple', () {
    test('même position vue 3 fois → nulle', () {
      // Position hors endgame (4 v 4) pour isoler la règle de répétition.
      const fen = 'W:WK1,K2,K3,K4:BK47,K48,K49,K50';
      final ref = DraughtsGameState.fromFen(fen);
      final s = DraughtsGameState(
        board: ref.board,
        turn: Side.white,
        positionCounts: {ref.positionKey: 3},
      );
      expect(s.outcome(), DraughtsOutcome.draw);
    });

    test('même position vue 2 fois → pas encore nulle', () {
      const fen = 'W:WK1,K2,K3,K4:BK47,K48,K49,K50';
      final ref = DraughtsGameState.fromFen(fen);
      final s = DraughtsGameState(
        board: ref.board,
        turn: Side.white,
        positionCounts: {ref.positionKey: 2},
      );
      expect(s.outcome(), DraughtsOutcome.ongoing);
    });
  });
}
