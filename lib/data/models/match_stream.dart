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
    // Système anti-triche DUAL : provenance de l'enregistrement.
    // `native_recorder` (filet de sécurité) | `livekit_track_egress`.
    @Default('native_recorder') String provider,
    // Clé objet privée dans le bucket (résolue en URL signée côté admin).
    String? storagePath,
    // Identifiant LiveKit Track Egress (null pour le natif).
    String? egressId,
    // Échéance de rétention (purge cleanup-streams).
    DateTime? expiresAt,
    // ── Anti-triche Phase 3 : commitment hash (proxy 360p, upload on-demand) ──
    // SHA-256 (hex) du proxy 360p engagé par le client à la fin du match.
    String? proofSha256,
    // Taille (octets) et durée (s) du proxy engagé.
    int? proofBytes,
    int? proofDurationSeconds,
    // Instant de l'engagement du commitment (hash reçu côté serveur).
    DateTime? proofCommittedAt,
    // Instant où un admin a réclamé la vidéo (déclenche l'upload on-demand).
    DateTime? proofClaimedAt,
    // Instant de livraison effective du fichier par le client.
    DateTime? proofUploadedAt,
    // Le SHA-256 du fichier uploadé correspond-il au commitment ?
    // null = pas encore uploadé/vérifié.
    bool? proofHashVerified,
  }) = _MatchStream;

  factory MatchStream.fromJson(Map<String, dynamic> json) =>
      _$MatchStreamFromJson(json);
}
