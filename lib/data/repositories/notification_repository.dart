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

  /// Realtime stream of every notification belonging to [userId], newest
  /// first. RLS on `public.notifications` already filters by
  /// `auth.uid() = user_id` so the `.eq()` here is defence in depth.
  Stream<List<ArenaNotification>> watch(String userId) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at')
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
final userNotificationsProvider =
    StreamProvider.family<List<ArenaNotification>, String>((ref, userId) {
  return ref.watch(notificationRepositoryProvider).watch(userId);
});

/// Convenience — unread count derived from the stream above. Used by the
/// home page bell badge.
final unreadNotificationCountProvider =
    Provider.family<int, String>((ref, userId) {
  final notifs = ref.watch(userNotificationsProvider(userId));
  return notifs.maybeWhen(
    data: (list) => list.where((n) => n.isUnread).length,
    orElse: () => 0,
  );
});
