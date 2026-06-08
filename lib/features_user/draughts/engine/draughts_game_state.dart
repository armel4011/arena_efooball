// =============================================================================
// ARENA — Moteur de dames : état de partie, application d'un coup, issue.
// =============================================================================

import 'package:arena/features_user/draughts/engine/draughts_board.dart';
import 'package:arena/features_user/draughts/engine/draughts_fen.dart';
import 'package:arena/features_user/draughts/engine/draughts_geometry.dart';
import 'package:arena/features_user/draughts/engine/draughts_move.dart';
import 'package:arena/features_user/draughts/engine/draughts_piece.dart';
import 'package:arena/features_user/draughts/engine/draughts_rules.dart';

/// Issue d'une partie.
enum DraughtsOutcome { ongoing, whiteWins, blackWins, draw }

/// État complet d'une partie : plateau, camp au trait, et compteur de demi-
/// coups « stériles » (sans prise ni mouvement de pion) pour la nulle.
///
/// NOTE (à affiner Phase 7) : la nulle FMJD complète combine plusieurs règles
/// d'endgame (ex. 25 coups, configurations dame contre dame). On implémente
/// ici le compteur de base (`drawPlyLimit`) ; les règles d'endgame fines sont
/// laissées en TODO et seront ajoutées avec les vecteurs de test dédiés.
class DraughtsGameState {
  const DraughtsGameState({
    required this.board,
    required this.turn,
    this.sterilePlies = 0,
  });

  factory DraughtsGameState.initial() => DraughtsGameState(
        board: DraughtsBoard.initial(),
        turn: Side.white,
      );

  factory DraughtsGameState.fromFen(String fen, {int sterilePlies = 0}) {
    final parsed = DraughtsFen.decode(fen);
    return DraughtsGameState(
      board: parsed.board,
      turn: parsed.turn,
      sterilePlies: sterilePlies,
    );
  }

  final DraughtsBoard board;
  final Side turn;
  final int sterilePlies;

  /// 25 coups (= 50 demi-coups) sans prise ni mouvement de pion → nulle.
  static const int drawPlyLimit = 50;

  String toFen() => DraughtsFen.encode(board, turn);

  List<DraughtsMove> legalMoves() => DraughtsRules.legalMoves(board, turn);

  /// Applique [move] (supposé légal) et renvoie le nouvel état (camp inversé).
  /// Gère la promotion : un pion promeut uniquement s'il TERMINE le coup sur
  /// sa rangée de promotion (pas s'il ne fait que la traverser en rafle).
  DraughtsGameState apply(DraughtsMove move) {
    final cells = board.mutableCells();
    final moving = cells[move.from];

    cells[move.from] = Piece.empty;
    for (final c in move.captured) {
      cells[c] = Piece.empty;
    }

    var placed = moving;
    if (moving.isMan &&
        DraughtsGeometry.rowOf(move.to) == turn.promotionRow) {
      placed = Piece.kingOf(turn);
    }
    cells[move.to] = placed;

    final progress = move.isCapture || moving.isMan;
    return DraughtsGameState(
      board: DraughtsBoard(cells),
      turn: turn.opponent,
      sterilePlies: progress ? 0 : sterilePlies + 1,
    );
  }

  /// Issue de la partie depuis cet état.
  DraughtsOutcome outcome() {
    if (board.countOf(turn) == 0) {
      return turn == Side.white
          ? DraughtsOutcome.blackWins
          : DraughtsOutcome.whiteWins;
    }
    if (legalMoves().isEmpty) {
      // Le camp au trait est bloqué → il perd.
      return turn == Side.white
          ? DraughtsOutcome.blackWins
          : DraughtsOutcome.whiteWins;
    }
    if (sterilePlies >= drawPlyLimit) {
      return DraughtsOutcome.draw;
    }
    return DraughtsOutcome.ongoing;
  }

  bool get isOver => outcome() != DraughtsOutcome.ongoing;
}
