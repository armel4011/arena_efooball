// =============================================================================
// ARENA — Moteur de dames : génération des coups légaux (règles FMJD 10×10).
// =============================================================================
// Règles implémentées :
//   * Pion : avance d'une case en diagonale (vers l'avant uniquement) pour un
//     déplacement simple ; CAPTURE en avant ET en arrière.
//   * Dame : déplacement et prise à longue portée sur les diagonales
//     (« dame volante »).
//   * PRISE OBLIGATOIRE : s'il existe au moins une prise, seules les prises
//     sont légales.
//   * RÈGLE DE MAJORITÉ : parmi les rafles, seules celles capturant le nombre
//     MAXIMAL de pièces sont légales.
//   * Continuation obligatoire : une rafle se poursuit tant qu'une prise est
//     possible depuis la case d'arrivée (on n'enregistre que les rafles
//     complètes).
//   * Une pièce déjà sautée reste sur le plateau jusqu'à la fin de la rafle
//     (interdiction de la sauter deux fois / de la traverser).
//   * Promotion : gérée à l'application du coup (un pion qui ne fait que
//     traverser la rangée de promotion pendant une rafle ne promeut PAS ;
//     cf. draughts_game_state.dart).
// =============================================================================

import 'package:arena/features_user/draughts/engine/draughts_board.dart';
import 'package:arena/features_user/draughts/engine/draughts_geometry.dart';
import 'package:arena/features_user/draughts/engine/draughts_move.dart';
import 'package:arena/features_user/draughts/engine/draughts_piece.dart';

class DraughtsRules {
  DraughtsRules._();

  /// Coups légaux pour [side] sur [board], règles internationales appliquées
  /// (prise obligatoire + majorité).
  static List<DraughtsMove> legalMoves(DraughtsBoard board, Side side) {
    final captures = _allCaptures(board, side);
    if (captures.isNotEmpty) {
      var max = 0;
      for (final m in captures) {
        if (m.captured.length > max) max = m.captured.length;
      }
      return captures.where((m) => m.captured.length == max).toList();
    }
    return _allSimpleMoves(board, side);
  }

  /// Reconstitue un coup (from→to + captures) à partir du diff de deux
  /// plateaux. Sert à ANIMER un coup reçu par le réseau sans en connaître le
  /// chemin exact (la rafle est alors rendue en glisse directe). Renvoie
  /// `null` si le diff ne correspond pas à un coup unique (ex. plateau
  /// réinitialisé en mort subite).
  static DraughtsMove? deriveMove(List<Piece> before, List<Piece> after) {
    final added = <int>[];
    final removed = <int>[];
    for (var i = 0; i < before.length; i++) {
      if (before[i].isEmpty && !after[i].isEmpty) added.add(i);
      if (!before[i].isEmpty && after[i].isEmpty) removed.add(i);
    }
    if (added.length != 1) return null;
    final to = added.first;
    final moverSide = after[to].side;
    if (moverSide == null) return null;
    final fromList = removed.where((i) => before[i].side == moverSide).toList();
    if (fromList.length != 1) return null;
    final fromIdx = fromList.first;
    final captured =
        removed.where((i) => before[i].side == moverSide.opponent).toList();

    if (captured.isEmpty) {
      return DraughtsMove(
        from: fromIdx,
        to: to,
        captured: const [],
        path: [fromIdx, to],
      );
    }

    // Rafle : retrouver le CHEMIN EXACT (séquence de sauts) en cherchant, parmi
    // les rafles légales de la position d'avant, celle qui part de `fromIdx`,
    // arrive sur `to` et capture exactement le même ensemble de pièces.
    final capturedSet = captured.toSet();
    for (final m in legalMoves(DraughtsBoard(before), moverSide)) {
      if (m.from == fromIdx &&
          m.to == to &&
          m.captured.length == capturedSet.length &&
          m.captured.toSet().containsAll(capturedSet)) {
        return m;
      }
    }

    // Repli (ne devrait pas arriver pour un coup légal) : glisse directe.
    return DraughtsMove(
      from: fromIdx,
      to: to,
      captured: captured,
      path: [fromIdx, to],
    );
  }

  // ───────────────────────── Déplacements simples ─────────────────────────

  static List<DraughtsMove> _allSimpleMoves(DraughtsBoard board, Side side) {
    final moves = <DraughtsMove>[];
    for (final idx in board.indicesOf(side)) {
      final piece = board.pieceAt(idx);
      if (piece.isKing) {
        _kingSimpleMoves(board, idx, moves);
      } else {
        _manSimpleMoves(board, idx, side, moves);
      }
    }
    return moves;
  }

  static void _manSimpleMoves(
    DraughtsBoard board,
    int idx,
    Side side,
    List<DraughtsMove> out,
  ) {
    final row = DraughtsGeometry.rowOf(idx);
    final col = DraughtsGeometry.colOf(idx);
    final dr = side.forward;
    for (final dc in const [-1, 1]) {
      final dest = DraughtsGeometry.indexAt(row + dr, col + dc);
      if (dest >= 0 && board.pieceAt(dest).isEmpty) {
        out.add(DraughtsMove.simple(idx, dest));
      }
    }
  }

