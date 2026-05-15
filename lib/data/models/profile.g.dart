// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProfileImpl _$$ProfileImplFromJson(Map<String, dynamic> json) =>
    _$ProfileImpl(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      countryCode: json['country_code'] as String,
      avatarColor: json['avatar_color'] as String? ?? '#4C7AFF',
      role: json['role'] == null
          ? UserRole.player
          : const UserRoleConverter().fromJson(json['role'] as String?),
      isActive: json['is_active'] as bool? ?? true,
      fcmToken: json['fcm_token'] as String?,
      stats:
          json['stats'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      authProvider: json['auth_provider'] as String? ?? 'email',
      authProviderId: json['auth_provider_id'] as String?,
      whatsappNumber: json['whatsapp_number'] as String?,
      preferredLanguage: json['preferred_language'] as String? ?? 'fr',
      preferredCurrency: json['preferred_currency'] as String? ?? 'XAF',
      timezone: json['timezone'] as String? ?? 'Africa/Douala',
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
      onboardingCompletedAt: json['onboarding_completed_at'] == null
          ? null
          : DateTime.parse(json['onboarding_completed_at'] as String),
      totpEnabled: json['totp_enabled'] as bool? ?? false,
      cguAcceptedAt: json['cgu_accepted_at'] == null
          ? null
          : DateTime.parse(json['cgu_accepted_at'] as String),
      cguVersionAccepted: json['cgu_version_accepted'] as String?,
      privacyPolicyAcceptedAt: json['privacy_policy_accepted_at'] == null
          ? null
          : DateTime.parse(json['privacy_policy_accepted_at'] as String),
      marketingConsent: json['marketing_consent'] as bool? ?? false,
      accountDeletionRequestedAt: json['account_deletion_requested_at'] == null
          ? null
          : DateTime.parse(json['account_deletion_requested_at'] as String),
      accountDeletionReason: json['account_deletion_reason'] as String?,
      deletedAt: json['deleted_at'] == null
          ? null
          : DateTime.parse(json['deleted_at'] as String),
      kycStatus: json['kyc_status'] as String? ?? 'none',
      kycVerifiedAt: json['kyc_verified_at'] == null
          ? null
          : DateTime.parse(json['kyc_verified_at'] as String),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$ProfileImplToJson(_$ProfileImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'email': instance.email,
      'country_code': instance.countryCode,
      'avatar_color': instance.avatarColor,
      if (const UserRoleConverter().toJson(instance.role) case final value?)
        'role': value,
      'is_active': instance.isActive,
      if (instance.fcmToken case final value?) 'fcm_token': value,
      'stats': instance.stats,
      'auth_provider': instance.authProvider,
      if (instance.authProviderId case final value?) 'auth_provider_id': value,
      if (instance.whatsappNumber case final value?) 'whatsapp_number': value,
      'preferred_language': instance.preferredLanguage,
      'preferred_currency': instance.preferredCurrency,
      'timezone': instance.timezone,
      'onboarding_completed': instance.onboardingCompleted,
      if (instance.onboardingCompletedAt?.toIso8601String() case final value?)
        'onboarding_completed_at': value,
      'totp_enabled': instance.totpEnabled,
      if (instance.cguAcceptedAt?.toIso8601String() case final value?)
        'cgu_accepted_at': value,
      if (instance.cguVersionAccepted case final value?)
        'cgu_version_accepted': value,
      if (instance.privacyPolicyAcceptedAt?.toIso8601String() case final value?)
        'privacy_policy_accepted_at': value,
      'marketing_consent': instance.marketingConsent,
      if (instance.accountDeletionRequestedAt?.toIso8601String()
          case final value?)
        'account_deletion_requested_at': value,
      if (instance.accountDeletionReason case final value?)
        'account_deletion_reason': value,
      if (instance.deletedAt?.toIso8601String() case final value?)
        'deleted_at': value,
      'kyc_status': instance.kycStatus,
      if (instance.kycVerifiedAt?.toIso8601String() case final value?)
        'kyc_verified_at': value,
      if (instance.createdAt?.toIso8601String() case final value?)
        'created_at': value,
      if (instance.updatedAt?.toIso8601String() case final value?)
        'updated_at': value,
    };
