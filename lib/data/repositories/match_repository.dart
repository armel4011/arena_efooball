import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// CRUD + Realtime over the `matches` table, plus a thin write-through to
/// `match_events` for the collaborative score validation flow (PHASE 5).
class MatchRepository {
  const MatchRepository(this._client);

  static const _table = 'matches';
  static const _eventsTable = 'match_events';

  final SupabaseClient _client;

  // ─── Reads ─────────────────────────────────────────────────────────────

  /// All matches of a competition, sorted by round then match_number.
  Future<List<ArenaMatch>> listForCompetition(String competitionId) async {
    final rows = await _client
        .from(_table)
        .select()
        .eq('competition_id', competitionId)
        .order('round', ascending: true)
        .order('match_number', ascending: true);
    return [
      for (final row in rows as List<dynamic>)
        ArenaMatch.fromJson(row as Map<String, dynamic>),
    ];
  }

  /// Realtime stream of every match in a competition. Sorting is done
  /// client-side because Supabase `.stream()` only accepts a single
  /// `.order()` clause (we want round + match_number).
  Stream<List<ArenaMatch>> watchForCompetition(String competitionId) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('competition_id', competitionId)
        .map(
          (rows) => [
            for (final row in rows) ArenaMatch.fromJson(row),
          ]..sort(_byRoundThenMatchNumber),
        );
  }

  static int _byRoundThenMatchNumber(ArenaMatch a, ArenaMatch b) {
    final byRound = (a.round ?? 0).compareTo(b.round ?? 0);
    if (byRound != 0) return byRound;
    return (a.matchNumber ?? 0).compareTo(b.matchNumber ?? 0);
  }

  /// Realtime stream of a single match. Emits `null` if the row doesn't
  /// exist (yet) — typically when the bracket admin hasn't created it.
  Stream<ArenaMatch?> watchById(String matchId) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('id', matchId)
        .map((rows) => rows.isEmpty ? null : ArenaMatch.fromJson(rows.first));
  }

  /// Realtime stream of `score_submitted` events for a match. Used by
  /// the score-validation step to detect when both players have posted.
  ///
  /// Each row is the raw `match_events` payload — the UI / a follow-up
  /// `submission` model can adapt as needed.
  Stream<List<Map<String, dynamic>>> watchScoreSubmissions(String matchId) {
    return _client
        .from(_eventsTable)
        .stream(primaryKey: ['id'])
        .eq('match_id', matchId)
        .order('created_at')
        .map(
          (rows) => [
            for (final row in rows)
              if (row['type'] == 'score_submitted') row,
          ],
        );
  }

  // ─── Writes ────────────────────────────────────────────────────────────

  /// HOME shares the eFootball room code: stamps `room_code`,
  /// claims the home seat, and flips the match to `ready`.
  Future<void> setRoomCode({
    required String matchId,
    required String hostProfileId,
    required String code,
  }) async {
    await _client.from(_table).update({
      'room_code': code.trim().toUpperCase(),
      'home_player_id': hostProfileId,
      'status': 'ready',
    }).eq('id', matchId);
  }

  /// Either player marks the match as actually started — flips to
  /// `in_progress` and stamps `started_at`.
  Future<void> markInProgress(String matchId) async {
    await _client.from(_table).update({
      'status': 'in_progress',
      'started_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', matchId);
  }

  /// Records a player's score submission as a `match_events` row.
  ///
  /// Score concordance is detected by reading the events stream
  /// (cf. [watchScoreSubmissions]) — the first writer doesn't get to
  /// silently overwrite the second's view. A successful matching pair
  /// is then committed via [commitScore].
  Future<void> submitScore({
    required String matchId,
    required String byProfileId,
    required int scoreP1,
    required int scoreP2,
  }) async {
    await _client.from(_eventsTable).insert({
      'match_id': matchId,
      'type': 'score_submitted',
      'created_by': byProfileId,
      'payload': {'score1': scoreP1, 'score2': scoreP2},
    });
  }

  /// Two concordant submissions → commit the result on the `matches`
  /// row: scores, winner, status. [winnerId] may be null on a draw —
  /// the caller decides which side wins (or it's a tie in round-robin).
  Future<void> commitScore({
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

  /// Two players posted disagreeing scores → flip to `disputed`. The
  /// admin / arbitration bot (PHASE 12.5) will resolve from there.
  Future<void> flagDisputed(String matchId) async {
    await _client.from(_table).update({'status': 'disputed'}).eq('id', matchId);
  }
}

final matchRepositoryProvider = Provider<MatchRepository>((ref) {
  return MatchRepository(ref.watch(supabaseClientProvider));
});

/// All matches of a competition, keyed by competition id.
///
/// Backed by [MatchRepository.listForCompetition] (one-shot) rather than
/// [MatchRepository.watchForCompetition]. We tried streaming the bracket
/// realtime in V1.0 but with `matchByIdProvider` + `matchScoreSubmissionsProvider`
/// already running on the open match room, having a third Realtime stream
/// on the bracket pushed the emulator into ANR territory and triggered
/// "Reading from a closed socket" exceptions on dispose. Pull-to-refresh
/// is enough for the bracket — the rare admin/live dashboard that *does*
/// need a streamed bracket can use `watchForCompetition` directly.
final competitionMatchesProvider =
    FutureProvider.family<List<ArenaMatch>, String>((ref, competitionId) {
  return ref.watch(matchRepositoryProvider).listForCompetition(competitionId);
});

/// Realtime stream of a single match by id.
final matchByIdProvider =
    StreamProvider.family<ArenaMatch?, String>((ref, matchId) {
  return ref.watch(matchRepositoryProvider).watchById(matchId);
});

/// Realtime stream of score-submission events for a match.
final matchScoreSubmissionsProvider = StreamProvider.family<
    List<Map<String, dynamic>>, String>((ref, matchId) {
  return ref.watch(matchRepositoryProvider).watchScoreSubmissions(matchId);
});
