import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/models/player_stats.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads completed matches for a player and folds them into a
/// [PlayerStats] summary (PHASE 9.1).
///
/// Depuis Phase 12.5, `profiles.stats jsonb` est aussi recalculé
/// server-side par la fonction `recalculate_player_stats` (trigger
/// AFTER UPDATE matches.status='completed'). Ce repository garde le
/// fold client pour les écrans qui ont déjà la liste de matches en main
/// (évite un round-trip) ; pour les leaderboards / classements,
/// lire directement `profiles.stats`.
class MatchStatsRepository {
  const MatchStatsRepository(this._client);

  static const _table = 'matches';

  final SupabaseClient _client;

  /// Aggregates W/L/D + goals scored/conceded for [playerId] across
  /// every `matches.status = 'completed'` row they are seated in.
  ///
  /// Cap à 500 matches pour borner le travail de serialization (power
  /// users 10k+ matches). Quand l'agrégat persistant `profiles.stats`
  /// devient autoritaire, ce repo passe en pure read sur stats — d'ici
  /// là on plafonne.
  Future<PlayerStats> getForPlayer(String playerId, {int limit = 500}) async {
    final rows = await _client
        .from(_table)
        .select()
        .or('player1_id.eq.$playerId,player2_id.eq.$playerId')
        .eq('status', 'completed')
        .order('finished_at', ascending: false)
        .limit(limit);

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

/// Variante 10-rows utilisée par le profil public (Phase 13). On garde
/// la version 5-rows pour l'onglet profil perso afin de ne pas allonger
/// son scroll initial.
final playerRecent10MatchesProvider =
    FutureProvider.family.autoDispose<List<ArenaMatch>, String>(
  (ref, playerId) =>
      ref.watch(matchStatsRepositoryProvider).recentMatches(playerId, limit: 10),
);

/// Powers the full match-history page (#14) — every status, not just
/// `completed`, so the "En cours" filter has data to render.
final playerMatchHistoryProvider =
    FutureProvider.family.autoDispose<List<ArenaMatch>, String>(
  (ref, playerId) =>
      ref.watch(matchStatsRepositoryProvider).allMatches(playerId),
);
