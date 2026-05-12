import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/models/match_status.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Admin-side reads + writes over `matches`.
///
/// User-facing flows (room code, score submission via `match_events`,
/// forfeit) live in [MatchRepository]. The admin path is different:
/// the admin commits a verdict directly on the row, then the trigger
/// `cascade_match_winner` propagates the winner into the next bracket
/// node.
class AdminMatchesRepository {
  const AdminMatchesRepository(this._client);

  static const _table = 'matches';

  final SupabaseClient _client;

  /// Realtime stream of every match across the platform.
  ///
  /// Filtering by [status] / [competitionId] runs client-side because
  /// `.stream()` only takes a single `.eq()`. V1.0 volumes are small
  /// enough that pulling all matches is fine; we'll switch to a paged
  /// fetch when it stops being.
  Stream<List<ArenaMatch>> watchAll({
    MatchStatus? status,
    String? competitionId,
  }) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) {
          final list = [for (final row in rows) ArenaMatch.fromJson(row)];
          return list.where((m) {
            if (status != null && m.status != status) return false;
            if (competitionId != null && m.competitionId != competitionId) {
              return false;
            }
            return true;
          }).toList(growable: false);
        });
  }

  /// Admin verdict on a match — stamps scores + winner + completed,
  /// regardless of whether players had agreed. `cascade_match_winner`
  /// in `supabase/migrations/20260507100003_phase8_auto_finals_streaming.sql`
  /// then propagates the winner into the next bracket node.
  Future<void> setVerdict({
    required String matchId,
    required int scoreP1,
    required int scoreP2,
    String? winnerId,
  }) async {
    await _client.from(_table).update({
      'score1': scoreP1,
      'score2': scoreP2,
      'winner_id': winnerId,
      'status': 'completed',
      'finished_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', matchId);
  }

  /// Admin cancels a match without picking a winner. Status → cancelled,
  /// scores/winner cleared, scheduled_at preserved. Used for cases like
  /// "both players no-show" or "match config was wrong, redo it".
  Future<void> cancel(String matchId) async {
    await _client.from(_table).update({
      'status': 'cancelled',
      'finished_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', matchId);
  }

  /// Admin manually flags an in-progress match for streaming. Auto
  /// finals get this flag via the trigger
  /// `auto_publish_final_match`, but the master prompt also wants the
  /// admin to be able to flip lesser matches.
  Future<void> setStreamingEnabled({
    required String matchId,
    required bool enabled,
    required String adminId,
  }) async {
    await _client.from(_table).update({
      'is_streamed': enabled,
      if (enabled) ...{
        'streaming_activation_type': 'manual_admin',
        'streaming_activated_by_admin_id': adminId,
        'streaming_activated_at': DateTime.now().toUtc().toIso8601String(),
      } else ...{
        'streaming_activation_type': null,
        'streaming_activated_by_admin_id': null,
        'streaming_activated_at': null,
      },
    }).eq('id', matchId);
  }

  /// Reschedules a match — admin-only path used from the bracket
  /// management page when a slot needs to slip.
  Future<void> reschedule({
    required String matchId,
    required DateTime scheduledAt,
  }) async {
    await _client.from(_table).update({
      'scheduled_at': scheduledAt.toUtc().toIso8601String(),
      'status': 'scheduled',
    }).eq('id', matchId);
  }
}

final adminMatchesRepositoryProvider =
    Provider<AdminMatchesRepository>((ref) {
  return AdminMatchesRepository(ref.watch(supabaseClientProvider));
});

class AdminMatchesFilter {
  const AdminMatchesFilter({this.status, this.competitionId});
  final MatchStatus? status;
  final String? competitionId;

  @override
  bool operator ==(Object other) =>
      other is AdminMatchesFilter &&
      other.status == status &&
      other.competitionId == competitionId;

  @override
  int get hashCode => Object.hash(status, competitionId);
}

final adminMatchesProvider =
    StreamProvider.family<List<ArenaMatch>, AdminMatchesFilter>((ref, filter) {
  return ref
      .watch(adminMatchesRepositoryProvider)
      .watchAll(status: filter.status, competitionId: filter.competitionId);
});
