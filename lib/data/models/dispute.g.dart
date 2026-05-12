// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dispute.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DisputeImpl _$$DisputeImplFromJson(Map<String, dynamic> json) =>
    _$DisputeImpl(
      id: json['id'] as String,
      matchId: json['match_id'] as String,
      openedBy: json['opened_by'] as String,
      status: json['status'] as String? ?? 'open',
      reason: json['reason'] as String?,
      evidence: json['evidence'] as Map<String, dynamic>? ??
          const <String, dynamic>{},
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

Map<String, dynamic> _$$DisputeImplToJson(_$DisputeImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'match_id': instance.matchId,
      'opened_by': instance.openedBy,
      'status': instance.status,
      if (instance.reason case final value?) 'reason': value,
      'evidence': instance.evidence,
      'escalation_level': instance.escalationLevel,
      if (instance.botAttemptedAt?.toIso8601String() case final value?)
        'bot_attempted_at': value,
      if (instance.escalatedAt?.toIso8601String() case final value?)
        'escalated_at': value,
      if (instance.resolvedAt?.toIso8601String() case final value?)
        'resolved_at': value,
      if (instance.resolvedBy case final value?) 'resolved_by': value,
      if (instance.resolution case final value?) 'resolution': value,
      if (instance.createdAt?.toIso8601String() case final value?)
        'created_at': value,
      if (instance.updatedAt?.toIso8601String() case final value?)
        'updated_at': value,
    };