  static void _kingSimpleMoves(
    DraughtsBoard board,
    int idx,
    List<DraughtsMove> out,
  ) {
    final row = DraughtsGeometry.rowOf(idx);
    final col = DraughtsGeometry.colOf(idx);
    for (final dir in DraughtsGeometry.diagonals) {
      var r = row + dir[0];
      var c = col + dir[1];
      var dest = DraughtsGeometry.indexAt(r, c);
      while (dest >= 0 && board.pieceAt(dest).isEmpty) {
        out.add(DraughtsMove.simple(idx, dest));
        r += dir[0];
        c += dir[1];
        dest = DraughtsGeometry.indexAt(r, c);
      }
    }
  }

  // ───────────────────────────── Prises ───────────────────────────────────

  static List<DraughtsMove> _allCaptures(DraughtsBoard board, Side side) {
    final results = <DraughtsMove>[];
    for (final idx in board.indicesOf(side)) {
      final piece = board.pieceAt(idx);
      final cells = board.mutableCells();
      final captured = <int>{};
      final path = <int>[idx];
      if (piece.isKing) {
        _searchKingCaptures(cells, idx, idx, side, captured, path, results);
      } else {
        _searchManCaptures(cells, idx, idx, side, captured, path, results);
      }
    }
    return results;
  }

  /// Recherche récursive des rafles d'un pion. [cells] est muté/restauré.
  /// [start] = case de départ initiale ; [current] = case courante.
  static void _searchManCaptures(
    List<Piece> cells,
    int start,
    int current,
    Side side,
    Set<int> captured,
    List<int> path,
    List<DraughtsMove> out,
  ) {
    final row = DraughtsGeometry.rowOf(current);
    final col = DraughtsGeometry.colOf(current);
    var extended = false;

    for (final dir in DraughtsGeometry.diagonals) {
      final midIdx = DraughtsGeometry.indexAt(row + dir[0], col + dir[1]);
      if (midIdx < 0) continue;
      final landIdx =
          DraughtsGeometry.indexAt(row + 2 * dir[0], col + 2 * dir[1]);
      if (landIdx < 0) continue;

      final midPiece = cells[midIdx];
      final canTake = midPiece.side == side.opponent &&
          !captured.contains(midIdx) &&
          cells[landIdx].isEmpty;
      if (!canTake) continue;

      // Saute : la pièce capturée reste sur le plateau (bloquante), le pion
      // se déplace de `current` vers `landIdx`.
      final moving = cells[current];
      cells[current] = Piece.empty;
      cells[landIdx] = moving;
      captured.add(midIdx);
      path.add(landIdx);

      _searchManCaptures(cells, start, landIdx, side, captured, path, out);

      // Annule.
      path.removeLast();
      captured.remove(midIdx);
      cells[landIdx] = Piece.empty;
      cells[current] = moving;
      extended = true;
    }

    if (!extended && captured.isNotEmpty) {
      out.add(
        DraughtsMove(
          from: start,
          to: current,
          captured: captured.toList(),
          path: List<int>.from(path),
        ),
      );
    }
  }

  /// Recherche récursive des rafles d'une dame (volante). [cells] muté/restauré.
  static void _searchKingCaptures(
    List<Piece> cells,
    int start,
    int current,
    Side side,
    Set<int> captured,
    List<int> path,
    List<DraughtsMove> out,
  ) {
    final row = DraughtsGeometry.rowOf(current);
    final col = DraughtsGeometry.colOf(current);
    var extended = false;

    for (final dir in DraughtsGeometry.diagonals) {
      // 1) Avance sur les cases vides jusqu'à la première pièce rencontrée.
      var r = row + dir[0];
      var c = col + dir[1];
      var scan = DraughtsGeometry.indexAt(r, c);
      while (scan >= 0 && cells[scan].isEmpty) {
        r += dir[0];
        c += dir[1];
        scan = DraughtsGeometry.indexAt(r, c);
      }
      if (scan < 0) continue; // bord atteint, rien à prendre

      // 2) Première pièce : capturable seulement si ennemie et pas déjà prise.
      final target = cells[scan];
      if (target.side != side.opponent || captured.contains(scan)) {
        continue; // pièce amie / déjà capturée → diagonale bloquée
      }
      final enemyIdx = scan;

      // 3) Cases d'arrivée : toutes les cases vides au-delà de l'ennemi.
      var lr = DraughtsGeometry.rowOf(enemyIdx) + dir[0];
      var lc = DraughtsGeometry.colOf(enemyIdx) + dir[1];
      var landIdx = DraughtsGeometry.indexAt(lr, lc);
      while (landIdx >= 0 && cells[landIdx].isEmpty) {
        final moving = cells[current];
        cells[current] = Piece.empty;
        cells[landIdx] = moving;
        captured.add(enemyIdx);
        path.add(landIdx);

        _searchKingCaptures(cells, start, landIdx, side, captured, path, out);

        path.removeLast();
        captured.remove(enemyIdx);
        cells[landIdx] = Piece.empty;
        cells[current] = moving;
        extended = true;

        lr += dir[0];
        lc += dir[1];
        landIdx = DraughtsGeometry.indexAt(lr, lc);
      }
    }

    if (!extended && captured.isNotEmpty) {
      out.add(
        DraughtsMove(
          from: start,
          to: current,
          captured: captured.toList(),
          path: List<int>.from(path),
        ),
      );
    }
  }
}
