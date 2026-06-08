// =============================================================================
// ARENA — Moteur de dames : le plateau (50 cases).
// =============================================================================

import 'package:arena/features_user/draughts/engine/draughts_geometry.dart';
import 'package:arena/features_user/draughts/engine/draughts_piece.dart';

/// État matériel du plateau : 50 cases jouables (`cells[i]` = contenu de la
/// case d'index `i`, soit le numéro `i + 1`). Immuable côté API : toute
/// modification passe par une copie (`copy`).
class DraughtsBoard {
  DraughtsBoard(List<Piece> cells)
      : assert(
          cells.length == DraughtsGeometry.squares,
          'Le plateau doit avoir exactement ${DraughtsGeometry.squares} cases',
        ),
        _cells = List<Piece>.unmodifiable(cells);

  /// Plateau vide.
  factory DraughtsBoard.empty() => DraughtsBoard(
        List<Piece>.filled(DraughtsGeometry.squares, Piece.empty),
      );

  /// Position de départ : 20 pions noirs (cases 1-20) en haut, 20 pions blancs
  /// (cases 31-50) en bas, les 2 rangées centrales (cases 21-30) vides.
  factory DraughtsBoard.initial() {
    final cells = List<Piece>.filled(DraughtsGeometry.squares, Piece.empty);
    for (var i = 0; i < 20; i++) {
      cells[i] = Piece.blackMan; // cases 1-20
    }
    for (var i = 30; i < 50; i++) {
      cells[i] = Piece.whiteMan; // cases 31-50
    }
    return DraughtsBoard(cells);
  }

  final List<Piece> _cells;

  List<Piece> get cells => _cells;

  Piece pieceAt(int index) => _cells[index];

  /// Liste des index occupés par une pièce du camp donné.
  List<int> indicesOf(Side side) {
    final out = <int>[];
    for (var i = 0; i < _cells.length; i++) {
      if (_cells[i].side == side) out.add(i);
    }
    return out;
  }

  int countOf(Side side) => indicesOf(side).length;

  /// Copie mutable des cases (pour appliquer un coup / explorer les rafles).
  List<Piece> mutableCells() => List<Piece>.from(_cells);

  @override
  String toString() {
    final b = StringBuffer();
    for (var row = 0; row < DraughtsGeometry.boardSize; row++) {
      for (var col = 0; col < DraughtsGeometry.boardSize; col++) {
        final idx = DraughtsGeometry.indexAt(row, col);
        if (idx < 0) {
          b.write('  ');
          continue;
        }
        switch (_cells[idx]) {
          case Piece.empty:
            b.write(' .');
          case Piece.whiteMan:
            b.write(' o');
          case Piece.whiteKing:
            b.write(' O');
          case Piece.blackMan:
            b.write(' x');
          case Piece.blackKing:
            b.write(' X');
        }
      }
      b.writeln();
    }
    return b.toString();
  }
}
