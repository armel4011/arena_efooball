import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/models/player_stats.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads completed matches for a player and folds them into a
/// [PlayerStats] summary (PHASE 9.1).
///
/// The job belongs server-side eventually (the PHASE 12.5 Edge Function
/// `recalculate_player_stats` will write to `profiles.stats jsonb` after
/// every match closes), but until then we recompute client-side on each
/// profile open. Match volume per V1.0 player stays low enough that the
/// extra round-trip is fine.
class MatchStatsRepository {
  const MatchStatsRepository(this._client);

  static const _table = 'matches';

  final SupabaseClient _client;

  /// Aggregates W/L/D + goals scored/conceded for [playerId] across
  /// every `matches.status = 'completed'` row they are seated in.
  Future<PlayerStats> getForPlayer(String playerId) async {
    final rows = await _client
        .from(_table)
        .select()
        .or('player1_id.eq.$playerId,player2_id.eq.$playerId')
        .eq('status', 'completed');

    final matches = [for (final r in rows) ArenaMatch.fromJson(r)];
    return foldMatches(playerId, matches);
  }

  /// Returns the [limit] most recent completed matches for [playerId],
  /// newest first. Drives the "Récents" list on `PlayerProfilePage`.
  Future<List<ArenaMatch>> recentMatches(
    String playerId, {
    int limit = 5,
  }) async {
    final rows = await _client
        .from(_table)
        .select()
        .or('player1_id.eq.$playerId,player2_id.eq.$playerId')
        .eq('status', 'completed')
        .order('finished_at', ascending: false)
        .limit(limit);
    return [for (final r in rows) ArenaMatch.fromJson(r)];
  }

  /// Returns every match the player has been seated in (any status), newest
  /// first. Powers the full `MatchHistoryPage` (#14) with its filter chips.
  Future<List<ArenaMatch>> allMatches(
    String playerId, {
    int limit = 100,
  }) async {
    final rows = await _client
        .from(_table)
        .select()
        .or('player1_id.eq.$playerId,player2_id.eq.$playerId')
        .order('scheduled_at', ascending: false)
        .limit(limit);
    return [for (final r in rows) ArenaMatch.fromJson(r)];
  }

  /// Pure aggregation kept on the class so tests can hit it without a
  /// SupabaseClient. A draw is encoded as `winner_id = null` on a
  /// completed match (penalty shootouts always set a winner, so this
  /// only fires on legacy / forfeit-cancelled rows).
  static PlayerStats foldMatches(
    String playerId,
    Iterable<ArenaMatch> matches,
  ) {
    var wins = 0;
    var losses = 0;
    var draws = 0;
    var goalsScored = 0;
    var goalsConceded = 0;

    for (final m in matches) {
      final isP1 = m.player1Id == playerId;
      final isP2 = m.player2Id == playerId;
      if (!isP1 && !isP2) continue;

      final myScore = isP1 ? m.score1 : m.score2;
      final theirScore = isP1 ? m.score2 : m.score1;
      goalsScored += myScore ?? 0;
      goalsConceded += theirScore ?? 0;

      if (m.winnerId == null) {
        draws++;
      } else if (m.winnerId == playerId) {
        wins++;
      } else {
        losses++;
      }
    }

    return PlayerStats(
      wins: wins,
      losses: losses,
      draws: draws,
      goalsScored: goalsScored,
      goalsConceded: goalsConceded,
    );
  }
}

final matchStatsRepositoryProvider = Provider<MatchStatsRepository>((ref) {
  return MatchStatsRepository(ref.watch(supabaseClientProvider));
});

/// Drives the stats card on the profile page. AutoDispose so the data
/// refreshes when the user comes back from elsewhere in the app.
final playerStatsProvider =
    FutureProvider.family.autoDispose<PlayerStats, String>(
  (ref, playerId) =>
      ref.watch(matchStatsRepositoryProvider).getForPlayer(playerId),
);

final playerRecentMatchesProvider =
    FutureProvider.family.autoDispose<List<ArenaMatch>, String>(
  (ref, playerId) =>
      ref.watch(matchStatsRepositoryProvider).recentMatches(playerId),
);

/// Powers the full match-history page (#14) — every status, not just
/// `completed`, so the "En cours" filter has data to render.
final playerMatchHistoryProvider =
    FutureProvider.family.autoDispose<List<ArenaMatch>, String>(
  (ref, playerId) =>
      ref.watch(matchStatsRepositoryProvider).allMatches(playerId),
);
