// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'arena_notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ArenaNotification _$ArenaNotificationFromJson(Map<String, dynamic> json) =>
    _ArenaNotification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String?,
      imageUrl: json['image_url'] as String?,
      data: json['data'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      readAt: json['read_at'] == null
          ? null
          : DateTime.parse(json['read_at'] as String),
      sentAt: json['sent_at'] == null
          ? null
          : DateTime.parse(json['sent_at'] as String),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$ArenaNotificationToJson(_ArenaNotification instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'type': instance.type,
      'title': instance.title,
      'body': ?instance.body,
      'image_url': ?instance.imageUrl,
      'data': instance.data,
      'read_at': ?instance.readAt?.toIso8601String(),
      'sent_at': ?instance.sentAt?.toIso8601String(),
      'created_at': ?instance.createdAt?.toIso8601String(),
    };
