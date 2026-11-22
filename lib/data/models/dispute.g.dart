// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dispute.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Dispute _$DisputeFromJson(Map<String, dynamic> json) => _Dispute(
  id: json['id'] as String,
  matchId: json['match_id'] as String,
  openedBy: json['opened_by'] as String,
  status: json['status'] as String? ?? 'open',
  reason: json['reason'] as String?,
  evidence:
      json['evidence'] as Map<String, dynamic>? ?? const <String, dynamic>{},
  escalationLevel: (json['escalation_level'] as num?)?.toInt() ?? 0,
  botAttemptedAt: json['bot_attempted_at'] == null
      ? null
      : DateTime.parse(json['bot_attempted_at'] as String),
  escalatedAt: json['escalated_at'] == null
      ? null
      : DateTime.parse(json['escalated_at'] as String),
  resolvedAt: json['resolved_at'] == null
      ? null
      : DateTime.parse(json['resolved_at'] as String),
  resolvedBy: json['resolved_by'] as String?,
  resolution: json['resolution'] as String?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$DisputeToJson(_Dispute instance) => <String, dynamic>{
  'id': instance.id,
  'match_id': instance.matchId,
  'opened_by': instance.openedBy,
  'status': instance.status,
  'reason': ?instance.reason,
  'evidence': instance.evidence,
  'escalation_level': instance.escalationLevel,
  'bot_attempted_at': ?instance.botAttemptedAt?.toIso8601String(),
  'escalated_at': ?instance.escalatedAt?.toIso8601String(),
  'resolved_at': ?instance.resolvedAt?.toIso8601String(),
  'resolved_by': ?instance.resolvedBy,
  'resolution': ?instance.resolution,
  'created_at': ?instance.createdAt?.toIso8601String(),
  'updated_at': ?instance.updatedAt?.toIso8601String(),
};
