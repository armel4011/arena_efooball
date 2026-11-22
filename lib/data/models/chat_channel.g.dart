// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_channel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChatChannel _$ChatChannelFromJson(Map<String, dynamic> json) => _ChatChannel(
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

Map<String, dynamic> _$ChatChannelToJson(_ChatChannel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'match_id': ?instance.matchId,
      'competition_id': ?instance.competitionId,
      'friendship_id': ?instance.friendshipId,
      'name': ?instance.name,
      'is_archived': instance.isArchived,
      'created_at': ?instance.createdAt?.toIso8601String(),
      'deleted_at': ?instance.deletedAt?.toIso8601String(),
    };
