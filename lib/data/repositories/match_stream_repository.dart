import 'package:arena/data/models/match_stream.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// CRUD over `public.streams`. Used by:
///   * the auto-recording flow (PHASE 8.3) — open a session at match
///     start, flip ended at match end, attach the Storage URL after the
///     upload completes,
///   * the manual upload flow (PHASE 8.3) — same shape, just no live
///     recording phase,
///   * the Agora live-streaming flow (PHASE 8.7) — admins flip
///     `is_public = true` to publish.
class MatchStreamRepository {
  const MatchStreamRepository(this._client);

  static const _table = 'streams';

  final SupabaseClient _client;

  /// Opens a new recording session for [matchId] owned by [playerId].
  ///
  /// `is_public` defaults to false (private anti-cheat); the admin
  /// console flips it later on for live streaming. The DB stamps
  /// `started_at` from `now()`.
  Future<MatchStream> openSession({
    required String matchId,
    required String playerId,
  }) async {
    final inserted = await _client
        .from(_table)
        .insert({
          'match_id': matchId,
          'player_id': playerId,
          'is_public': false,
          'is_active': true,
        })
        .select()
        .single();
    return MatchStream.fromJson(inserted);
  }

  /// Closes a session: flips `is_active = false` and stamps
  /// `ended_at = now()`. Does not touch the url field — call
  /// [attachUrl] once the upload completes (often a few seconds later).
  Future<void> markEnded(String streamId) async {
    await _client.from(_table).update({
      'is_active': false,
      'ended_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', streamId);
  }

  /// Attaches the final Storage URL (or Agora channel name) to a session.
  Future<void> attachUrl(String streamId, String url) async {
    await _client.from(_table).update({'url': url}).eq('id', streamId);
  }

  /// Lists streams owned by [playerId] (most recent first). Used by the
  /// upcoming player profile / dispute history screen.
  Future<List<MatchStream>> listForPlayer(String playerId, {int limit = 20}) async {
    final rows = await _client
        .from(_table)
        .select()
        .eq('player_id', playerId)
        .order('started_at', ascending: false)
        .limit(limit);
    return [for (final r in rows) MatchStream.fromJson(r)];
  }

  /// Realtime stream of all stream rows tied to a match — useful so the
  /// match-room can show "the opponent is recording" indicators.
  Stream<List<MatchStream>> watchByMatch(String matchId) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('match_id', matchId)
        .map(
          (rows) => [for (final r in rows) MatchStream.fromJson(r)],
        );
  }

  /// Admin-only: flips `is_public` on a stream row. Behind the scenes
  /// the `streams_admin_all` RLS rejects this update for non-admins,
  /// so this method silently no-ops if a player calls it.
  ///
  /// PHASE 8.7 — admin marks a HOME's recording row as public to
  /// open the Agora channel for that match. Toggling it back to false
  /// hides the live stream from [watchActivePublic] without ending
  /// the underlying recording session.
  Future<void> setStreamingPublic({
    required String streamId,
    required bool isPublic,
  }) async {
    await _client
        .from(_table)
        .update({'is_public': isPublic})
        .eq('id', streamId);
  }

  /// Realtime feed of every active public stream — drives
  /// `LiveStreamsPage`. Streams disappear from the list as soon as
  /// the admin flips `is_public = false` or the broadcaster ends
  /// (`is_active = false`).
  Stream<List<MatchStream>> watchActivePublic() {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('is_public', true)
        .map(
          (rows) => [
            for (final r in rows)
              if (r['is_active'] == true) MatchStream.fromJson(r),
          ],
        );
  }
}

final matchStreamRepositoryProvider = Provider<MatchStreamRepository>((ref) {
  return MatchStreamRepository(ref.watch(supabaseClientProvider));
});

final matchStreamsByMatchProvider =
    StreamProvider.family<List<MatchStream>, String>((ref, matchId) {
  return ref.watch(matchStreamRepositoryProvider).watchByMatch(matchId);
});

/// Drives `LiveStreamsPage` — every active public stream, realtime.
final activePublicStreamsProvider =
    StreamProvider<List<MatchStream>>((ref) {
  return ref.watch(matchStreamRepositoryProvider).watchActivePublic();
});
