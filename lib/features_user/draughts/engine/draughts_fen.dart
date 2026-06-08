// =============================================================================
// ARENA — Moteur de dames : sérialisation FEN-like (PDN).
// =============================================================================
// Format : "<trait>:W<pièces blanches>:B<pièces noires>"
//   - <trait> = 'W' ou 'B' (camp au trait)
//   - chaque pièce = son numéro de case (1-50), préfixé 'K' pour une dame.
// Exemple (départ, blancs au trait) :
//   "W:W31,32,...,50:B1,2,...,20"
//
// Ce format sert au stockage DB (colonne board_fen) et au calcul du hash
// d'état parent (anti-rejeu côté serveur). La sortie est CANONIQUE (cases
// triées) pour que client Dart et serveur TS produisent la même chaîne.
// =============================================================================

import 'package:arena/features_user/draughts/engine/draughts_board.dart';
import 'package:arena/features_user/draughts/engine/draughts_geometry.dart';
import 'package:arena/features_user/draughts/engine/draughts_piece.dart';

class DraughtsFen {
  DraughtsFen._();

  static String encode(DraughtsBoard board, Side turn) {
    final whites = <String>[];
    final blacks = <String>[];
    for (var i = 0; i < DraughtsGeometry.squares; i++) {
      final p = board.pieceAt(i);
      if (p.isEmpty) continue;
      final sq = DraughtsGeometry.squareNumber(i);
      final token = p.isKing ? 'K$sq' : '$sq';
      if (p.isWhite) {
        whites.add(token);
      } else {
        blacks.add(token);
      }
    }
    final t = turn == Side.white ? 'W' : 'B';
    return '$t:W${whites.join(",")}:B${blacks.join(",")}';
  }

  /// Parse une FEN. Lève [FormatException] si malformée.
  static ({DraughtsBoard board, Side turn}) decode(String fen) {
    final parts = fen.split(':');
    if (parts.length != 3) {
      throw FormatException('FEN invalide (3 segments attendus): $fen');
    }
    final turn = switch (parts[0].trim().toUpperCase()) {
      'W' => Side.white,
      'B' => Side.black,
      _ => throw FormatException('Trait invalide: ${parts[0]}'),
    };

    final cells = List<Piece>.filled(DraughtsGeometry.squares, Piece.empty);

    void parseSegment(String seg, Side side) {
      final prefix = side == Side.white ? 'W' : 'B';
      if (!seg.startsWith(prefix)) {
        throw FormatException('Segment "$seg" doit commencer par $prefix');
      }
      final body = seg.substring(1).trim();
      if (body.isEmpty) return;
      for (final raw in body.split(',')) {
        final token = raw.trim();
        if (token.isEmpty) continue;
        final isKing = token.startsWith('K');
        final numStr = isKing ? token.substring(1) : token;
        final sq = int.tryParse(numStr);
        if (sq == null || sq < 1 || sq > DraughtsGeometry.squares) {
          throw FormatException('Case invalide: $token');
        }
        final idx = DraughtsGeometry.indexFromSquare(sq);
        cells[idx] =
            isKing ? Piece.kingOf(side) : Piece.manOf(side);
      }
    }

    parseSegment(parts[1].trim(), Side.white);
    parseSegment(parts[2].trim(), Side.black);

    return (board: DraughtsBoard(cells), turn: turn);
  }
}
