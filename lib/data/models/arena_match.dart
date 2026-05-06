import 'package:arena/data/models/match_status.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'arena_match.freezed.dart';
part 'arena_match.g.dart';

/// Mirror of the `matches` table — minimal subset used by the bracket /
/// match-room UI in V1.0.
///
/// Player display names are not joined here (PHASE 4.E or PHASE 5 will
/// hydrate them via a separate `profiles` lookup keyed by id). Streaming
/// fields, anti-cheat fields and admin metadata are left out — we only
/// keep what the bracket and (future) match-room actually read.
///
/// Class is named `ArenaMatch` to avoid clashing with the Dart core
/// `Match` regex type.
@Freezed(fromJson: true, toJson: true)
sealed class ArenaMatch with _$ArenaMatch {
  const factory ArenaMatch({
    required String id,
    required String competitionId,
    String? phaseId,
    String? groupId,
    int? round,
    int? matchNumber,
    String? player1Id,
    String? player2Id,
    int? score1,
    int? score2,
    String? winnerId,
    @MatchStatusConverter()
    @Default(MatchStatus.pending)
    MatchStatus status,
    String? homePlayerId,
    String? roomCode,
    String? nextMatchId,
    DateTime? scheduledAt,
    DateTime? startedAt,
    DateTime? finishedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _ArenaMatch;

  const ArenaMatch._();

  factory ArenaMatch.fromJson(Map<String, dynamic> json) =>
      _$ArenaMatchFromJson(json);

  /// `true` when both players are slotted in (vs. waiting for a previous
  /// round's winner to cascade in).
  bool get hasBothPlayers => player1Id != null && player2Id != null;

  /// `true` when the match has produced a winner.
  bool get hasResult => status.isCompleted && winnerId != null;
}
