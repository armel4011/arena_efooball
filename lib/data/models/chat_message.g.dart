// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ChatMessageImpl _$$ChatMessageImplFromJson(Map<String, dynamic> json) =>
    _$ChatMessageImpl(
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

Map<String, dynamic> _$$ChatMessageImplToJson(_$ChatMessageImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'channel_id': instance.channelId,
      'content': instance.content,
      if (instance.senderId case final value?) 'sender_id': value,
      'type': instance.type,
      'is_moderated': instance.isModerated,
      if (instance.moderatedAt?.toIso8601String() case final value?)
        'moderated_at': value,
      if (instance.moderatedReason case final value?) 'moderated_reason': value,
      if (instance.createdAt?.toIso8601String() case final value?)
        'created_at': value,
      if (instance.mediaUrl case final value?) 'media_url': value,
      if (instance.mediaType case final value?) 'media_type': value,
      if (instance.deletedAt?.toIso8601String() case final value?)
        'deleted_at': value,
    };
