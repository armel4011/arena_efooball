import 'package:freezed_annotation/freezed_annotation.dart';

part 'match_stream.freezed.dart';
part 'match_stream.g.dart';

/// Mirror of the `public.streams` table.
///
/// One row per recording or live-stream session. The same shape covers
/// two flows:
///   * **Anti-cheat recording** (PHASE 8.3) — `is_public = false`,
///     `url` points at a `match-recordings/{match}/{player}/...mp4`
///     object in Supabase Storage once the upload completes.
///   * **Live Agora stream** (PHASE 8.7) — `is_public = true`, `url`
///     holds the Agora channel name.
///
/// `is_active = true` while the session is in progress; the client
/// flips it to `false` and stamps `ended_at` from `markEnded()`.
@Freezed(fromJson: true, toJson: true)
sealed class MatchStream with _$MatchStream {
  const factory MatchStream({
    required String id,
    required String matchId,
    required String playerId,
    @Default(false) bool isPublic,
    @Default(true) bool isActive,
    String? url,
    DateTime? startedAt,
    DateTime? endedAt,
  }) = _MatchStream;

  factory MatchStream.fromJson(Map<String, dynamic> json) =>
      _$MatchStreamFromJson(json);
}
