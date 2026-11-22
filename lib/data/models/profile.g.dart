// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Profile _$ProfileFromJson(Map<String, dynamic> json) => _Profile(
  id: json['id'] as String,
  username: json['username'] as String,
  countryCode: json['country_code'] as String,
  email: json['email'] as String?,
  avatarColor: json['avatar_color'] as String? ?? '#4C7AFF',
  avatarUrl: json['avatar_url'] as String?,
  role: json['role'] == null
      ? UserRole.player
      : const UserRoleConverter().fromJson(json['role'] as String?),
  isActive: json['is_active'] as bool? ?? true,
  permanentBan: json['permanent_ban'] as bool? ?? false,
  fcmToken: json['fcm_token'] as String?,
  stats: json['stats'] as Map<String, dynamic>? ?? const <String, dynamic>{},
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
  referralCode: json['referral_code'] as String? ?? '',
  referredBy: json['referred_by'] as String?,
  adminAllowedCountries: (json['admin_allowed_countries'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  adminAllowedSections: (json['admin_allowed_sections'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  gameInterests: const GameInterestsConverter().fromJson(
    json['game_interests'] as List?,
  ),
  birthDate: json['birth_date'] == null
      ? null
      : DateTime.parse(json['birth_date'] as String),
  deviceId: json['device_id'] as String?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$ProfileToJson(_Profile instance) => <String, dynamic>{
  'id': instance.id,
  'username': instance.username,
  'country_code': instance.countryCode,
  'email': ?instance.email,
  'avatar_color': instance.avatarColor,
  'avatar_url': ?instance.avatarUrl,
  'role': ?const UserRoleConverter().toJson(instance.role),
  'is_active': instance.isActive,
  'permanent_ban': instance.permanentBan,
  'fcm_token': ?instance.fcmToken,
  'stats': instance.stats,
  'auth_provider': instance.authProvider,
  'auth_provider_id': ?instance.authProviderId,
  'whatsapp_number': ?instance.whatsappNumber,
  'preferred_language': instance.preferredLanguage,
  'preferred_currency': instance.preferredCurrency,
  'timezone': instance.timezone,
  'onboarding_completed': instance.onboardingCompleted,
  'onboarding_completed_at': ?instance.onboardingCompletedAt?.toIso8601String(),
  'totp_enabled': instance.totpEnabled,
  'cgu_accepted_at': ?instance.cguAcceptedAt?.toIso8601String(),
  'cgu_version_accepted': ?instance.cguVersionAccepted,
  'privacy_policy_accepted_at': ?instance.privacyPolicyAcceptedAt
      ?.toIso8601String(),
  'marketing_consent': instance.marketingConsent,
  'account_deletion_requested_at': ?instance.accountDeletionRequestedAt
      ?.toIso8601String(),
  'account_deletion_reason': ?instance.accountDeletionReason,
  'deleted_at': ?instance.deletedAt?.toIso8601String(),
  'kyc_status': instance.kycStatus,
  'kyc_verified_at': ?instance.kycVerifiedAt?.toIso8601String(),
  'referral_code': instance.referralCode,
  'referred_by': ?instance.referredBy,
  'admin_allowed_countries': ?instance.adminAllowedCountries,
  'admin_allowed_sections': ?instance.adminAllowedSections,
  'game_interests': ?const GameInterestsConverter().toJson(
    instance.gameInterests,
  ),
  'birth_date': ?instance.birthDate?.toIso8601String(),
  'device_id': ?instance.deviceId,
  'created_at': ?instance.createdAt?.toIso8601String(),
  'updated_at': ?instance.updatedAt?.toIso8601String(),
};
