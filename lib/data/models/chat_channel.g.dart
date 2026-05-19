// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_channel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ChatChannelImpl _$$ChatChannelImplFromJson(Map<String, dynamic> json) =>
    _$ChatChannelImpl(
      id: json['id'] as String,
      type: json['type'] as String,
      matchId: json['match_id'] as String?,
      competitionId: json['competition_id'] as String?,
      friendshipId: json['friendship_id'] as String?,
      name: json['name'] as String?,
      isArchived: json['is_archived'] as bool? ?? false,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      deletedAt: json['deleted_at'] == null
          ? null
          : DateTime.parse(json['deleted_at'] as String),
    );

Map<String, dynamic> _$$ChatChannelImplToJson(_$ChatChannelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      if (instance.matchId case final value?) 'match_id': value,
      if (instance.competitionId case final value?) 'competition_id': value,
      if (instance.friendshipId case final value?) 'friendship_id': value,
      if (instance.name case final value?) 'name': value,
      'is_archived': instance.isArchived,
      if (instance.createdAt?.toIso8601String() case final value?)
        'created_at': value,
      if (instance.deletedAt?.toIso8601String() case final value?)
        'deleted_at': value,
    };
