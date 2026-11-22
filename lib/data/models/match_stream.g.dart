// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_stream.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MatchStream _$MatchStreamFromJson(Map<String, dynamic> json) => _MatchStream(
  id: json['id'] as String,
  matchId: json['match_id'] as String,
  playerId: json['player_id'] as String,
  isPublic: json['is_public'] as bool? ?? false,
  isActive: json['is_active'] as bool? ?? true,
  url: json['url'] as String?,
  startedAt: json['started_at'] == null
      ? null
      : DateTime.parse(json['started_at'] as String),
  endedAt: json['ended_at'] == null
      ? null
      : DateTime.parse(json['ended_at'] as String),
  provider: json['provider'] as String? ?? 'native_recorder',
  storagePath: json['storage_path'] as String?,
  egressId: json['egress_id'] as String?,
  expiresAt: json['expires_at'] == null
      ? null
      : DateTime.parse(json['expires_at'] as String),
  proofSha256: json['proof_sha256'] as String?,
  proofBytes: (json['proof_bytes'] as num?)?.toInt(),
  proofDurationSeconds: (json['proof_duration_seconds'] as num?)?.toInt(),
  proofCommittedAt: json['proof_committed_at'] == null
      ? null
      : DateTime.parse(json['proof_committed_at'] as String),
  proofClaimedAt: json['proof_claimed_at'] == null
      ? null
      : DateTime.parse(json['proof_claimed_at'] as String),
  proofUploadedAt: json['proof_uploaded_at'] == null
      ? null
      : DateTime.parse(json['proof_uploaded_at'] as String),
  proofHashVerified: json['proof_hash_verified'] as bool?,
);

Map<String, dynamic> _$MatchStreamToJson(_MatchStream instance) =>
    <String, dynamic>{
      'id': instance.id,
      'match_id': instance.matchId,
      'player_id': instance.playerId,
      'is_public': instance.isPublic,
      'is_active': instance.isActive,
      'url': ?instance.url,
      'started_at': ?instance.startedAt?.toIso8601String(),
      'ended_at': ?instance.endedAt?.toIso8601String(),
      'provider': instance.provider,
      'storage_path': ?instance.storagePath,
      'egress_id': ?instance.egressId,
      'expires_at': ?instance.expiresAt?.toIso8601String(),
      'proof_sha256': ?instance.proofSha256,
      'proof_bytes': ?instance.proofBytes,
      'proof_duration_seconds': ?instance.proofDurationSeconds,
      'proof_committed_at': ?instance.proofCommittedAt?.toIso8601String(),
      'proof_claimed_at': ?instance.proofClaimedAt?.toIso8601String(),
      'proof_uploaded_at': ?instance.proofUploadedAt?.toIso8601String(),
      'proof_hash_verified': ?instance.proofHashVerified,
    };
