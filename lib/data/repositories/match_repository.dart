import 'package:arena/core/services/persistent_cache.dart';
import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
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

  /// Matchs à venir / en cours pour [playerId] — alimente la home
  /// "Prochains matchs" + l'onglet DIRECT de l'inbox messages.
  ///
  /// Filtre out completed/cancelled/forfeited (matches déjà soldés).
  /// Trié par `scheduled_at asc` quand renseigné, sinon par `created_at`.
  Future<List<ArenaMatch>> listActiveForPlayer(
    String playerId, {
    int limit = 20,
  }) async {
    final rows = await _client
        .from(_table)
        .select()
        .or('player1_id.eq.$playerId,player2_id.eq.$playerId')
        .not('status', 'in', '(completed,cancelled,forfeited)')
        .order('scheduled_at', ascending: true, nullsFirst: false)
        .limit(limit);
    return [
      for (final row in rows as List<dynamic>)
        ArenaMatch.fromJson(row as Map<String, dynamic>),
    ];
  }

  /// Variante "récents" pour l'inbox : inclut les matchs terminés, triés
  /// par `finished_at desc` (récents en haut), fallback `scheduled_at`.
  Future<List<ArenaMatch>> listAnyForPlayer(
    String playerId, {
    int limit = 30,
  }) async {
    final rows = await _client
        .from(_table)
        .select()
        .or('player1_id.eq.$playerId,player2_id.eq.$playerId')
        .order('finished_at', ascending: false, nullsFirst: false)
        .order('scheduled_at', ascending: false, nullsFirst: false)
        .limit(limit);
    return [
      for (final row in rows as List<dynamic>)
        ArenaMatch.fromJson(row as Map<String, dynamic>),
    ];
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

  /// Nouveau flux : le HOME envoie son code eFootball depuis le bouton
  /// flottant rouge APRÈS avoir déjà démarré son enregistrement (le match
  /// est donc déjà `in_progress`). On n'écrit QUE `room_code` — surtout pas
  /// `status`, sinon on régresserait `in_progress → ready` et on casserait
  /// la state machine (et le recording en cours). `home_player_id` est déjà
  /// posé (seed du bracket / démarrage), donc pas réécrit ici.
  Future<void> sendRoomCode({
    required String matchId,
    required String code,
  }) async {
    await _client.from(_table).update({
      'room_code': code.trim().toUpperCase(),
    }).eq('id', matchId);
  }

  /// Records the team name a player will use for this match. Stamps the
  /// column matching the player's seat ([isPlayer1]) — the per-column
  /// intent is enforced here, not by RLS (cf. `matches_player_update`).
  /// Used for anti-cheat arbitration so the admin knows which team each
  /// player fielded.
  Future<void> setTeamName({
    required String matchId,
    required bool isPlayer1,
    required String teamName,
  }) async {
    final column = isPlayer1 ? 'player1_team_name' : 'player2_team_name';
    await _client.from(_table).update({
      column: teamName.trim(),
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
  ///
  /// When [decidedByPenalties] is `true`, [penaltyP1] and [penaltyP2]
  /// must be provided and they're stamped on the payload alongside the
  /// regulation-time score. Penalties only make sense for knockout
  /// matches — the form hides the toggle for group-stage rows.
  Future<void> submitScore({
    required String matchId,
    required String byProfileId,
    required int scoreP1,
    required int scoreP2,
    bool decidedByPenalties = false,
    int? penaltyP1,
    int? penaltyP2,
    String? proofPath,
    String? proofMimeType,
  }) async {
    final payload = <String, dynamic>{
      'score1': scoreP1,
      'score2': scoreP2,
      if (decidedByPenalties) ...{
        'via_penalties': true,
        'penalty1': penaltyP1,
        'penalty2': penaltyP2,
      },
      if (proofPath != null) 'proof_path': proofPath,
      if (proofMimeType != null) 'proof_mime': proofMimeType,
    };
    await _client.from(_eventsTable).insert({
      'match_id': matchId,
      'type': 'score_submitted',
      'created_by': byProfileId,
      'payload': payload,
    });
  }

  /// Two concordant submissions → finalize the result server-side.
  ///
  /// Delegates to the `finalize_match_score` RPC (SECURITY DEFINER): the
  /// server re-reads both `score_submitted` events, re-checks they agree,
  /// computes the winner and writes score/winner/status itself. Direct
  /// client UPDATEs of those columns are now blocked by the
  /// `guard_matches_protected_columns` trigger — passing scores from the
  /// client would be ignored anyway, so we only send the match id.
  Future<void> commitScore({required String matchId}) async {
    await _client.rpc<void>(
      'finalize_match_score',
      params: {'p_match_id': matchId},
    );
  }

  /// Two players posted disagreeing scores → open a dispute. Via the atomic
  /// `flag_score_dispute` RPC : flips the match to `disputed` AND materialises a
  /// `disputes` row (idempotent) so the litige surfaces in the admin arbitration
  /// queue. If both players later agree on a score, `finalize_match_score`
  /// auto-closes that dispute; otherwise the admin resolves it (`resolve_dispute`).
  Future<void> flagDisputed(String matchId) async {
    await _client.rpc<void>(
      'flag_score_dispute',
      params: {'p_match_id': matchId},
    );
  }

  /// Declares a forfeit by the current player via the `forfeit_match` RPC
  /// (SECURITY DEFINER): the server checks the caller is one of the two
  /// players, awards the win to the opponent, flips `status` to
  /// `forfeited`, stamps `finished_at`, and logs a `forfeit` event. A
  /// player can therefore only ever forfeit on their own behalf — direct
  /// client writes of `status`/`winner_id` are blocked by the
  /// `guard_matches_protected_columns` trigger.
  ///
  /// PHASE 8.5 — triggered either by the player tapping "Arrêter
  /// (forfait)" in the overlay's long-press menu, or automatically when
  /// the 2-minute pause grace expires. [forfeitingPlayerId] / [opponentId]
  /// are kept for caller compatibility but the server derives both from
  /// the authenticated identity and the match row.
  Future<void> markForfeit({
    required String matchId,
    required String forfeitingPlayerId,
    required String opponentId,
    String? reason,
  }) async {
    await _client.rpc<void>(
      'forfeit_match',
      params: {
        'p_match_id': matchId,
        if (reason != null) 'p_reason': reason,
      },
    );
  }

  /// Generic `match_events` insert. Players may post any event whose
  /// `created_by` is themselves (RLS enforced — see migration
  /// `20260506200001_phase5_player_match_room_rls.sql`).
  Future<void> recordEvent({
    required String matchId,
    required String type,
    required String byProfileId,
    Map<String, dynamic>? payload,
  }) async {
    await _client.from(_eventsTable).insert({
      'match_id': matchId,
      'type': type,
      'created_by': byProfileId,
      'payload': payload ?? <String, dynamic>{},
    });
  }
}

final matchRepositoryProvider = Provider<MatchRepository>((ref) {
  return MatchRepository(ref.watch(supabaseClientProvider));
});

/// All matches of a competition, keyed by competition id.
///
/// **Realtime stream depuis batch 🔴 2026-05-28** : remplace l'ancien
/// FutureProvider+pull-refresh. Le risque ANR historique (3 streams
/// simultanés bracket + matchById + scoreSubmissions saturant WebSocket)
/// est mitigué par `.autoDispose` qui ferme le stream bracket des qu'on
/// quitte `bracket_view_page` pour entrer dans une `match_room_page` —
/// les 2 contextes ne sont jamais actifs en meme temps en navigation
/// normale (go_router push).
final competitionMatchesProvider = StreamProvider.family
    .autoDispose<List<ArenaMatch>, String>((ref, competitionId) async* {
  // Offline-safe : le bracket reste fige sur les derniers matchs connus
  // au lieu d'afficher une ErrorState reseau hors-ligne.
  final cache = await ref.watch(persistentCacheProvider.future);
  yield* cache.hydrate<ArenaMatch>(
    namespace: 'competition_matches.$competitionId',
    source:
        ref.watch(matchRepositoryProvider).watchForCompetition(competitionId),
    fromJson: ArenaMatch.fromJson,
    toJson: (m) => m.toJson(),
  );
});

/// Realtime stream of a single match by id. `.autoDispose` empêche le
/// stream WebSocket de rester actif pour chaque match visité. Le cache
/// disque ne garde lui que le dernier JSON connu par match (borne, ~Ko) →
/// la MatchRoom reste affichee hors-ligne au lieu d'une ErrorState.
final matchByIdProvider = StreamProvider.family
    .autoDispose<ArenaMatch?, String>((ref, matchId) async* {
  final cache = await ref.watch(persistentCacheProvider.future);
  yield* cache.hydrateSingle<ArenaMatch>(
    namespace: 'match.$matchId',
    source: ref.watch(matchRepositoryProvider).watchById(matchId),
    fromJson: ArenaMatch.fromJson,
    toJson: (m) => m.toJson(),
  );
});

/// Realtime stream of score-submission events for a match. `.autoDispose`
/// — utilisé uniquement dans le MatchRoom; rien ne le consomme après
/// la fin du match. Cache offline-safe : le flow de score reste fige sur
/// les derniers events au lieu d'une ErrorState dans la room.
final matchScoreSubmissionsProvider = StreamProvider.family
    .autoDispose<List<Map<String, dynamic>>, String>((ref, matchId) async* {
  final cache = await ref.watch(persistentCacheProvider.future);
  yield* cache.hydrate<Map<String, dynamic>>(
    namespace: 'score_submissions.$matchId',
    source: ref.watch(matchRepositoryProvider).watchScoreSubmissions(matchId),
    fromJson: (json) => json,
    toJson: (m) => m,
  );
});

/// Matchs actifs (scheduled / ready / in_progress / awaiting…) du joueur
/// courant — alimente la home "Prochains matchs".
///
/// **Cold start cache** : la liste connue est persistee → la section
/// "Prochain match" s'affiche instantanement au boot meme offline.
final myActiveMatchesProvider =
    StreamProvider.autoDispose<List<ArenaMatch>>((ref) async* {
  final me = ref.watch(currentSessionProvider)?.user.id;
  if (me == null) {
    yield const [];
    return;
  }
  final cache = await ref.watch(persistentCacheProvider.future);
  // Source = fetch one-shot wrappe en Stream (le repo n'a pas de stream
  // pour cette query — listActiveForPlayer filtre cote serveur).
  final source = Stream<List<ArenaMatch>>.fromFuture(
    ref.watch(matchRepositoryProvider).listActiveForPlayer(me),
  );
  yield* cache.hydrate<ArenaMatch>(
    namespace: 'active_matches.$me',
    source: source,
    fromJson: ArenaMatch.fromJson,
    toJson: (m) => m.toJson(),
  );
});

/// Tous les matchs du joueur courant, récents en haut. Alimente l'onglet
/// DIRECT de l'inbox messages — un thread = un match auquel je participe.
final myAllMatchesProvider =
    FutureProvider.autoDispose<List<ArenaMatch>>((ref) async {
  final me = ref.watch(currentSessionProvider)?.user.id;
  if (me == null) return const [];
  final cache = await ref.watch(persistentCacheProvider.future);
  // Offline-safe : l'onglet DIRECT de l'inbox reste fige sur les derniers
  // matchs connus au lieu d'afficher une erreur reseau hors-ligne.
  return cache.fetchListOrCache<ArenaMatch>(
    namespace: 'inbox_all_matches.$me',
    fetch: () => ref.watch(matchRepositoryProvider).listAnyForPlayer(me),
    fromJson: ArenaMatch.fromJson,
    toJson: (m) => m.toJson(),
  );
});
