import 'package:freezed_annotation/freezed_annotation.dart';

part 'arena_notification.freezed.dart';
part 'arena_notification.g.dart';

/// Mirror of the `public.notifications` table (PHASE 10).
///
/// `type` is a free-form string — known values today:
/// `match_starting`, `match_score_to_validate`, `competition_starting`,
/// `dispute_opened`, `payout_received`, `system`. The push payload
/// dispatched by the FCM Edge Function (PHASE 12.5) inserts the row
/// here too so the in-app feed stays in sync without a separate write.
@Freezed(fromJson: true, toJson: true)
sealed class ArenaNotification with _$ArenaNotification {
  const factory ArenaNotification({
    required String id,
    required String userId,
    required String type,
    required String title,
    String? body,
    @Default(<String, dynamic>{}) Map<String, dynamic> data,
    DateTime? readAt,
    DateTime? sentAt,
    DateTime? createdAt,
  }) = _ArenaNotification;

  const ArenaNotification._();

  factory ArenaNotification.fromJson(Map<String, dynamic> json) =>
      _$ArenaNotificationFromJson(json);

  bool get isUnread => readAt == null;

  /// Optional deep-link target carried in `data.route` so a notif tap
  /// can `go_router.go(route)` straight to the relevant screen.
  String? get route {
    final raw = data['route'];
    return raw is String && raw.isNotEmpty ? raw : null;
  }
}
