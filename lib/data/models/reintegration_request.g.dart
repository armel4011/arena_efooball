// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reintegration_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ReintegrationRequest _$ReintegrationRequestFromJson(
  Map<String, dynamic> json,
) => _ReintegrationRequest(
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

Map<String, dynamic> _$ReintegrationRequestToJson(
  _ReintegrationRequest instance,
) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'message': instance.message,
  'status': instance.status,
  'created_at': ?instance.createdAt?.toIso8601String(),
  'resolved_at': ?instance.resolvedAt?.toIso8601String(),
  'resolved_by': ?instance.resolvedBy,
  'resolution_reason': ?instance.resolutionReason,
  'updated_at': ?instance.updatedAt?.toIso8601String(),
};
