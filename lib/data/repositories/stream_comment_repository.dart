import 'dart:async';

import 'package:arena/data/models/stream_comment.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads + writes on `public.stream_comments` (chat publique des
/// spectateurs d'un live).
///
/// La lecture passe par un `Stream<List<StreamComment>>` Riverpod
/// (cf. [streamCommentsProvider]) qui combine un fetch initial des
/// 100 derniers messages avec une subscription realtime aux INSERT.
/// L'écriture passe par [post], qui insère directement (la RLS de la
/// table vérifie que l'auteur est l'user courant et qu'un stream
/// public actif existe sur ce match).
class StreamCommentRepository {
  const StreamCommentRepository(this._client);

  static const _table = 'stream_comments';
  static const _maxHistory = 100;

  final SupabaseClient _client;

  Future<List<StreamComment>> fetchRecent(String matchId) async {
    final rows = await _client
        .from(_table)
        .select()
        .eq('match_id', matchId)
        .order('created_at')
        .limit(_maxHistory);
    return [
      for (final row in rows as List<dynamic>)
        StreamComment.fromJson(row as Map<String, dynamic>),
    ];
  }

  /// Insert un commentaire. Lève si l'utilisateur n'a pas de session
  /// ou si le check RLS échoue (pas de stream actif sur ce match).
  Future<void> post({required String matchId, required String content}) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('Pas de session active — login requis pour commenter.');
    }
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;
    await _client.from(_table).insert({
      'match_id': matchId,
      'author_id': user.id,
      'content': trimmed,
    });
  }
}

final streamCommentRepositoryProvider = Provider<StreamCommentRepository>((
  ref,
) {
  return StreamCommentRepository(ref.watch(supabaseClientProvider));
});

/// Stream live des commentaires d'un match donné. Combine un fetch
/// initial (les 100 derniers, dans l'ordre chronologique) avec une
/// subscription realtime aux INSERT. Auto-dispose quand plus aucun
/// listener n'écoute (= sortie de WatchStreamPage).
final streamCommentsProvider = StreamProvider.family
    .autoDispose<List<StreamComment>, String>((ref, matchId) async* {
  final repo = ref.watch(streamCommentRepositoryProvider);
  final client = ref.watch(supabaseClientProvider);

  // 1. Fetch initial.
  var buffer = await repo.fetchRecent(matchId);
  yield List.unmodifiable(buffer);

  // 2. Subscribe aux INSERT sur ce match_id. Le channel name est
  // unique par matchId pour ne pas mélanger les flux quand on
  // change de live.
  final channel = client
      .channel('stream_comments_$matchId')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'stream_comments',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'match_id',
          value: matchId,
        ),
        callback: (payload) {
          try {
            final row = payload.newRecord;
            buffer = List.unmodifiable([
              ...buffer,
              StreamComment.fromJson(row),
            ]);
          } catch (_) {
            // payload mal formé — on ignore plutôt que crasher
            // le stream listener et perdre les messages suivants.
          }
        },
      )
      .subscribe();

  ref.onDispose(() {
    client.removeChannel(channel);
  });

  // 3. Re-emit la buffer à chaque modification. On suit le
  // pattern Riverpod : un controller interne re-yield à chaque
  // tick triggered par le callback realtime.
  final controller = StreamController<List<StreamComment>>();
  ref.onDispose(controller.close);

  final timer = Timer.periodic(const Duration(milliseconds: 400), (_) {
    if (!controller.isClosed) {
      controller.add(buffer);
    }
  });
  ref.onDispose(timer.cancel);

  yield* controller.stream;
});
