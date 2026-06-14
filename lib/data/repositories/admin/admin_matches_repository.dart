import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/models/match_status.dart';
import 'package:arena/data/repositories/match_repository.dart' show MatchRepository;
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:flutter/foundation.dart';
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
  static const _streamsTable = 'streams';

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

  /// Orchestre l'activation/désactivation MANUELLE de la diffusion live
  /// d'un match depuis l'UI admin.
  ///
  /// [setStreamingEnabled] ne flippe que le flag `matches.is_streamed` ;
  /// or pour qu'un broadcast Agora soit visible côté grand public il faut
  /// AUSSI une row `streams` du joueur HOME avec `is_public = true` ET
  /// `is_active = true`. En activation manuelle (avant même que le joueur
  /// ait lancé sa session), cette row peut ne pas exister — on l'upsert.
  ///
  /// ACTIVER :
  ///   1. `is_streamed = true` (+ métadonnées manual_admin).
  ///   2. Si une row `streams` ACTIVE existe déjà pour (match, home) →
  ///      `is_public = true` ; sinon INSERT une nouvelle row publique
  ///      active. (Le check par match_id + player_id + is_active évite
  ///      les doublons avec la row créée par `auto_publish_late_stream`.)
  ///
  /// DÉSACTIVER :
  ///   1. `is_streamed = false` (+ métadonnées remises à null).
  ///   2. Toutes les row(s) `streams` publiques du match → `is_public =
  ///      false` (sans toucher `is_active` : on masque le live sans
  ///      clôturer l'enregistrement sous-jacent).
  ///
  /// La row `streams` est manipulée directement ici (et non via
  /// `MatchStreamRepository`) car l'orchestration appartient au flux
  /// admin du match. L'audit (`stream_enabled` / `stream_disabled`) est
  /// écrit par l'appelant UI, qui détient l'adminId de session.
  Future<void> setManualStreaming({
    required String matchId,
    required String homePlayerId,
    required bool enabled,
    required String adminId,
  }) async {
    await setStreamingEnabled(
      matchId: matchId,
      enabled: enabled,
      adminId: adminId,
    );

    if (enabled) {
      // Cherche une row active existante pour ce match + ce home player.
      final existing = await _client
          .from(_streamsTable)
          .select('id')
          .eq('match_id', matchId)
          .eq('player_id', homePlayerId)
          .eq('is_active', true)
          .limit(1)
          .maybeSingle();

      if (existing != null) {
        await _client
            .from(_streamsTable)
            .update({'is_public': true})
            .eq('id', existing['id'] as String);
      } else {
        await _client.from(_streamsTable).insert({
          'match_id': matchId,
          'player_id': homePlayerId,
          'is_public': true,
          'is_active': true,
        });
      }
    } else {
      // Masque tous les flux publics du match (broadcaster + éventuels).
      await _client
          .from(_streamsTable)
          .update({'is_public': false})
          .eq('match_id', matchId)
          .eq('is_public', true);
    }
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

@immutable
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
    StreamProvider.family.autoDispose<List<ArenaMatch>, AdminMatchesFilter>((ref, filter) {
  return ref
      .watch(adminMatchesRepositoryProvider)
      .watchAll(status: filter.status, competitionId: filter.competitionId);
});
