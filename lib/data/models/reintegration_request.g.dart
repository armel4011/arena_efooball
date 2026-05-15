// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reintegration_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ReintegrationRequestImpl _$$ReintegrationRequestImplFromJson(
        Map<String, dynamic> json) =>
    _$ReintegrationRequestImpl(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      message: json['message'] as String,
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      resolvedAt: json['resolved_at'] == null
          ? null
          : DateTime.parse(json['resolved_at'] as String),
      resolvedBy: json['resolved_by'] as String?,
      resolutionReason: json['resolution_reason'] as String?,
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$ReintegrationRequestImplToJson(
        _$ReintegrationRequestImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'message': instance.message,
      'status': instance.status,
      if (instance.createdAt?.toIso8601String() case final value?)
        'created_at': value,
      if (instance.resolvedAt?.toIso8601String() case final value?)
        'resolved_at': value,
      if (instance.resolvedBy case final value?) 'resolved_by': value,
      if (instance.resolutionReason case final value?)
        'resolution_reason': value,
      if (instance.updatedAt?.toIso8601String() case final value?)
        'updated_at': value,
    };
