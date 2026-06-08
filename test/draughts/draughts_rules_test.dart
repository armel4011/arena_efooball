import 'package:arena/features_user/draughts/engine/draughts_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Déplacements simples', () {
    test('ouverture : les Blancs ont 9 coups', () {
      final state = DraughtsGameState.initial();
      final moves = state.legalMoves();
      expect(moves.length, 9);
      expect(moves.every((m) => !m.isCapture), isTrue);
    });

    test('dame seule : déplacements à longue portée', () {
      // Dame blanche en case 28, plateau autrement vide.
      final state = DraughtsGameState.fromFen('W:WK28:B');
      final moves = state.legalMoves();
      expect(moves.isNotEmpty, isTrue);
      expect(moves.every((m) => !m.isCapture), isTrue);
      // Toutes les destinations sont distinctes et atteignables en diagonale.
      expect(moves.map((m) => m.to).toSet().length, moves.length);
    });
  });

  group('Prises (pion)', () {
    test('prise simple obligatoire', () {
      final state = DraughtsGameState.fromFen('W:W28:B22');
      final moves = state.legalMoves();
      expect(moves.length, 1);
      expect(moves.single.isCapture, isTrue);
      expect(moves.single.captured, [21]); // case 22 → index 21
      expect(moves.single.to, 16); // arrive case 17
    });

    test('prise en arrière autorisée', () {
      // Pion blanc en case 28 (rangée 5). Un pion noir en case 33 (rangée 6,
      // DERRIÈRE le pion blanc qui avance vers le haut) doit être capturable.
      // 28 = (5,4) ; 33 = (6,5) ; case d'arrivée (7,6) = case 39.
      final state = DraughtsGameState.fromFen('W:W28:B33');
      final moves = state.legalMoves();
      expect(moves.length, 1);
      expect(moves.single.captured, [32]); // case 33 → index 32
      expect(moves.single.to, 38); // case 39 → index 38
    });

    test('règle de majorité : la rafle double est forcée', () {
      final state = DraughtsGameState.fromFen('W:W28:B22,11,23');
      final moves = state.legalMoves();
      expect(moves.length, 1);
      final m = moves.single;
      expect(m.captured.length, 2);
      expect(m.captured.toSet(), {21, 10}); // cases 22 et 11
      expect(m.to, 5); // arrive case 6
    });
  });

  group('Prises (dame volante)', () {
    test('plusieurs cases d arrivée derrière la pièce capturée', () {
      final state = DraughtsGameState.fromFen('W:WK28:B22');
      final moves = state.legalMoves();
      expect(moves.length, 3);
      expect(
        moves.every((m) => m.captured.length == 1 && m.captured.first == 21),
        isTrue,
      );
      expect(moves.map((m) => m.to).toSet(), {16, 10, 5}); // cases 17,11,6
    });
  });

  group('Promotion', () {
    test('un pion qui s arrête sur la dernière rangée devient dame', () {
      // Pion blanc en case 7 (rangée 1). Avance vers la rangée 0 → promotion.
      final state = DraughtsGameState.fromFen('W:W7:B');
      final moves = state.legalMoves();
      expect(moves.isNotEmpty, isTrue);
      final promo = moves.firstWhere((m) => m.to == 0); // case 1, rangée 0
      final next = state.apply(promo);
      expect(next.board.pieceAt(0), Piece.whiteKing);
    });
  });

  group('deriveMove (animation depuis un diff réseau)', () {
    test('déplacement simple', () {
      final before = DraughtsGameState.fromFen('W:W28:B').board.cells;
      final after = DraughtsGameState.fromFen('W:W22:B').board.cells;
      final m = DraughtsRules.deriveMove(before, after);
      expect(m, isNotNull);
      expect(m!.from, 27); // case 28
      expect(m.to, 21); // case 22
      expect(m.captured, isEmpty);
    });

    test('prise (la pièce capturée disparaît)', () {
      // Avant : blanc 28, noir 22. Après : blanc 17 (a sauté 22).
      final before = DraughtsGameState.fromFen('W:W28:B22').board.cells;
      final after = DraughtsGameState.fromFen('W:W17:B').board.cells;
      final m = DraughtsRules.deriveMove(before, after);
      expect(m, isNotNull);
      expect(m!.from, 27);
      expect(m.to, 16); // case 17
      expect(m.captured, [21]); // case 22
    });

    test('rafle multi-saut : chemin EXACT reconstruit (pas une glisse)', () {
      // Avant : blanc 28, noirs 22 et 11 → rafle 28x22x11 arrivant case 6.
      final before = DraughtsGameState.fromFen('W:W28:B22,11').board.cells;
      final after = DraughtsGameState.fromFen('W:W6:B').board.cells;
      final m = DraughtsRules.deriveMove(before, after)!;
      expect(m.captured.toSet(), {21, 10}); // cases 22 et 11
      expect(m.path, [27, 16, 5]); // 28 → 17 → 6 : la case intermédiaire 17 !
    });

    test('réinitialisation (mort subite) → non dérivable', () {
      final before = DraughtsGameState.fromFen('W:W28:B').board.cells;
      final after = DraughtsGameState.initial().board.cells;
      expect(DraughtsRules.deriveMove(before, after), isNull);
    });
  });

  group('Issue de partie', () {
    test('camp sans pièce a perdu', () {
      final state = DraughtsGameState.fromFen('W:W:B1');
      expect(state.outcome(), DraughtsOutcome.blackWins);
    });

    test('camp au trait bloqué (aucun coup) a perdu', () {
      // Pion blanc en case 46 (9,0) : seule avance possible = case 41,
      // occupée par un pion noir ; case d'arrivée d une prise (case 37)
      // occupée → aucune prise. Blancs au trait, aucun coup légal.
      final state = DraughtsGameState.fromFen('W:W46:B41,37');
      expect(state.legalMoves(), isEmpty);
      expect(state.outcome(), DraughtsOutcome.blackWins);
    });

    test('position de départ : partie en cours', () {
      expect(DraughtsGameState.initial().outcome(), DraughtsOutcome.ongoing);
    });
  });
}
