import 'package:arena/core/services/persistent_cache.dart';
import 'package:arena/data/models/arena_notification.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads + writes over `public.notifications` (PHASE 10).
///
/// The FCM dispatch side (Edge Function `send_targeted_notification`,
/// pg_cron sweep) lands in PHASE 12.5 — this repo only consumes the
/// rows after they've been inserted.
class NotificationRepository {
  const NotificationRepository(this._client);

  static const _table = 'notifications';
  static const _profilesTable = 'profiles';

  final SupabaseClient _client;

  /// Realtime stream of the latest [limit] notifications belonging to
  /// [userId], newest first. RLS on `public.notifications` already
  /// filters by `auth.uid() = user_id` so the `.eq()` here is defence
  /// in depth.
  ///
  /// The cap protects the home-page bell + notification center from
  /// pulling thousands of rows for power users — older entries land
  /// with a cursor-based loader in PHASE 12.5.
  Stream<List<ArenaNotification>> watch(String userId, {int limit = 100}) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit)
        .map(
          (rows) => [
            for (final row in rows) ArenaNotification.fromJson(row),
          ]..sort(_byCreatedAtDesc),
        );
  }

  Future<void> markRead(String id) async {
    await _client
        .from(_table)
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id)
        .isFilter('read_at', null);
  }

  /// Stamps `read_at = now()` on every unread row of [userId]. RLS keeps
  /// the update scoped to the caller, the explicit filter just lets us
  /// avoid touching already-read rows.
  Future<void> markAllRead(String userId) async {
    await _client
        .from(_table)
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('user_id', userId)
        .isFilter('read_at', null);
  }

  /// Saves the FCM device token on the caller's profile so the dispatch
  /// Edge Function (PHASE 12.5) can target this device. Skips the write
  /// if [token] matches what's already stored to avoid a Realtime echo
  /// every cold start.
  Future<void> saveFcmToken({
    required String userId,
    required String token,
  }) async {
    final current = await _client
        .from(_profilesTable)
        .select('fcm_token')
        .eq('id', userId)
        .maybeSingle();

    if (current != null && current['fcm_token'] == token) return;

    await _client
        .from(_profilesTable)
        .update({'fcm_token': token})
        .eq('id', userId);
  }

  /// Clears the FCM token (logout). The dispatch Edge Function skips
  /// rows whose `fcm_token` is NULL so this is enough to stop pushing
  /// to a signed-out device.
  Future<void> clearFcmToken(String userId) async {
    await _client
        .from(_profilesTable)
        .update({'fcm_token': null})
        .eq('id', userId);
  }

  /// Saves the iOS PushKit VoIP token on the caller's profile. The
  /// dispatch Edge Function routes `call_invite` pushes for iOS devices
  /// through APNs VoIP (FCM cannot send VoIP pushes). Skips the write
  /// when [token] is unchanged — same rationale as [saveFcmToken].
  Future<void> saveVoipToken({
    required String userId,
    required String token,
  }) async {
    final current = await _client
        .from(_profilesTable)
        .select('voip_token')
        .eq('id', userId)
        .maybeSingle();

    if (current != null && current['voip_token'] == token) return;

    await _client
        .from(_profilesTable)
        .update({'voip_token': token})
        .eq('id', userId);
  }

  /// Clears the VoIP token (logout, or PushKit invalidated it).
  Future<void> clearVoipToken(String userId) async {
    await _client
        .from(_profilesTable)
        .update({'voip_token': null})
        .eq('id', userId);
  }

  static int _byCreatedAtDesc(ArenaNotification a, ArenaNotification b) {
    final ad = a.createdAt;
    final bd = b.createdAt;
    if (ad == null && bd == null) return 0;
    if (ad == null) return 1;
    if (bd == null) return -1;
    return bd.compareTo(ad);
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(supabaseClientProvider));
});

/// Realtime stream of the signed-in user's notifications, newest first.
/// Returns an empty list when no user is signed in (signed-out splash etc.).
///
/// **Cold start cache** : la derniere liste reçue est persistee via
/// `PersistentCache` et réémise instantanément au prochain démarrage,
/// avant que le stream Supabase n'ait recu son premier event. La cloche
/// s'affiche donc avec son badge sans spinner ; les eventuels nouveaux
/// items arrivent par le stream dans la seconde qui suit.
final userNotificationsProvider = StreamProvider.family
    .autoDispose<List<ArenaNotification>, String>((ref, userId) async* {
  final source = ref.watch(notificationRepositoryProvider).watch(userId);
  final cache = await ref.watch(persistentCacheProvider.future);
  yield* cache.hydrate<ArenaNotification>(
    namespace: 'notifications.$userId',
    source: source,
    fromJson: ArenaNotification.fromJson,
    toJson: (n) => n.toJson(),
  );
});

/// Convenience — unread count derived from the stream above. Used by the
/// home page bell badge.
final unreadNotificationCountProvider =
    Provider.family.autoDispose<int, String>((ref, userId) {
  final notifs = ref.watch(userNotificationsProvider(userId));
  return notifs.maybeWhen(
    data: (list) => list.where((n) => n.isUnread).length,
    orElse: () => 0,
  );
});
