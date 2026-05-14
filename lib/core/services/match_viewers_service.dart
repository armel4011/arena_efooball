import 'dart:async';

import 'package:arena/data/repositories/profile_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Realtime viewer-presence tracker for live Agora streams (PHASE 8.7).
///
/// Opens a Supabase Realtime channel `match-viewers-{matchId}` and
/// tracks the caller's presence. Every other subscriber to the same
/// channel receives the synced presence state, so the count is just
/// `presenceState.length`.
///
/// The DB columns `matches.current_viewers_count` /
/// `peak_viewers_count` are kept untouched here: they are the
/// admin-side projection (updated by a PHASE 12.5 Edge Function), while
/// the live count shown to a viewer comes from presence directly.
class MatchViewersService {
  MatchViewersService(this._client);

  final SupabaseClient _client;

  /// Subscribes to the viewer presence channel for [matchId] and emits
  /// the running count.
  ///
  /// Set [tracking] to `false` to read the count without registering
  /// the caller (e.g. an admin dashboard). Cancelling the returned
  /// subscription untracks and closes the channel.
  Stream<int> watch({
    required String matchId,
    bool tracking = true,
    String? viewerId,
  }) {
    final controller = StreamController<int>();
    final channel = _client.channel(
      'match-viewers-$matchId',
      opts: const RealtimeChannelConfig(self: true),
    );

    final selfKey = viewerId ??
        _client.auth.currentUser?.id ??
        'anon-${DateTime.now().microsecondsSinceEpoch}';

    channel
      ..onPresenceSync((_) {
        if (controller.isClosed) return;
        controller.add(channel.presenceState().length);
      })
      ..subscribe((status, error) async {
        if (status == RealtimeSubscribeStatus.subscribed && tracking) {
          await channel.track({
            'key': selfKey,
            'joined_at': DateTime.now().toUtc().toIso8601String(),
          });
        }
      });

    controller.onCancel = () async {
      try {
        if (tracking) await channel.untrack();
      } catch (e) {
        debugPrint('[viewers] untrack failed (channel may be closed): $e');
      }
      try {
        await channel.unsubscribe();
      } catch (e) {
        debugPrint('[viewers] unsubscribe failed: $e');
      }
      await controller.close();
    };

    return controller.stream;
  }
}

final matchViewersServiceProvider = Provider<MatchViewersService>((ref) {
  return MatchViewersService(ref.watch(supabaseClientProvider));
});

/// Live viewer count for a given match, fed by presence on
/// `match-viewers-{matchId}`. The subscriber's own presence IS
/// tracked, so a `WatchStreamPage` automatically counts itself.
final matchViewerCountProvider =
    StreamProvider.family.autoDispose<int, String>((ref, matchId) {
  return ref.watch(matchViewersServiceProvider).watch(matchId: matchId);
});
