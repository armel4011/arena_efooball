// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_audit_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AdminAuditLogImpl _$$AdminAuditLogImplFromJson(Map<String, dynamic> json) =>
    _$AdminAuditLogImpl(
      id: json['id'] as String,
      adminId: json['admin_id'] as String,
      action: json['action'] as String,
      targetType: json['target_type'] as String?,
      targetId: json['target_id'] as String?,
      beforeState: json['before_state'] as Map<String, dynamic>? ??
          const <String, dynamic>{},
      afterState: json['after_state'] as Map<String, dynamic>? ??
          const <String, dynamic>{},
      ipAddress: json['ip_address'] as String?,
      userAgent: json['user_agent'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$AdminAuditLogImplToJson(_$AdminAuditLogImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'admin_id': instance.adminId,
      'action': instance.action,
      if (instance.targetType case final value?) 'target_type': value,
      if (instance.targetId case final value?) 'target_id': value,
      'before_state': instance.beforeState,
      'after_state': instance.afterState,
      if (instance.ipAddress case final value?) 'ip_address': value,
      if (instance.userAgent case final value?) 'user_agent': value,
      if (instance.createdAt?.toIso8601String() case final value?)
        'created_at': value,
    };
