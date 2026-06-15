import 'package:arena/core/services/persistent_cache.dart';
import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/models/player_stats.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Accès aux stats joueur + listes de matchs.
///
/// `getForPlayer` lit le compteur de carrière persisté `profiles.stats`
/// (incrémenté server-side au passage à `completed`, jamais décrémenté).
/// [foldMatches] reste exposé (pur, testé) pour agréger une liste de
/// matchs déjà en main, mais n'est plus la source des stats de profil :
/// folder `matches` ramènerait les stats à zéro dès qu'un match est purgé.
class MatchStatsRepository {
  const MatchStatsRepository(this._client);

  static const _table = 'matches';

  final SupabaseClient _client;

  /// Lit le compteur de carrière persisté dans `profiles.stats`.
  ///
  /// `profiles.stats` est la source autoritaire : incrémenté server-side
  /// au passage d'un match à `completed` (trigger), JAMAIS recalculé
  /// depuis zéro ni décrémenté. Lire ici (et non plus folder la table
  /// `matches`) garantit que les stats survivent à la purge / suppression
  /// des matchs — une compétition close ou un cleanup ne remet rien à zéro.
  Future<PlayerStats> getForPlayer(String playerId) async {
    final row = await _client
        .from('profiles')
        .select('stats')
        .eq('id', playerId)
        .maybeSingle();
    final stats = (row?['stats'] as Map?)?.cast<String, dynamic>();
    if (stats == null || stats.isEmpty) return const PlayerStats.empty();
    return PlayerStats.fromJson(stats);
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
  (ref, playerId) async {
    final cache = await ref.watch(persistentCacheProvider.future);
    // Offline-safe : renvoie les dernieres stats connues (ou un zero-state
    // coherent) au lieu d'une erreur reseau quand l'app est hors-ligne.
    return cache.fetchObjectOrCache<PlayerStats>(
      namespace: 'player_stats.$playerId',
      fetch: () => ref.watch(matchStatsRepositoryProvider).getForPlayer(playerId),
      fromJson: PlayerStats.fromJson,
      toJson: (s) => s.toJson(),
      offlineFallback: const PlayerStats.empty(),
    );
  },
);

final playerRecentMatchesProvider =
    FutureProvider.family.autoDispose<List<ArenaMatch>, String>(
  (ref, playerId) async {
    final cache = await ref.watch(persistentCacheProvider.future);
    return cache.fetchListOrCache<ArenaMatch>(
      namespace: 'recent_matches.$playerId',
      fetch: () => ref.watch(matchStatsRepositoryProvider).recentMatches(playerId),
      fromJson: ArenaMatch.fromJson,
      toJson: (m) => m.toJson(),
    );
  },
);

/// Variante 10-rows utilisée par le profil public (Phase 13). On garde
/// la version 5-rows pour l'onglet profil perso afin de ne pas allonger
/// son scroll initial.
final playerRecent10MatchesProvider =
    FutureProvider.family.autoDispose<List<ArenaMatch>, String>(
  (ref, playerId) async {
    final cache = await ref.watch(persistentCacheProvider.future);
    // Offline-safe : la carte "matchs recents" du profil public reste
    // figee sur les derniers matchs connus au lieu d'une erreur reseau.
    return cache.fetchListOrCache<ArenaMatch>(
      namespace: 'recent_matches_10.$playerId',
      fetch: () => ref
          .watch(matchStatsRepositoryProvider)
          .recentMatches(playerId, limit: 10),
      fromJson: ArenaMatch.fromJson,
      toJson: (m) => m.toJson(),
    );
  },
);

/// Powers the full match-history page (#14) — every status, not just
/// `completed`, so the "En cours" filter has data to render.
final playerMatchHistoryProvider =
    FutureProvider.family.autoDispose<List<ArenaMatch>, String>(
  (ref, playerId) =>
      ref.watch(matchStatsRepositoryProvider).allMatches(playerId),
);
