// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Profile {

 String get id; String get username; String get countryCode; String? get email; String get avatarColor; String? get avatarUrl;@UserRoleConverter() UserRole get role; bool get isActive; bool get permanentBan; String? get fcmToken; Map<String, dynamic> get stats; String get authProvider; String? get authProviderId; String? get whatsappNumber; String get preferredLanguage; String get preferredCurrency; String get timezone; bool get onboardingCompleted; DateTime? get onboardingCompletedAt; bool get totpEnabled; DateTime? get cguAcceptedAt; String? get cguVersionAccepted; DateTime? get privacyPolicyAcceptedAt; bool get marketingConsent; DateTime? get accountDeletionRequestedAt; String? get accountDeletionReason; DateTime? get deletedAt; String get kycStatus; DateTime? get kycVerifiedAt; String get referralCode; String? get referredBy; List<String>? get adminAllowedCountries; List<String>? get adminAllowedSections;@GameInterestsConverter() List<GameType>? get gameInterests;/// Date de naissance (PII) — saisie à l'inscription. Lue par le propriétaire
/// et les admins ; sert à calculer l'âge côté admin.
 DateTime? get birthDate;/// Empreinte d'appareil (ANDROID_ID) posée à l'inscription — anti-faux-
/// comptes (max 5 comptes/appareil + blocage auto-parrainage même appareil).
 String? get deviceId; DateTime? get createdAt; DateTime? get updatedAt;
/// Create a copy of Profile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfileCopyWith<Profile> get copyWith => _$ProfileCopyWithImpl<Profile>(this as Profile, _$identity);

  /// Serializes this Profile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Profile;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Profile&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.username, _this.username) || other.username == _this.username)&&(identical(other.countryCode, _this.countryCode) || other.countryCode == _this.countryCode)&&(identical(other.email, _this.email) || other.email == _this.email)&&(identical(other.avatarColor, _this.avatarColor) || other.avatarColor == _this.avatarColor)&&(identical(other.avatarUrl, _this.avatarUrl) || other.avatarUrl == _this.avatarUrl)&&(identical(other.role, _this.role) || other.role == _this.role)&&(identical(other.isActive, _this.isActive) || other.isActive == _this.isActive)&&(identical(other.permanentBan, _this.permanentBan) || other.permanentBan == _this.permanentBan)&&(identical(other.fcmToken, _this.fcmToken) || other.fcmToken == _this.fcmToken)&&const DeepCollectionEquality().equals(other.stats, _this.stats)&&(identical(other.authProvider, _this.authProvider) || other.authProvider == _this.authProvider)&&(identical(other.authProviderId, _this.authProviderId) || other.authProviderId == _this.authProviderId)&&(identical(other.whatsappNumber, _this.whatsappNumber) || other.whatsappNumber == _this.whatsappNumber)&&(identical(other.preferredLanguage, _this.preferredLanguage) || other.preferredLanguage == _this.preferredLanguage)&&(identical(other.preferredCurrency, _this.preferredCurrency) || other.preferredCurrency == _this.preferredCurrency)&&(identical(other.timezone, _this.timezone) || other.timezone == _this.timezone)&&(identical(other.onboardingCompleted, _this.onboardingCompleted) || other.onboardingCompleted == _this.onboardingCompleted)&&(identical(other.onboardingCompletedAt, _this.onboardingCompletedAt) || other.onboardingCompletedAt == _this.onboardingCompletedAt)&&(identical(other.totpEnabled, _this.totpEnabled) || other.totpEnabled == _this.totpEnabled)&&(identical(other.cguAcceptedAt, _this.cguAcceptedAt) || other.cguAcceptedAt == _this.cguAcceptedAt)&&(identical(other.cguVersionAccepted, _this.cguVersionAccepted) || other.cguVersionAccepted == _this.cguVersionAccepted)&&(identical(other.privacyPolicyAcceptedAt, _this.privacyPolicyAcceptedAt) || other.privacyPolicyAcceptedAt == _this.privacyPolicyAcceptedAt)&&(identical(other.marketingConsent, _this.marketingConsent) || other.marketingConsent == _this.marketingConsent)&&(identical(other.accountDeletionRequestedAt, _this.accountDeletionRequestedAt) || other.accountDeletionRequestedAt == _this.accountDeletionRequestedAt)&&(identical(other.accountDeletionReason, _this.accountDeletionReason) || other.accountDeletionReason == _this.accountDeletionReason)&&(identical(other.deletedAt, _this.deletedAt) || other.deletedAt == _this.deletedAt)&&(identical(other.kycStatus, _this.kycStatus) || other.kycStatus == _this.kycStatus)&&(identical(other.kycVerifiedAt, _this.kycVerifiedAt) || other.kycVerifiedAt == _this.kycVerifiedAt)&&(identical(other.referralCode, _this.referralCode) || other.referralCode == _this.referralCode)&&(identical(other.referredBy, _this.referredBy) || other.referredBy == _this.referredBy)&&const DeepCollectionEquality().equals(other.adminAllowedCountries, _this.adminAllowedCountries)&&const DeepCollectionEquality().equals(other.adminAllowedSections, _this.adminAllowedSections)&&const DeepCollectionEquality().equals(other.gameInterests, _this.gameInterests)&&(identical(other.birthDate, _this.birthDate) || other.birthDate == _this.birthDate)&&(identical(other.deviceId, _this.deviceId) || other.deviceId == _this.deviceId)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Profile;
  return Object.hashAll([runtimeType,_this.id,_this.username,_this.countryCode,_this.email,_this.avatarColor,_this.avatarUrl,_this.role,_this.isActive,_this.permanentBan,_this.fcmToken,const DeepCollectionEquality().hash(_this.stats),_this.authProvider,_this.authProviderId,_this.whatsappNumber,_this.preferredLanguage,_this.preferredCurrency,_this.timezone,_this.onboardingCompleted,_this.onboardingCompletedAt,_this.totpEnabled,_this.cguAcceptedAt,_this.cguVersionAccepted,_this.privacyPolicyAcceptedAt,_this.marketingConsent,_this.accountDeletionRequestedAt,_this.accountDeletionReason,_this.deletedAt,_this.kycStatus,_this.kycVerifiedAt,_this.referralCode,_this.referredBy,const DeepCollectionEquality().hash(_this.adminAllowedCountries),const DeepCollectionEquality().hash(_this.adminAllowedSections),const DeepCollectionEquality().hash(_this.gameInterests),_this.birthDate,_this.deviceId,_this.createdAt,_this.updatedAt]);
}

