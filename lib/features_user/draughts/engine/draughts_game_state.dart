// =============================================================================
// ARENA — Moteur de dames : état de partie, application d'un coup, issue.
// =============================================================================
// Implémente les 4 règles de nulle FMJD (international 10×10) :
//   a) Répétition triple : même position (plateau + trait) vue 3 fois → nulle.
//   b) 25 coups : 50 demi-coups sans prise NI mouvement de pion → nulle.
//   c) 16 coups : un roi seul contre {3 dames | 2 dames+1 pion | 1 dame+2 pions}
//      → nulle si non gagné en 16 coups par camp (32 demi-coups).
//   d) 5 coups : un roi seul contre {1 dame | 2 dames | 1 dame+1 pion}
//      (inclut roi vs roi) → nulle après 5 coups par camp (10 demi-coups).
//
// Les compteurs (sterile/endgame) et l'historique de répétition sont THREADÉS
// dans l'état immuable (et persistés côté DB pour que l'Edge Function — qui
// fait foi — détecte les nulles sans rejouer toute la partie).
// =============================================================================

import 'package:arena/features_user/draughts/engine/draughts_board.dart';
import 'package:arena/features_user/draughts/engine/draughts_fen.dart';
import 'package:arena/features_user/draughts/engine/draughts_geometry.dart';
import 'package:arena/features_user/draughts/engine/draughts_move.dart';
import 'package:arena/features_user/draughts/engine/draughts_piece.dart';
import 'package:arena/features_user/draughts/engine/draughts_rules.dart';

/// Issue d'une partie.
enum DraughtsOutcome { ongoing, whiteWins, blackWins, draw }

/// Configuration d'endgame soumise à une règle de nulle accélérée.
enum DraughtsEndgame { none, fiveMove, sixteenMove }

/// État complet d'une partie : plateau, trait, et l'état nécessaire aux règles
/// de nulle (compteur stérile, compteur d'endgame, historique de positions).
class DraughtsGameState {
  DraughtsGameState({
    required this.board,
    required this.turn,
    this.sterilePlies = 0,
    this.endgamePlies = 0,
    Map<String, int>? positionCounts,
  }) : positionCounts = positionCounts ?? const {};

  factory DraughtsGameState.initial() {
    final board = DraughtsBoard.initial();
    final key = DraughtsFen.encode(board, Side.white);
    return DraughtsGameState(
      board: board,
      turn: Side.white,
      positionCounts: {key: 1},
    );
  }

  /// Reconstruit depuis une FEN. Sans `positionCounts`, la position courante
  /// est comptée une fois (pas d'historique antérieur connu).
  factory DraughtsGameState.fromFen(
    String fen, {
    int sterilePlies = 0,
    int endgamePlies = 0,
    Map<String, int>? positionCounts,
  }) {
    final parsed = DraughtsFen.decode(fen);
    final counts = positionCounts ??
        {DraughtsFen.encode(parsed.board, parsed.turn): 1};
    return DraughtsGameState(
      board: parsed.board,
      turn: parsed.turn,
      sterilePlies: sterilePlies,
      endgamePlies: endgamePlies,
      positionCounts: counts,
    );
  }

  final DraughtsBoard board;
  final Side turn;
  final int sterilePlies;
  final int endgamePlies;

  /// Nombre d'occurrences de chaque position (clé FEN plateau+trait), pour la
  /// règle de répétition triple.
  final Map<String, int> positionCounts;

  /// 25 coups (= 50 demi-coups) sans prise ni mouvement de pion → nulle.
  static const int drawPlyLimit = 50;

  /// 16 coups par camp = 32 demi-coups.
  static const int sixteenMovePlyLimit = 32;

  /// 5 coups par camp = 10 demi-coups.
  static const int fiveMovePlyLimit = 10;

  String get positionKey => DraughtsFen.encode(board, turn);

  String toFen() => DraughtsFen.encode(board, turn);

  List<DraughtsMove> legalMoves() => DraughtsRules.legalMoves(board, turn);

