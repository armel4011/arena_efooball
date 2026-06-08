import 'package:arena/features_user/draughts/engine/draughts_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Géométrie 10×10', () {
    test('round-trip index ↔ (row,col) sur les 50 cases', () {
      for (var i = 0; i < DraughtsGeometry.squares; i++) {
        final row = DraughtsGeometry.rowOf(i);
        final col = DraughtsGeometry.colOf(i);
        expect(DraughtsGeometry.indexAt(row, col), i, reason: 'case ${i + 1}');
      }
    });

    test('cases claires et hors plateau renvoient -1', () {
      // (0,0) est une case claire (rangée paire → colonne paire = claire).
      expect(DraughtsGeometry.indexAt(0, 0), -1);
      expect(DraughtsGeometry.indexAt(1, 1), -1);
      expect(DraughtsGeometry.indexAt(-1, 1), -1);
      expect(DraughtsGeometry.indexAt(10, 1), -1);
    });

    test('cases de coin attendues', () {
      expect(DraughtsGeometry.indexAt(0, 1), 0); // case 1
      expect(DraughtsGeometry.indexAt(9, 8), 49); // case 50
      expect(DraughtsGeometry.indexAt(1, 0), 5); // case 6
    });
  });

  group('Position de départ', () {
    final board = DraughtsBoard.initial();

    test('20 pions blancs (cases 31-50) et 20 pions noirs (cases 1-20)', () {
      expect(board.countOf(Side.white), 20);
      expect(board.countOf(Side.black), 20);
      for (var sq = 1; sq <= 20; sq++) {
        expect(board.pieceAt(sq - 1), Piece.blackMan, reason: 'case $sq');
      }
      for (var sq = 31; sq <= 50; sq++) {
        expect(board.pieceAt(sq - 1), Piece.whiteMan, reason: 'case $sq');
      }
    });

    test('10 cases centrales vides (21-30)', () {
      for (var sq = 21; sq <= 30; sq++) {
        expect(board.pieceAt(sq - 1), Piece.empty, reason: 'case $sq');
      }
    });

    test('aucune dame au départ', () {
      for (final p in board.cells) {
        expect(p.isKing, isFalse);
      }
    });
  });

  group('FEN', () {
    test('round-trip sur la position de départ', () {
      final state = DraughtsGameState.initial();
      final fen = state.toFen();
      expect(fen.startsWith('W:W'), isTrue);
      final reparsed = DraughtsGameState.fromFen(fen);
      expect(reparsed.toFen(), fen);
      expect(reparsed.turn, Side.white);
      expect(reparsed.board.countOf(Side.white), 20);
      expect(reparsed.board.countOf(Side.black), 20);
    });

    test('encode/décode dames et trait noir', () {
      const fen = 'B:WK50:BK1,2';
      final parsed = DraughtsGameState.fromFen(fen);
      expect(parsed.turn, Side.black);
      expect(parsed.board.pieceAt(49), Piece.whiteKing);
      expect(parsed.board.pieceAt(0), Piece.blackKing);
      expect(parsed.board.pieceAt(1), Piece.blackMan);
      expect(parsed.toFen(), fen);
    });

    test('FEN malformée lève une FormatException', () {
      expect(() => DraughtsFen.decode('garbage'), throwsFormatException);
      expect(() => DraughtsFen.decode('X:W1:B2'), throwsFormatException);
    });
  });
}