@override
String toString() {
  final _this = this as Profile;
  return 'Profile(id: ${_this.id}, username: ${_this.username}, countryCode: ${_this.countryCode}, email: ${_this.email}, avatarColor: ${_this.avatarColor}, avatarUrl: ${_this.avatarUrl}, role: ${_this.role}, isActive: ${_this.isActive}, permanentBan: ${_this.permanentBan}, fcmToken: ${_this.fcmToken}, stats: ${_this.stats}, authProvider: ${_this.authProvider}, authProviderId: ${_this.authProviderId}, whatsappNumber: ${_this.whatsappNumber}, preferredLanguage: ${_this.preferredLanguage}, preferredCurrency: ${_this.preferredCurrency}, timezone: ${_this.timezone}, onboardingCompleted: ${_this.onboardingCompleted}, onboardingCompletedAt: ${_this.onboardingCompletedAt}, totpEnabled: ${_this.totpEnabled}, cguAcceptedAt: ${_this.cguAcceptedAt}, cguVersionAccepted: ${_this.cguVersionAccepted}, privacyPolicyAcceptedAt: ${_this.privacyPolicyAcceptedAt}, marketingConsent: ${_this.marketingConsent}, accountDeletionRequestedAt: ${_this.accountDeletionRequestedAt}, accountDeletionReason: ${_this.accountDeletionReason}, deletedAt: ${_this.deletedAt}, kycStatus: ${_this.kycStatus}, kycVerifiedAt: ${_this.kycVerifiedAt}, referralCode: ${_this.referralCode}, referredBy: ${_this.referredBy}, adminAllowedCountries: ${_this.adminAllowedCountries}, adminAllowedSections: ${_this.adminAllowedSections}, gameInterests: ${_this.gameInterests}, birthDate: ${_this.birthDate}, deviceId: ${_this.deviceId}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $ProfileCopyWith<$Res>  {
  factory $ProfileCopyWith(Profile value, $Res Function(Profile) _then) = _$ProfileCopyWithImpl;
@useResult
$Res call({
 String id, String username, String countryCode, String? email, String avatarColor, String? avatarUrl,@UserRoleConverter() UserRole role, bool isActive, bool permanentBan, String? fcmToken, Map<String, dynamic> stats, String authProvider, String? authProviderId, String? whatsappNumber, String preferredLanguage, String preferredCurrency, String timezone, bool onboardingCompleted, DateTime? onboardingCompletedAt, bool totpEnabled, DateTime? cguAcceptedAt, String? cguVersionAccepted, DateTime? privacyPolicyAcceptedAt, bool marketingConsent, DateTime? accountDeletionRequestedAt, String? accountDeletionReason, DateTime? deletedAt, String kycStatus, DateTime? kycVerifiedAt, String referralCode, String? referredBy, List<String>? adminAllowedCountries, List<String>? adminAllowedSections,@GameInterestsConverter() List<GameType>? gameInterests, DateTime? birthDate, String? deviceId, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$ProfileCopyWithImpl<$Res>
    implements $ProfileCopyWith<$Res> {
  _$ProfileCopyWithImpl(this._self, this._then);

  final Profile _self;
  final $Res Function(Profile) _then;

/// Create a copy of Profile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? username = null,Object? countryCode = null,Object? email = freezed,Object? avatarColor = null,Object? avatarUrl = freezed,Object? role = null,Object? isActive = null,Object? permanentBan = null,Object? fcmToken = freezed,Object? stats = null,Object? authProvider = null,Object? authProviderId = freezed,Object? whatsappNumber = freezed,Object? preferredLanguage = null,Object? preferredCurrency = null,Object? timezone = null,Object? onboardingCompleted = null,Object? onboardingCompletedAt = freezed,Object? totpEnabled = null,Object? cguAcceptedAt = freezed,Object? cguVersionAccepted = freezed,Object? privacyPolicyAcceptedAt = freezed,Object? marketingConsent = null,Object? accountDeletionRequestedAt = freezed,Object? accountDeletionReason = freezed,Object? deletedAt = freezed,Object? kycStatus = null,Object? kycVerifiedAt = freezed,Object? referralCode = null,Object? referredBy = freezed,Object? adminAllowedCountries = freezed,Object? adminAllowedSections = freezed,Object? gameInterests = freezed,Object? birthDate = freezed,Object? deviceId = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(Profile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,countryCode: null == countryCode ? _self.countryCode : countryCode // ignore: cast_nullable_to_non_nullable
as String,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,avatarColor: null == avatarColor ? _self.avatarColor : avatarColor // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as UserRole,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,permanentBan: null == permanentBan ? _self.permanentBan : permanentBan // ignore: cast_nullable_to_non_nullable
as bool,fcmToken: freezed == fcmToken ? _self.fcmToken : fcmToken // ignore: cast_nullable_to_non_nullable
as String?,stats: null == stats ? _self.stats : stats // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,authProvider: null == authProvider ? _self.authProvider : authProvider // ignore: cast_nullable_to_non_nullable
as String,authProviderId: freezed == authProviderId ? _self.authProviderId : authProviderId // ignore: cast_nullable_to_non_nullable
as String?,whatsappNumber: freezed == whatsappNumber ? _self.whatsappNumber : whatsappNumber // ignore: cast_nullable_to_non_nullable
as String?,preferredLanguage: null == preferredLanguage ? _self.preferredLanguage : preferredLanguage // ignore: cast_nullable_to_non_nullable
as String,preferredCurrency: null == preferredCurrency ? _self.preferredCurrency : preferredCurrency // ignore: cast_nullable_to_non_nullable
as String,timezone: null == timezone ? _self.timezone : timezone // ignore: cast_nullable_to_non_nullable
as String,onboardingCompleted: null == onboardingCompleted ? _self.onboardingCompleted : onboardingCompleted // ignore: cast_nullable_to_non_nullable
as bool,onboardingCompletedAt: freezed == onboardingCompletedAt ? _self.onboardingCompletedAt : onboardingCompletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,totpEnabled: null == totpEnabled ? _self.totpEnabled : totpEnabled // ignore: cast_nullable_to_non_nullable
as bool,cguAcceptedAt: freezed == cguAcceptedAt ? _self.cguAcceptedAt : cguAcceptedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,cguVersionAccepted: freezed == cguVersionAccepted ? _self.cguVersionAccepted : cguVersionAccepted // ignore: cast_nullable_to_non_nullable
as String?,privacyPolicyAcceptedAt: freezed == privacyPolicyAcceptedAt ? _self.privacyPolicyAcceptedAt : privacyPolicyAcceptedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,marketingConsent: null == marketingConsent ? _self.marketingConsent : marketingConsent // ignore: cast_nullable_to_non_nullable
as bool,accountDeletionRequestedAt: freezed == accountDeletionRequestedAt ? _self.accountDeletionRequestedAt : accountDeletionRequestedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,accountDeletionReason: freezed == accountDeletionReason ? _self.accountDeletionReason : accountDeletionReason // ignore: cast_nullable_to_non_nullable
as String?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,kycStatus: null == kycStatus ? _self.kycStatus : kycStatus // ignore: cast_nullable_to_non_nullable
as String,kycVerifiedAt: freezed == kycVerifiedAt ? _self.kycVerifiedAt : kycVerifiedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,referralCode: null == referralCode ? _self.referralCode : referralCode // ignore: cast_nullable_to_non_nullable
as String,referredBy: freezed == referredBy ? _self.referredBy : referredBy // ignore: cast_nullable_to_non_nullable
as String?,adminAllowedCountries: freezed == adminAllowedCountries ? _self.adminAllowedCountries : adminAllowedCountries // ignore: cast_nullable_to_non_nullable
as List<String>?,adminAllowedSections: freezed == adminAllowedSections ? _self.adminAllowedSections : adminAllowedSections // ignore: cast_nullable_to_non_nullable
as List<String>?,gameInterests: freezed == gameInterests ? _self.gameInterests : gameInterests // ignore: cast_nullable_to_non_nullable
as List<GameType>?,birthDate: freezed == birthDate ? _self.birthDate : birthDate // ignore: cast_nullable_to_non_nullable
as DateTime?,deviceId: freezed == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Profile].
extension ProfilePatterns on Profile {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Profile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Profile() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Profile value)  $default,){
final _that = this;
switch (_that) {
case _Profile():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Profile value)?  $default,){
final _that = this;
switch (_that) {
case _Profile() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String username,  String countryCode,  String? email,  String avatarColor,  String? avatarUrl, @UserRoleConverter()  UserRole role,  bool isActive,  bool permanentBan,  String? fcmToken,  Map<String, dynamic> stats,  String authProvider,  String? authProviderId,  String? whatsappNumber,  String preferredLanguage,  String preferredCurrency,  String timezone,  bool onboardingCompleted,  DateTime? onboardingCompletedAt,  bool totpEnabled,  DateTime? cguAcceptedAt,  String? cguVersionAccepted,  DateTime? privacyPolicyAcceptedAt,  bool marketingConsent,  DateTime? accountDeletionRequestedAt,  String? accountDeletionReason,  DateTime? deletedAt,  String kycStatus,  DateTime? kycVerifiedAt,  String referralCode,  String? referredBy,  List<String>? adminAllowedCountries,  List<String>? adminAllowedSections, @GameInterestsConverter()  List<GameType>? gameInterests,  DateTime? birthDate,  String? deviceId,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Profile() when $default != null:
return $default(_that.id,_that.username,_that.countryCode,_that.email,_that.avatarColor,_that.avatarUrl,_that.role,_that.isActive,_that.permanentBan,_that.fcmToken,_that.stats,_that.authProvider,_that.authProviderId,_that.whatsappNumber,_that.preferredLanguage,_that.preferredCurrency,_that.timezone,_that.onboardingCompleted,_that.onboardingCompletedAt,_that.totpEnabled,_that.cguAcceptedAt,_that.cguVersionAccepted,_that.privacyPolicyAcceptedAt,_that.marketingConsent,_that.accountDeletionRequestedAt,_that.accountDeletionReason,_that.deletedAt,_that.kycStatus,_that.kycVerifiedAt,_that.referralCode,_that.referredBy,_that.adminAllowedCountries,_that.adminAllowedSections,_that.gameInterests,_that.birthDate,_that.deviceId,_that.createdAt,_that.updatedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String username,  String countryCode,  String? email,  String avatarColor,  String? avatarUrl, @UserRoleConverter()  UserRole role,  bool isActive,  bool permanentBan,  String? fcmToken,  Map<String, dynamic> stats,  String authProvider,  String? authProviderId,  String? whatsappNumber,  String preferredLanguage,  String preferredCurrency,  String timezone,  bool onboardingCompleted,  DateTime? onboardingCompletedAt,  bool totpEnabled,  DateTime? cguAcceptedAt,  String? cguVersionAccepted,  DateTime? privacyPolicyAcceptedAt,  bool marketingConsent,  DateTime? accountDeletionRequestedAt,  String? accountDeletionReason,  DateTime? deletedAt,  String kycStatus,  DateTime? kycVerifiedAt,  String referralCode,  String? referredBy,  List<String>? adminAllowedCountries,  List<String>? adminAllowedSections, @GameInterestsConverter()  List<GameType>? gameInterests,  DateTime? birthDate,  String? deviceId,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Profile():
return $default(_that.id,_that.username,_that.countryCode,_that.email,_that.avatarColor,_that.avatarUrl,_that.role,_that.isActive,_that.permanentBan,_that.fcmToken,_that.stats,_that.authProvider,_that.authProviderId,_that.whatsappNumber,_that.preferredLanguage,_that.preferredCurrency,_that.timezone,_that.onboardingCompleted,_that.onboardingCompletedAt,_that.totpEnabled,_that.cguAcceptedAt,_that.cguVersionAccepted,_that.privacyPolicyAcceptedAt,_that.marketingConsent,_that.accountDeletionRequestedAt,_that.accountDeletionReason,_that.deletedAt,_that.kycStatus,_that.kycVerifiedAt,_that.referralCode,_that.referredBy,_that.adminAllowedCountries,_that.adminAllowedSections,_that.gameInterests,_that.birthDate,_that.deviceId,_that.createdAt,_that.updatedAt);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String username,  String countryCode,  String? email,  String avatarColor,  String? avatarUrl, @UserRoleConverter()  UserRole role,  bool isActive,  bool permanentBan,  String? fcmToken,  Map<String, dynamic> stats,  String authProvider,  String? authProviderId,  String? whatsappNumber,  String preferredLanguage,  String preferredCurrency,  String timezone,  bool onboardingCompleted,  DateTime? onboardingCompletedAt,  bool totpEnabled,  DateTime? cguAcceptedAt,  String? cguVersionAccepted,  DateTime? privacyPolicyAcceptedAt,  bool marketingConsent,  DateTime? accountDeletionRequestedAt,  String? accountDeletionReason,  DateTime? deletedAt,  String kycStatus,  DateTime? kycVerifiedAt,  String referralCode,  String? referredBy,  List<String>? adminAllowedCountries,  List<String>? adminAllowedSections, @GameInterestsConverter()  List<GameType>? gameInterests,  DateTime? birthDate,  String? deviceId,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Profile() when $default != null:
return $default(_that.id,_that.username,_that.countryCode,_that.email,_that.avatarColor,_that.avatarUrl,_that.role,_that.isActive,_that.permanentBan,_that.fcmToken,_that.stats,_that.authProvider,_that.authProviderId,_that.whatsappNumber,_that.preferredLanguage,_that.preferredCurrency,_that.timezone,_that.onboardingCompleted,_that.onboardingCompletedAt,_that.totpEnabled,_that.cguAcceptedAt,_that.cguVersionAccepted,_that.privacyPolicyAcceptedAt,_that.marketingConsent,_that.accountDeletionRequestedAt,_that.accountDeletionReason,_that.deletedAt,_that.kycStatus,_that.kycVerifiedAt,_that.referralCode,_that.referredBy,_that.adminAllowedCountries,_that.adminAllowedSections,_that.gameInterests,_that.birthDate,_that.deviceId,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Profile extends Profile {
  const _Profile({required this.id, required this.username, required this.countryCode, this.email, this.avatarColor = '#4C7AFF', this.avatarUrl, @UserRoleConverter() this.role = UserRole.player, this.isActive = true, this.permanentBan = false, this.fcmToken,  Map<String, dynamic> stats = const <String, dynamic>{}, this.authProvider = 'email', this.authProviderId, this.whatsappNumber, this.preferredLanguage = 'fr', this.preferredCurrency = 'XAF', this.timezone = 'Africa/Douala', this.onboardingCompleted = false, this.onboardingCompletedAt, this.totpEnabled = false, this.cguAcceptedAt, this.cguVersionAccepted, this.privacyPolicyAcceptedAt, this.marketingConsent = false, this.accountDeletionRequestedAt, this.accountDeletionReason, this.deletedAt, this.kycStatus = 'none', this.kycVerifiedAt, this.referralCode = '', this.referredBy,  List<String>? adminAllowedCountries,  List<String>? adminAllowedSections, @GameInterestsConverter()  List<GameType>? gameInterests, this.birthDate, this.deviceId, this.createdAt, this.updatedAt}): _stats = stats,_adminAllowedCountries = adminAllowedCountries,_adminAllowedSections = adminAllowedSections,_gameInterests = gameInterests,super._();
  factory _Profile.fromJson(Map<String, dynamic> json) => _$ProfileFromJson(json);

@override final  String id;
@override final  String username;
@override final  String countryCode;
@override final  String? email;
@override@JsonKey() final  String avatarColor;
@override final  String? avatarUrl;
@override@JsonKey()@UserRoleConverter() final  UserRole role;
@override@JsonKey() final  bool isActive;
@override@JsonKey() final  bool permanentBan;
@override final  String? fcmToken;
 final  Map<String, dynamic> _stats;
@override@JsonKey() Map<String, dynamic> get stats {
  if (_stats is EqualUnmodifiableMapView) return _stats;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_stats);
}

@override@JsonKey() final  String authProvider;
@override final  String? authProviderId;
@override final  String? whatsappNumber;
@override@JsonKey() final  String preferredLanguage;
@override@JsonKey() final  String preferredCurrency;
@override@JsonKey() final  String timezone;
@override@JsonKey() final  bool onboardingCompleted;
@override final  DateTime? onboardingCompletedAt;
@override@JsonKey() final  bool totpEnabled;
@override final  DateTime? cguAcceptedAt;
@override final  String? cguVersionAccepted;
@override final  DateTime? privacyPolicyAcceptedAt;
@override@JsonKey() final  bool marketingConsent;
@override final  DateTime? accountDeletionRequestedAt;
@override final  String? accountDeletionReason;
@override final  DateTime? deletedAt;
@override@JsonKey() final  String kycStatus;
@override final  DateTime? kycVerifiedAt;
@override@JsonKey() final  String referralCode;
@override final  String? referredBy;
 final  List<String>? _adminAllowedCountries;
@override List<String>? get adminAllowedCountries {
  final value = _adminAllowedCountries;
  if (value == null) return null;
  if (_adminAllowedCountries is EqualUnmodifiableListView) return _adminAllowedCountries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  List<String>? _adminAllowedSections;
@override List<String>? get adminAllowedSections {
  final value = _adminAllowedSections;
  if (value == null) return null;
  if (_adminAllowedSections is EqualUnmodifiableListView) return _adminAllowedSections;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  List<GameType>? _gameInterests;
@override@GameInterestsConverter() List<GameType>? get gameInterests {
  final value = _gameInterests;
  if (value == null) return null;
  if (_gameInterests is EqualUnmodifiableListView) return _gameInterests;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// Date de naissance (PII) — saisie à l'inscription. Lue par le propriétaire
/// et les admins ; sert à calculer l'âge côté admin.
@override final  DateTime? birthDate;
/// Empreinte d'appareil (ANDROID_ID) posée à l'inscription — anti-faux-
/// comptes (max 5 comptes/appareil + blocage auto-parrainage même appareil).
@override final  String? deviceId;
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;

/// Create a copy of Profile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfileCopyWith<_Profile> get copyWith => __$ProfileCopyWithImpl<_Profile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProfileToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Profile&&(identical(other.id, id) || other.id == id)&&(identical(other.username, username) || other.username == username)&&(identical(other.countryCode, countryCode) || other.countryCode == countryCode)&&(identical(other.email, email) || other.email == email)&&(identical(other.avatarColor, avatarColor) || other.avatarColor == avatarColor)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.role, role) || other.role == role)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.permanentBan, permanentBan) || other.permanentBan == permanentBan)&&(identical(other.fcmToken, fcmToken) || other.fcmToken == fcmToken)&&const DeepCollectionEquality().equals(other.stats, _stats)&&(identical(other.authProvider, authProvider) || other.authProvider == authProvider)&&(identical(other.authProviderId, authProviderId) || other.authProviderId == authProviderId)&&(identical(other.whatsappNumber, whatsappNumber) || other.whatsappNumber == whatsappNumber)&&(identical(other.preferredLanguage, preferredLanguage) || other.preferredLanguage == preferredLanguage)&&(identical(other.preferredCurrency, preferredCurrency) || other.preferredCurrency == preferredCurrency)&&(identical(other.timezone, timezone) || other.timezone == timezone)&&(identical(other.onboardingCompleted, onboardingCompleted) || other.onboardingCompleted == onboardingCompleted)&&(identical(other.onboardingCompletedAt, onboardingCompletedAt) || other.onboardingCompletedAt == onboardingCompletedAt)&&(identical(other.totpEnabled, totpEnabled) || other.totpEnabled == totpEnabled)&&(identical(other.cguAcceptedAt, cguAcceptedAt) || other.cguAcceptedAt == cguAcceptedAt)&&(identical(other.cguVersionAccepted, cguVersionAccepted) || other.cguVersionAccepted == cguVersionAccepted)&&(identical(other.privacyPolicyAcceptedAt, privacyPolicyAcceptedAt) || other.privacyPolicyAcceptedAt == privacyPolicyAcceptedAt)&&(identical(other.marketingConsent, marketingConsent) || other.marketingConsent == marketingConsent)&&(identical(other.accountDeletionRequestedAt, accountDeletionRequestedAt) || other.accountDeletionRequestedAt == accountDeletionRequestedAt)&&(identical(other.accountDeletionReason, accountDeletionReason) || other.accountDeletionReason == accountDeletionReason)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.kycStatus, kycStatus) || other.kycStatus == kycStatus)&&(identical(other.kycVerifiedAt, kycVerifiedAt) || other.kycVerifiedAt == kycVerifiedAt)&&(identical(other.referralCode, referralCode) || other.referralCode == referralCode)&&(identical(other.referredBy, referredBy) || other.referredBy == referredBy)&&const DeepCollectionEquality().equals(other.adminAllowedCountries, _adminAllowedCountries)&&const DeepCollectionEquality().equals(other.adminAllowedSections, _adminAllowedSections)&&const DeepCollectionEquality().equals(other.gameInterests, _gameInterests)&&(identical(other.birthDate, birthDate) || other.birthDate == birthDate)&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hashAll([runtimeType,id,username,countryCode,email,avatarColor,avatarUrl,role,isActive,permanentBan,fcmToken,const DeepCollectionEquality().hash(_stats),authProvider,authProviderId,whatsappNumber,preferredLanguage,preferredCurrency,timezone,onboardingCompleted,onboardingCompletedAt,totpEnabled,cguAcceptedAt,cguVersionAccepted,privacyPolicyAcceptedAt,marketingConsent,accountDeletionRequestedAt,accountDeletionReason,deletedAt,kycStatus,kycVerifiedAt,referralCode,referredBy,const DeepCollectionEquality().hash(_adminAllowedCountries),const DeepCollectionEquality().hash(_adminAllowedSections),const DeepCollectionEquality().hash(_gameInterests),birthDate,deviceId,createdAt,updatedAt]);
}

@override
String toString() {
    return 'Profile(id: $id, username: $username, countryCode: $countryCode, email: $email, avatarColor: $avatarColor, avatarUrl: $avatarUrl, role: $role, isActive: $isActive, permanentBan: $permanentBan, fcmToken: $fcmToken, stats: $stats, authProvider: $authProvider, authProviderId: $authProviderId, whatsappNumber: $whatsappNumber, preferredLanguage: $preferredLanguage, preferredCurrency: $preferredCurrency, timezone: $timezone, onboardingCompleted: $onboardingCompleted, onboardingCompletedAt: $onboardingCompletedAt, totpEnabled: $totpEnabled, cguAcceptedAt: $cguAcceptedAt, cguVersionAccepted: $cguVersionAccepted, privacyPolicyAcceptedAt: $privacyPolicyAcceptedAt, marketingConsent: $marketingConsent, accountDeletionRequestedAt: $accountDeletionRequestedAt, accountDeletionReason: $accountDeletionReason, deletedAt: $deletedAt, kycStatus: $kycStatus, kycVerifiedAt: $kycVerifiedAt, referralCode: $referralCode, referredBy: $referredBy, adminAllowedCountries: $adminAllowedCountries, adminAllowedSections: $adminAllowedSections, gameInterests: $gameInterests, birthDate: $birthDate, deviceId: $deviceId, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ProfileCopyWith<$Res> implements $ProfileCopyWith<$Res> {
  factory _$ProfileCopyWith(_Profile value, $Res Function(_Profile) _then) = __$ProfileCopyWithImpl;
@override @useResult
$Res call({
 String id, String username, String countryCode, String? email, String avatarColor, String? avatarUrl,@UserRoleConverter() UserRole role, bool isActive, bool permanentBan, String? fcmToken, Map<String, dynamic> stats, String authProvider, String? authProviderId, String? whatsappNumber, String preferredLanguage, String preferredCurrency, String timezone, bool onboardingCompleted, DateTime? onboardingCompletedAt, bool totpEnabled, DateTime? cguAcceptedAt, String? cguVersionAccepted, DateTime? privacyPolicyAcceptedAt, bool marketingConsent, DateTime? accountDeletionRequestedAt, String? accountDeletionReason, DateTime? deletedAt, String kycStatus, DateTime? kycVerifiedAt, String referralCode, String? referredBy, List<String>? adminAllowedCountries, List<String>? adminAllowedSections,@GameInterestsConverter() List<GameType>? gameInterests, DateTime? birthDate, String? deviceId, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$ProfileCopyWithImpl<$Res>
    implements _$ProfileCopyWith<$Res> {
  __$ProfileCopyWithImpl(this._self, this._then);

  final _Profile _self;
  final $Res Function(_Profile) _then;

/// Create a copy of Profile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? username = null,Object? countryCode = null,Object? email = freezed,Object? avatarColor = null,Object? avatarUrl = freezed,Object? role = null,Object? isActive = null,Object? permanentBan = null,Object? fcmToken = freezed,Object? stats = null,Object? authProvider = null,Object? authProviderId = freezed,Object? whatsappNumber = freezed,Object? preferredLanguage = null,Object? preferredCurrency = null,Object? timezone = null,Object? onboardingCompleted = null,Object? onboardingCompletedAt = freezed,Object? totpEnabled = null,Object? cguAcceptedAt = freezed,Object? cguVersionAccepted = freezed,Object? privacyPolicyAcceptedAt = freezed,Object? marketingConsent = null,Object? accountDeletionRequestedAt = freezed,Object? accountDeletionReason = freezed,Object? deletedAt = freezed,Object? kycStatus = null,Object? kycVerifiedAt = freezed,Object? referralCode = null,Object? referredBy = freezed,Object? adminAllowedCountries = freezed,Object? adminAllowedSections = freezed,Object? gameInterests = freezed,Object? birthDate = freezed,Object? deviceId = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_Profile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,countryCode: null == countryCode ? _self.countryCode : countryCode // ignore: cast_nullable_to_non_nullable
as String,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,avatarColor: null == avatarColor ? _self.avatarColor : avatarColor // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as UserRole,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,permanentBan: null == permanentBan ? _self.permanentBan : permanentBan // ignore: cast_nullable_to_non_nullable
as bool,fcmToken: freezed == fcmToken ? _self.fcmToken : fcmToken // ignore: cast_nullable_to_non_nullable
as String?,stats: null == stats ? _self._stats : stats // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,authProvider: null == authProvider ? _self.authProvider : authProvider // ignore: cast_nullable_to_non_nullable
as String,authProviderId: freezed == authProviderId ? _self.authProviderId : authProviderId // ignore: cast_nullable_to_non_nullable
as String?,whatsappNumber: freezed == whatsappNumber ? _self.whatsappNumber : whatsappNumber // ignore: cast_nullable_to_non_nullable
as String?,preferredLanguage: null == preferredLanguage ? _self.preferredLanguage : preferredLanguage // ignore: cast_nullable_to_non_nullable
as String,preferredCurrency: null == preferredCurrency ? _self.preferredCurrency : preferredCurrency // ignore: cast_nullable_to_non_nullable
as String,timezone: null == timezone ? _self.timezone : timezone // ignore: cast_nullable_to_non_nullable
as String,onboardingCompleted: null == onboardingCompleted ? _self.onboardingCompleted : onboardingCompleted // ignore: cast_nullable_to_non_nullable
as bool,onboardingCompletedAt: freezed == onboardingCompletedAt ? _self.onboardingCompletedAt : onboardingCompletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,totpEnabled: null == totpEnabled ? _self.totpEnabled : totpEnabled // ignore: cast_nullable_to_non_nullable
as bool,cguAcceptedAt: freezed == cguAcceptedAt ? _self.cguAcceptedAt : cguAcceptedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,cguVersionAccepted: freezed == cguVersionAccepted ? _self.cguVersionAccepted : cguVersionAccepted // ignore: cast_nullable_to_non_nullable
as String?,privacyPolicyAcceptedAt: freezed == privacyPolicyAcceptedAt ? _self.privacyPolicyAcceptedAt : privacyPolicyAcceptedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,marketingConsent: null == marketingConsent ? _self.marketingConsent : marketingConsent // ignore: cast_nullable_to_non_nullable
as bool,accountDeletionRequestedAt: freezed == accountDeletionRequestedAt ? _self.accountDeletionRequestedAt : accountDeletionRequestedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,accountDeletionReason: freezed == accountDeletionReason ? _self.accountDeletionReason : accountDeletionReason // ignore: cast_nullable_to_non_nullable
as String?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,kycStatus: null == kycStatus ? _self.kycStatus : kycStatus // ignore: cast_nullable_to_non_nullable
as String,kycVerifiedAt: freezed == kycVerifiedAt ? _self.kycVerifiedAt : kycVerifiedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,referralCode: null == referralCode ? _self.referralCode : referralCode // ignore: cast_nullable_to_non_nullable
as String,referredBy: freezed == referredBy ? _self.referredBy : referredBy // ignore: cast_nullable_to_non_nullable
as String?,adminAllowedCountries: freezed == adminAllowedCountries ? _self._adminAllowedCountries : adminAllowedCountries // ignore: cast_nullable_to_non_nullable
as List<String>?,adminAllowedSections: freezed == adminAllowedSections ? _self._adminAllowedSections : adminAllowedSections // ignore: cast_nullable_to_non_nullable
as List<String>?,gameInterests: freezed == gameInterests ? _self._gameInterests : gameInterests // ignore: cast_nullable_to_non_nullable
as List<GameType>?,birthDate: freezed == birthDate ? _self.birthDate : birthDate // ignore: cast_nullable_to_non_nullable
as DateTime?,deviceId: freezed == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