  /// Catégorie d'endgame d'un plateau (un roi seul contre peu de matériel).
  /// Symétrique : peu importe la couleur du roi seul.
  static DraughtsEndgame endgameCategory(DraughtsBoard board) {
    var wK = 0;
    var wM = 0;
    var bK = 0;
    var bM = 0;
    for (final p in board.cells) {
      switch (p) {
        case Piece.whiteKing:
          wK++;
        case Piece.whiteMan:
          wM++;
        case Piece.blackKing:
          bK++;
        case Piece.blackMan:
          bM++;
        case Piece.empty:
          break;
      }
    }
    DraughtsEndgame catFor(int kings, int men) {
      final total = kings + men;
      if (kings < 1) return DraughtsEndgame.none; // le fort doit avoir ≥1 dame
      if (total <= 2) return DraughtsEndgame.fiveMove;
      if (total == 3) return DraughtsEndgame.sixteenMove;
      return DraughtsEndgame.none;
    }

    // Blancs = roi seul → on classe selon le matériel noir, et inversement.
    if (wK == 1 && wM == 0) {
      final c = catFor(bK, bM);
      if (c != DraughtsEndgame.none) return c;
    }
    if (bK == 1 && bM == 0) {
      final c = catFor(wK, wM);
      if (c != DraughtsEndgame.none) return c;
    }
    return DraughtsEndgame.none;
  }

  /// Applique [move] (supposé légal) et renvoie le nouvel état (trait inversé).
  /// Promotion : un pion ne promeut que s'il TERMINE le coup sur sa dernière
  /// rangée (pas s'il ne fait que la traverser en rafle).
  DraughtsGameState apply(DraughtsMove move) {
    final cells = board.mutableCells();
    final moving = cells[move.from];

    cells[move.from] = Piece.empty;
    for (final c in move.captured) {
      cells[c] = Piece.empty;
    }

    var placed = moving;
    if (moving.isMan && DraughtsGeometry.rowOf(move.to) == turn.promotionRow) {
      placed = Piece.kingOf(turn);
    }
    cells[move.to] = placed;
    final newBoard = DraughtsBoard(cells);

    // a/b) Compteur stérile (25 coups).
    final progress = move.isCapture || moving.isMan;
    final newSterile = progress ? 0 : sterilePlies + 1;

    // c/d) Compteur d'endgame : réinitialisé si la catégorie change.
    final newCat = endgameCategory(newBoard);
    final prevCat = endgameCategory(board);
    final newEndgame = newCat == DraughtsEndgame.none
        ? 0
        : (newCat == prevCat ? endgamePlies + 1 : 1);

    // Répétition : compte la position résultante.
    final newTurn = turn.opponent;
    final key = DraughtsFen.encode(newBoard, newTurn);
    final counts = Map<String, int>.from(positionCounts);
    counts[key] = (counts[key] ?? 0) + 1;

    return DraughtsGameState(
      board: newBoard,
      turn: newTurn,
      sterilePlies: newSterile,
      endgamePlies: newEndgame,
      positionCounts: counts,
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
      return turn == Side.white
          ? DraughtsOutcome.blackWins
          : DraughtsOutcome.whiteWins;
    }
    // a) Répétition triple.
    if ((positionCounts[positionKey] ?? 0) >= 3) {
      return DraughtsOutcome.draw;
    }
    // c/d) Endgames à nulle accélérée.
    final cat = endgameCategory(board);
    if (cat == DraughtsEndgame.sixteenMove &&
        endgamePlies >= sixteenMovePlyLimit) {
      return DraughtsOutcome.draw;
    }
    if (cat == DraughtsEndgame.fiveMove && endgamePlies >= fiveMovePlyLimit) {
      return DraughtsOutcome.draw;
    }
    // b) 25 coups.
    if (sterilePlies >= drawPlyLimit) {
      return DraughtsOutcome.draw;
    }
    return DraughtsOutcome.ongoing;
  }

  bool get isOver => outcome() != DraughtsOutcome.ongoing;
}
