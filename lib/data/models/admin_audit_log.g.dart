// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_audit_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AdminAuditLog _$AdminAuditLogFromJson(Map<String, dynamic> json) =>
    _AdminAuditLog(
      id: json['id'] as String,
      adminId: json['admin_id'] as String,
      action: json['action'] as String,
      targetType: json['target_type'] as String?,
      targetId: json['target_id'] as String?,
      beforeState:
          json['before_state'] as Map<String, dynamic>? ??
          const <String, dynamic>{},
      afterState:
          json['after_state'] as Map<String, dynamic>? ??
          const <String, dynamic>{},
      ipAddress: json['ip_address'] as String?,
      userAgent: json['user_agent'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$AdminAuditLogToJson(_AdminAuditLog instance) =>
    <String, dynamic>{
      'id': instance.id,
      'admin_id': instance.adminId,
      'action': instance.action,
      'target_type': ?instance.targetType,
      'target_id': ?instance.targetId,
      'before_state': instance.beforeState,
      'after_state': instance.afterState,
      'ip_address': ?instance.ipAddress,
      'user_agent': ?instance.userAgent,
      'created_at': ?instance.createdAt?.toIso8601String(),
    };
