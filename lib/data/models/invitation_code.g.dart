// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invitation_code.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$InvitationCodeImpl _$$InvitationCodeImplFromJson(Map<String, dynamic> json) =>
    _$InvitationCodeImpl(
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

Map<String, dynamic> _$$InvitationCodeImplToJson(
        _$InvitationCodeImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      if (const UserRoleConverter().toJson(instance.role) case final value?)
        'role': value,
      if (instance.generatedBy case final value?) 'generated_by': value,
      if (instance.targetEmail case final value?) 'target_email': value,
      if (instance.expiresAt?.toIso8601String() case final value?)
        'expires_at': value,
      'max_uses': instance.maxUses,
      'uses_count': instance.usesCount,
      if (instance.usedAt?.toIso8601String() case final value?)
        'used_at': value,
      if (instance.usedBy case final value?) 'used_by': value,
      if (instance.allowedCountryCodes case final value?)
        'allowed_country_codes': value,
      if (instance.allowedSections case final value?) 'allowed_sections': value,
      if (instance.createdAt?.toIso8601String() case final value?)
        'created_at': value,
    };
