// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'arena_notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ArenaNotificationImpl _$$ArenaNotificationImplFromJson(
        Map<String, dynamic> json) =>
    _$ArenaNotificationImpl(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String?,
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

Map<String, dynamic> _$$ArenaNotificationImplToJson(
        _$ArenaNotificationImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'type': instance.type,
      'title': instance.title,
      if (instance.body case final value?) 'body': value,
      'data': instance.data,
      if (instance.readAt?.toIso8601String() case final value?)
        'read_at': value,
      if (instance.sentAt?.toIso8601String() case final value?)
        'sent_at': value,
      if (instance.createdAt?.toIso8601String() case final value?)
        'created_at': value,
    };
