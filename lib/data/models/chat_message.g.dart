// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) => _ChatMessage(
  id: json['id'] as String,
  channelId: json['channel_id'] as String,
  content: json['content'] as String,
  senderId: json['sender_id'] as String?,
  type: json['type'] as String? ?? 'text',
  isModerated: json['is_moderated'] as bool? ?? false,
  moderatedAt: json['moderated_at'] == null
      ? null
      : DateTime.parse(json['moderated_at'] as String),
  moderatedReason: json['moderated_reason'] as String?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  mediaUrl: json['media_url'] as String?,
  mediaType: json['media_type'] as String?,
  deletedAt: json['deleted_at'] == null
      ? null
      : DateTime.parse(json['deleted_at'] as String),
);

Map<String, dynamic> _$ChatMessageToJson(_ChatMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'channel_id': instance.channelId,
      'content': instance.content,
      'sender_id': ?instance.senderId,
      'type': instance.type,
      'is_moderated': instance.isModerated,
      'moderated_at': ?instance.moderatedAt?.toIso8601String(),
      'moderated_reason': ?instance.moderatedReason,
      'created_at': ?instance.createdAt?.toIso8601String(),
      'media_url': ?instance.mediaUrl,
      'media_type': ?instance.mediaType,
      'deleted_at': ?instance.deletedAt?.toIso8601String(),
    };
