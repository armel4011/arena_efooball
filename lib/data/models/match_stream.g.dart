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
    };
