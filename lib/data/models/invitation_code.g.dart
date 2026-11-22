// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invitation_code.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_InvitationCode _$InvitationCodeFromJson(Map<String, dynamic> json) =>
    _InvitationCode(
      id: json['id'] as String,
      code: json['code'] as String,
      role: json['role'] == null
          ? UserRole.admin
          : const UserRoleConverter().fromJson(json['role'] as String?),
      generatedBy: json['generated_by'] as String?,
      targetEmail: json['target_email'] as String?,
      expiresAt: json['expires_at'] == null
          ? null
          : DateTime.parse(json['expires_at'] as String),
      maxUses: (json['max_uses'] as num?)?.toInt() ?? 1,
      usesCount: (json['uses_count'] as num?)?.toInt() ?? 0,
      usedAt: json['used_at'] == null
          ? null
          : DateTime.parse(json['used_at'] as String),
      usedBy: json['used_by'] as String?,
      allowedCountryCodes: (json['allowed_country_codes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      allowedSections: (json['allowed_sections'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$InvitationCodeToJson(_InvitationCode instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'role': ?const UserRoleConverter().toJson(instance.role),
      'generated_by': ?instance.generatedBy,
      'target_email': ?instance.targetEmail,
      'expires_at': ?instance.expiresAt?.toIso8601String(),
      'max_uses': instance.maxUses,
      'uses_count': instance.usesCount,
      'used_at': ?instance.usedAt?.toIso8601String(),
      'used_by': ?instance.usedBy,
      'allowed_country_codes': ?instance.allowedCountryCodes,
      'allowed_sections': ?instance.allowedSections,
      'created_at': ?instance.createdAt?.toIso8601String(),
    };
