// =============================================================================
// ARENA — Modèle d'une ligne `draughts_games` (état serveur d'une partie).
// =============================================================================
// Modèle plat (pas freezed : peu de champs, pas de codegen). Convertit vers
// l'état moteur via [toState] (le board_fen est rejoué par le moteur Dart).
// =============================================================================

import 'package:arena/features_user/draughts/engine/draughts_engine.dart';

class DraughtsGameRow {
  const DraughtsGameRow({
    required this.id,
    required this.matchId,
    required this.gameNumber,
    required this.whiteId,
    required this.blackId,
    required this.currentTurn,
    required this.boardFen,
    required this.ply,
    required this.sterilePlies,
    required this.status,
    required this.whiteClockMs,
    required this.blackClockMs,
    required this.lastMoveAt,
  });

  factory DraughtsGameRow.fromMap(Map<String, dynamic> m) {
    return DraughtsGameRow(
      id: m['id'] as String,
      matchId: m['match_id'] as String,
      gameNumber: (m['game_number'] as num).toInt(),
      whiteId: m['white_id'] as String,
      blackId: m['black_id'] as String,
      currentTurn: m['current_turn'] as String,
      boardFen: m['board_fen'] as String,
      ply: (m['ply'] as num).toInt(),
      sterilePlies: (m['sterile_plies'] as num).toInt(),
      status: m['status'] as String,
      whiteClockMs: (m['white_clock_ms'] as num?)?.toInt(),
      blackClockMs: (m['black_clock_ms'] as num?)?.toInt(),
      lastMoveAt: DateTime.parse(m['last_move_at'] as String),
    );
  }

  final String id;
  final String matchId;
  final int gameNumber;
  final String whiteId;
  final String blackId;
  final String currentTurn; // 'white' | 'black'
  final String boardFen;
  final int ply;
  final int sterilePlies;
  final String status; // active | white_won | black_won | draw | aborted
  final int? whiteClockMs;
  final int? blackClockMs;
  final DateTime lastMoveAt;

  bool get isActive => status == 'active';
  Side get turn => currentTurn == 'white' ? Side.white : Side.black;

  /// Camp du joueur `uid`, ou null s'il n'est pas un des deux joueurs.
  Side? colorOf(String? uid) {
    if (uid == whiteId) return Side.white;
    if (uid == blackId) return Side.black;
    return null;
  }

  DraughtsGameState toState() =>
      DraughtsGameState.fromFen(boardFen, sterilePlies: sterilePlies);
}
