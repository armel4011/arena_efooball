// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_stream.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MatchStreamImpl _$$MatchStreamImplFromJson(Map<String, dynamic> json) =>
    _$MatchStreamImpl(
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

Map<String, dynamic> _$$MatchStreamImplToJson(_$MatchStreamImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'match_id': instance.matchId,
      'player_id': instance.playerId,
      'is_public': instance.isPublic,
      'is_active': instance.isActive,
      if (instance.url case final value?) 'url': value,
      if (instance.startedAt?.toIso8601String() case final value?)
        'started_at': value,
      if (instance.endedAt?.toIso8601String() case final value?)
        'ended_at': value,
      'provider': instance.provider,
      if (instance.storagePath case final value?) 'storage_path': value,
      if (instance.egressId case final value?) 'egress_id': value,
      if (instance.expiresAt?.toIso8601String() case final value?)
        'expires_at': value,
      if (instance.proofSha256 case final value?) 'proof_sha256': value,
      if (instance.proofBytes case final value?) 'proof_bytes': value,
      if (instance.proofDurationSeconds case final value?)
        'proof_duration_seconds': value,
      if (instance.proofCommittedAt?.toIso8601String() case final value?)
        'proof_committed_at': value,
      if (instance.proofClaimedAt?.toIso8601String() case final value?)
        'proof_claimed_at': value,
      if (instance.proofUploadedAt?.toIso8601String() case final value?)
        'proof_uploaded_at': value,
      if (instance.proofHashVerified case final value?)
        'proof_hash_verified': value,
    };
