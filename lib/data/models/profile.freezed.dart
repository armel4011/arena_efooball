// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Profile _$ProfileFromJson(Map<String, dynamic> json) {
  return _Profile.fromJson(json);
}

/// @nodoc
mixin _$Profile {
  String get id => throw _privateConstructorUsedError;
  String get username => throw _privateConstructorUsedError;
  String get countryCode =>
      throw _privateConstructorUsedError; // Nullable depuis le fix C-1 résiduel : les lectures cross-user passent
// par la vue `public_profiles` qui n'expose PAS l'email (PII). Non-null
// en pratique pour le profil de l'utilisateur courant (lu sur la table).
  String? get email => throw _privateConstructorUsedError;
  String get avatarColor =>
      throw _privateConstructorUsedError; // Photo d'avatar (bucket Storage `avatars`). NULL → repli cercle coloré
// + initiale via [avatarColor].
  String? get avatarUrl => throw _privateConstructorUsedError;
  @UserRoleConverter()
  UserRole get role => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;
  bool get permanentBan => throw _privateConstructorUsedError;
  String? get fcmToken => throw _privateConstructorUsedError;
  Map<String, dynamic> get stats => throw _privateConstructorUsedError;
  String get authProvider => throw _privateConstructorUsedError;
  String? get authProviderId => throw _privateConstructorUsedError;
  String? get whatsappNumber => throw _privateConstructorUsedError;
  String get preferredLanguage => throw _privateConstructorUsedError;
  String get preferredCurrency => throw _privateConstructorUsedError;
  String get timezone => throw _privateConstructorUsedError;
  bool get onboardingCompleted => throw _privateConstructorUsedError;
  DateTime? get onboardingCompletedAt => throw _privateConstructorUsedError;
  bool get totpEnabled => throw _privateConstructorUsedError;
  DateTime? get cguAcceptedAt => throw _privateConstructorUsedError;
  String? get cguVersionAccepted => throw _privateConstructorUsedError;
  DateTime? get privacyPolicyAcceptedAt => throw _privateConstructorUsedError;
  bool get marketingConsent => throw _privateConstructorUsedError;
  DateTime? get accountDeletionRequestedAt =>
      throw _privateConstructorUsedError;
  String? get accountDeletionReason => throw _privateConstructorUsedError;
  DateTime? get deletedAt => throw _privateConstructorUsedError;
  String get kycStatus => throw _privateConstructorUsedError;
  DateTime? get kycVerifiedAt =>
      throw _privateConstructorUsedError; // Lot D — Système de parrainage (item 8).
  String get referralCode => throw _privateConstructorUsedError;
  String? get referredBy =>
      throw _privateConstructorUsedError; // VOLET 3 — périmètre admin restreint (par code d'invitation). NULL ou
// liste vide = aucune restriction (voit tout). Sinon l'admin/super-admin
// est limité aux pays (ISO alpha-2) / sections listés. Propagé par l'EF
// `register-admin` depuis `invitation_codes.allowed_*`.
  List<String>? get adminAllowedCountries => throw _privateConstructorUsedError;
  List<String>? get adminAllowedSections =>
      throw _privateConstructorUsedError; // Sondage « jeux d'intérêt » : jeux dont l'utilisateur veut disputer des
// compétitions. NULL = n'a JAMAIS répondu (nouveau compte → déclenche le
// dialogue obligatoire au 1er démarrage) ; liste (éventuellement vide) =
// a répondu. Écrit une seule fois via le RPC `set_game_interests`.
  @GameInterestsConverter()
  List<GameType>? get gameInterests => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this Profile to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Profile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProfileCopyWith<Profile> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProfileCopyWith<$Res> {
  factory $ProfileCopyWith(Profile value, $Res Function(Profile) then) =
      _$ProfileCopyWithImpl<$Res, Profile>;
  @useResult
  $Res call(
      {String id,
      String username,
      String countryCode,
      String? email,
      String avatarColor,
      String? avatarUrl,
      @UserRoleConverter() UserRole role,
      bool isActive,
      bool permanentBan,
      String? fcmToken,
      Map<String, dynamic> stats,
      String authProvider,
      String? authProviderId,
      String? whatsappNumber,
      String preferredLanguage,
      String preferredCurrency,
      String timezone,
      bool onboardingCompleted,
      DateTime? onboardingCompletedAt,
      bool totpEnabled,
      DateTime? cguAcceptedAt,
      String? cguVersionAccepted,
      DateTime? privacyPolicyAcceptedAt,
      bool marketingConsent,
      DateTime? accountDeletionRequestedAt,
      String? accountDeletionReason,
      DateTime? deletedAt,
      String kycStatus,
      DateTime? kycVerifiedAt,
      String referralCode,
      String? referredBy,
      List<String>? adminAllowedCountries,
      List<String>? adminAllowedSections,
      @GameInterestsConverter() List<GameType>? gameInterests,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class _$ProfileCopyWithImpl<$Res, $Val extends Profile>
    implements $ProfileCopyWith<$Res> {
  _$ProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Profile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? username = null,
    Object? countryCode = null,
    Object? email = freezed,
    Object? avatarColor = null,
    Object? avatarUrl = freezed,
    Object? role = null,
    Object? isActive = null,
    Object? permanentBan = null,
    Object? fcmToken = freezed,
    Object? stats = null,
    Object? authProvider = null,
    Object? authProviderId = freezed,
    Object? whatsappNumber = freezed,
    Object? preferredLanguage = null,
    Object? preferredCurrency = null,
    Object? timezone = null,
    Object? onboardingCompleted = null,
    Object? onboardingCompletedAt = freezed,
    Object? totpEnabled = null,
    Object? cguAcceptedAt = freezed,
    Object? cguVersionAccepted = freezed,
    Object? privacyPolicyAcceptedAt = freezed,
    Object? marketingConsent = null,
    Object? accountDeletionRequestedAt = freezed,
    Object? accountDeletionReason = freezed,
    Object? deletedAt = freezed,
    Object? kycStatus = null,
    Object? kycVerifiedAt = freezed,
    Object? referralCode = null,
    Object? referredBy = freezed,
    Object? adminAllowedCountries = freezed,
    Object? adminAllowedSections = freezed,
    Object? gameInterests = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      username: null == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String,
      countryCode: null == countryCode
          ? _value.countryCode
          : countryCode // ignore: cast_nullable_to_non_nullable
              as String,
      email: freezed == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      avatarColor: null == avatarColor
          ? _value.avatarColor
          : avatarColor // ignore: cast_nullable_to_non_nullable
              as String,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as UserRole,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      permanentBan: null == permanentBan
          ? _value.permanentBan
          : permanentBan // ignore: cast_nullable_to_non_nullable
              as bool,
      fcmToken: freezed == fcmToken
          ? _value.fcmToken
          : fcmToken // ignore: cast_nullable_to_non_nullable
              as String?,
      stats: null == stats
          ? _value.stats
          : stats // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      authProvider: null == authProvider
          ? _value.authProvider
          : authProvider // ignore: cast_nullable_to_non_nullable
              as String,
      authProviderId: freezed == authProviderId
          ? _value.authProviderId
          : authProviderId // ignore: cast_nullable_to_non_nullable
              as String?,
      whatsappNumber: freezed == whatsappNumber
          ? _value.whatsappNumber
          : whatsappNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      preferredLanguage: null == preferredLanguage
          ? _value.preferredLanguage
          : preferredLanguage // ignore: cast_nullable_to_non_nullable
              as String,
      preferredCurrency: null == preferredCurrency
          ? _value.preferredCurrency
          : preferredCurrency // ignore: cast_nullable_to_non_nullable
              as String,
      timezone: null == timezone
          ? _value.timezone
          : timezone // ignore: cast_nullable_to_non_nullable
              as String,
      onboardingCompleted: null == onboardingCompleted
          ? _value.onboardingCompleted
          : onboardingCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
      onboardingCompletedAt: freezed == onboardingCompletedAt
          ? _value.onboardingCompletedAt
          : onboardingCompletedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      totpEnabled: null == totpEnabled
          ? _value.totpEnabled
          : totpEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      cguAcceptedAt: freezed == cguAcceptedAt
          ? _value.cguAcceptedAt
          : cguAcceptedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      cguVersionAccepted: freezed == cguVersionAccepted
          ? _value.cguVersionAccepted
          : cguVersionAccepted // ignore: cast_nullable_to_non_nullable
              as String?,
      privacyPolicyAcceptedAt: freezed == privacyPolicyAcceptedAt
          ? _value.privacyPolicyAcceptedAt
          : privacyPolicyAcceptedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      marketingConsent: null == marketingConsent
          ? _value.marketingConsent
          : marketingConsent // ignore: cast_nullable_to_non_nullable
              as bool,
      accountDeletionRequestedAt: freezed == accountDeletionRequestedAt
          ? _value.accountDeletionRequestedAt
          : accountDeletionRequestedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      accountDeletionReason: freezed == accountDeletionReason
          ? _value.accountDeletionReason
          : accountDeletionReason // ignore: cast_nullable_to_non_nullable
              as String?,
      deletedAt: freezed == deletedAt
          ? _value.deletedAt
          : deletedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      kycStatus: null == kycStatus
          ? _value.kycStatus
          : kycStatus // ignore: cast_nullable_to_non_nullable
              as String,
      kycVerifiedAt: freezed == kycVerifiedAt
          ? _value.kycVerifiedAt
          : kycVerifiedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      referralCode: null == referralCode
          ? _value.referralCode
          : referralCode // ignore: cast_nullable_to_non_nullable
              as String,
      referredBy: freezed == referredBy
          ? _value.referredBy
          : referredBy // ignore: cast_nullable_to_non_nullable
              as String?,
      adminAllowedCountries: freezed == adminAllowedCountries
          ? _value.adminAllowedCountries
          : adminAllowedCountries // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      adminAllowedSections: freezed == adminAllowedSections
          ? _value.adminAllowedSections
          : adminAllowedSections // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      gameInterests: freezed == gameInterests
          ? _value.gameInterests
          : gameInterests // ignore: cast_nullable_to_non_nullable
              as List<GameType>?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProfileImplCopyWith<$Res> implements $ProfileCopyWith<$Res> {
  factory _$$ProfileImplCopyWith(
          _$ProfileImpl value, $Res Function(_$ProfileImpl) then) =
      __$$ProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String username,
      String countryCode,
      String? email,
      String avatarColor,
      String? avatarUrl,
      @UserRoleConverter() UserRole role,
      bool isActive,
      bool permanentBan,
      String? fcmToken,
      Map<String, dynamic> stats,
      String authProvider,
      String? authProviderId,
      String? whatsappNumber,
      String preferredLanguage,
      String preferredCurrency,
      String timezone,
      bool onboardingCompleted,
      DateTime? onboardingCompletedAt,
      bool totpEnabled,
      DateTime? cguAcceptedAt,
      String? cguVersionAccepted,
      DateTime? privacyPolicyAcceptedAt,
      bool marketingConsent,
      DateTime? accountDeletionRequestedAt,
      String? accountDeletionReason,
      DateTime? deletedAt,
      String kycStatus,
      DateTime? kycVerifiedAt,
      String referralCode,
      String? referredBy,
      List<String>? adminAllowedCountries,
      List<String>? adminAllowedSections,
      @GameInterestsConverter() List<GameType>? gameInterests,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class __$$ProfileImplCopyWithImpl<$Res>
    extends _$ProfileCopyWithImpl<$Res, _$ProfileImpl>
    implements _$$ProfileImplCopyWith<$Res> {
  __$$ProfileImplCopyWithImpl(
      _$ProfileImpl _value, $Res Function(_$ProfileImpl) _then)
      : super(_value, _then);

  /// Create a copy of Profile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? username = null,
    Object? countryCode = null,
    Object? email = freezed,
    Object? avatarColor = null,
    Object? avatarUrl = freezed,
    Object? role = null,
    Object? isActive = null,
    Object? permanentBan = null,
    Object? fcmToken = freezed,
    Object? stats = null,
    Object? authProvider = null,
    Object? authProviderId = freezed,
    Object? whatsappNumber = freezed,
    Object? preferredLanguage = null,
    Object? preferredCurrency = null,
    Object? timezone = null,
    Object? onboardingCompleted = null,
    Object? onboardingCompletedAt = freezed,
    Object? totpEnabled = null,
    Object? cguAcceptedAt = freezed,
    Object? cguVersionAccepted = freezed,
    Object? privacyPolicyAcceptedAt = freezed,
    Object? marketingConsent = null,
    Object? accountDeletionRequestedAt = freezed,
    Object? accountDeletionReason = freezed,
    Object? deletedAt = freezed,
    Object? kycStatus = null,
    Object? kycVerifiedAt = freezed,
    Object? referralCode = null,
    Object? referredBy = freezed,
    Object? adminAllowedCountries = freezed,
    Object? adminAllowedSections = freezed,
    Object? gameInterests = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$ProfileImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      username: null == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String,
      countryCode: null == countryCode
          ? _value.countryCode
          : countryCode // ignore: cast_nullable_to_non_nullable
              as String,
      email: freezed == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      avatarColor: null == avatarColor
          ? _value.avatarColor
          : avatarColor // ignore: cast_nullable_to_non_nullable
              as String,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as UserRole,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      permanentBan: null == permanentBan
          ? _value.permanentBan
          : permanentBan // ignore: cast_nullable_to_non_nullable
              as bool,
      fcmToken: freezed == fcmToken
          ? _value.fcmToken
          : fcmToken // ignore: cast_nullable_to_non_nullable
              as String?,
      stats: null == stats
          ? _value._stats
          : stats // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      authProvider: null == authProvider
          ? _value.authProvider
          : authProvider // ignore: cast_nullable_to_non_nullable
              as String,
      authProviderId: freezed == authProviderId
          ? _value.authProviderId
          : authProviderId // ignore: cast_nullable_to_non_nullable
              as String?,
      whatsappNumber: freezed == whatsappNumber
          ? _value.whatsappNumber
          : whatsappNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      preferredLanguage: null == preferredLanguage
          ? _value.preferredLanguage
          : preferredLanguage // ignore: cast_nullable_to_non_nullable
              as String,
      preferredCurrency: null == preferredCurrency
          ? _value.preferredCurrency
          : preferredCurrency // ignore: cast_nullable_to_non_nullable
              as String,
      timezone: null == timezone
          ? _value.timezone
          : timezone // ignore: cast_nullable_to_non_nullable
              as String,
      onboardingCompleted: null == onboardingCompleted
          ? _value.onboardingCompleted
          : onboardingCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
      onboardingCompletedAt: freezed == onboardingCompletedAt
          ? _value.onboardingCompletedAt
          : onboardingCompletedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      totpEnabled: null == totpEnabled
          ? _value.totpEnabled
          : totpEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      cguAcceptedAt: freezed == cguAcceptedAt
          ? _value.cguAcceptedAt
          : cguAcceptedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      cguVersionAccepted: freezed == cguVersionAccepted
          ? _value.cguVersionAccepted
          : cguVersionAccepted // ignore: cast_nullable_to_non_nullable
              as String?,
      privacyPolicyAcceptedAt: freezed == privacyPolicyAcceptedAt
          ? _value.privacyPolicyAcceptedAt
          : privacyPolicyAcceptedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      marketingConsent: null == marketingConsent
          ? _value.marketingConsent
          : marketingConsent // ignore: cast_nullable_to_non_nullable
              as bool,
      accountDeletionRequestedAt: freezed == accountDeletionRequestedAt
          ? _value.accountDeletionRequestedAt
          : accountDeletionRequestedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      accountDeletionReason: freezed == accountDeletionReason
          ? _value.accountDeletionReason
          : accountDeletionReason // ignore: cast_nullable_to_non_nullable
              as String?,
      deletedAt: freezed == deletedAt
          ? _value.deletedAt
          : deletedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      kycStatus: null == kycStatus
          ? _value.kycStatus
          : kycStatus // ignore: cast_nullable_to_non_nullable
              as String,
      kycVerifiedAt: freezed == kycVerifiedAt
          ? _value.kycVerifiedAt
          : kycVerifiedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      referralCode: null == referralCode
          ? _value.referralCode
          : referralCode // ignore: cast_nullable_to_non_nullable
              as String,
      referredBy: freezed == referredBy
          ? _value.referredBy
          : referredBy // ignore: cast_nullable_to_non_nullable
              as String?,
      adminAllowedCountries: freezed == adminAllowedCountries
          ? _value._adminAllowedCountries
          : adminAllowedCountries // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      adminAllowedSections: freezed == adminAllowedSections
          ? _value._adminAllowedSections
          : adminAllowedSections // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      gameInterests: freezed == gameInterests
          ? _value._gameInterests
          : gameInterests // ignore: cast_nullable_to_non_nullable
              as List<GameType>?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProfileImpl extends _Profile {
  const _$ProfileImpl(
      {required this.id,
      required this.username,
      required this.countryCode,
      this.email,
      this.avatarColor = '#4C7AFF',
      this.avatarUrl,
      @UserRoleConverter() this.role = UserRole.player,
      this.isActive = true,
      this.permanentBan = false,
      this.fcmToken,
      final Map<String, dynamic> stats = const <String, dynamic>{},
      this.authProvider = 'email',
      this.authProviderId,
      this.whatsappNumber,
      this.preferredLanguage = 'fr',
      this.preferredCurrency = 'XAF',
      this.timezone = 'Africa/Douala',
      this.onboardingCompleted = false,
      this.onboardingCompletedAt,
      this.totpEnabled = false,
      this.cguAcceptedAt,
      this.cguVersionAccepted,
      this.privacyPolicyAcceptedAt,
      this.marketingConsent = false,
      this.accountDeletionRequestedAt,
      this.accountDeletionReason,
      this.deletedAt,
      this.kycStatus = 'none',
      this.kycVerifiedAt,
      this.referralCode = '',
      this.referredBy,
      final List<String>? adminAllowedCountries,
      final List<String>? adminAllowedSections,
      @GameInterestsConverter() final List<GameType>? gameInterests,
      this.createdAt,
      this.updatedAt})
      : _stats = stats,
        _adminAllowedCountries = adminAllowedCountries,
        _adminAllowedSections = adminAllowedSections,
        _gameInterests = gameInterests,
        super._();

  factory _$ProfileImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProfileImplFromJson(json);

  @override
  final String id;
  @override
  final String username;
  @override
  final String countryCode;
// Nullable depuis le fix C-1 résiduel : les lectures cross-user passent
// par la vue `public_profiles` qui n'expose PAS l'email (PII). Non-null
// en pratique pour le profil de l'utilisateur courant (lu sur la table).
  @override
  final String? email;
  @override
  @JsonKey()
  final String avatarColor;
// Photo d'avatar (bucket Storage `avatars`). NULL → repli cercle coloré
// + initiale via [avatarColor].
  @override
  final String? avatarUrl;
  @override
  @JsonKey()
  @UserRoleConverter()
  final UserRole role;
  @override
  @JsonKey()
  final bool isActive;
  @override
  @JsonKey()
  final bool permanentBan;
  @override
  final String? fcmToken;
  final Map<String, dynamic> _stats;
  @override
  @JsonKey()
  Map<String, dynamic> get stats {
    if (_stats is EqualUnmodifiableMapView) return _stats;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_stats);
  }

  @override
  @JsonKey()
  final String authProvider;
  @override
  final String? authProviderId;
  @override
  final String? whatsappNumber;
  @override
  @JsonKey()
  final String preferredLanguage;
  @override
  @JsonKey()
  final String preferredCurrency;
  @override
  @JsonKey()
  final String timezone;
  @override
  @JsonKey()
  final bool onboardingCompleted;
  @override
  final DateTime? onboardingCompletedAt;
  @override
  @JsonKey()
  final bool totpEnabled;
  @override
  final DateTime? cguAcceptedAt;
  @override
  final String? cguVersionAccepted;
  @override
  final DateTime? privacyPolicyAcceptedAt;
  @override
  @JsonKey()
  final bool marketingConsent;
  @override
  final DateTime? accountDeletionRequestedAt;
  @override
  final String? accountDeletionReason;
  @override
  final DateTime? deletedAt;
  @override
  @JsonKey()
  final String kycStatus;
  @override
  final DateTime? kycVerifiedAt;
// Lot D — Système de parrainage (item 8).
  @override
  @JsonKey()
  final String referralCode;
  @override
  final String? referredBy;
// VOLET 3 — périmètre admin restreint (par code d'invitation). NULL ou
// liste vide = aucune restriction (voit tout). Sinon l'admin/super-admin
// est limité aux pays (ISO alpha-2) / sections listés. Propagé par l'EF
// `register-admin` depuis `invitation_codes.allowed_*`.
  final List<String>? _adminAllowedCountries;
// VOLET 3 — périmètre admin restreint (par code d'invitation). NULL ou
// liste vide = aucune restriction (voit tout). Sinon l'admin/super-admin
// est limité aux pays (ISO alpha-2) / sections listés. Propagé par l'EF
// `register-admin` depuis `invitation_codes.allowed_*`.
  @override
  List<String>? get adminAllowedCountries {
    final value = _adminAllowedCountries;
    if (value == null) return null;
    if (_adminAllowedCountries is EqualUnmodifiableListView)
      return _adminAllowedCountries;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _adminAllowedSections;
  @override
  List<String>? get adminAllowedSections {
    final value = _adminAllowedSections;
    if (value == null) return null;
    if (_adminAllowedSections is EqualUnmodifiableListView)
      return _adminAllowedSections;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

// Sondage « jeux d'intérêt » : jeux dont l'utilisateur veut disputer des
// compétitions. NULL = n'a JAMAIS répondu (nouveau compte → déclenche le
// dialogue obligatoire au 1er démarrage) ; liste (éventuellement vide) =
// a répondu. Écrit une seule fois via le RPC `set_game_interests`.
  final List<GameType>? _gameInterests;
// Sondage « jeux d'intérêt » : jeux dont l'utilisateur veut disputer des
// compétitions. NULL = n'a JAMAIS répondu (nouveau compte → déclenche le
// dialogue obligatoire au 1er démarrage) ; liste (éventuellement vide) =
// a répondu. Écrit une seule fois via le RPC `set_game_interests`.
  @override
  @GameInterestsConverter()
  List<GameType>? get gameInterests {
    final value = _gameInterests;
    if (value == null) return null;
    if (_gameInterests is EqualUnmodifiableListView) return _gameInterests;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'Profile(id: $id, username: $username, countryCode: $countryCode, email: $email, avatarColor: $avatarColor, avatarUrl: $avatarUrl, role: $role, isActive: $isActive, permanentBan: $permanentBan, fcmToken: $fcmToken, stats: $stats, authProvider: $authProvider, authProviderId: $authProviderId, whatsappNumber: $whatsappNumber, preferredLanguage: $preferredLanguage, preferredCurrency: $preferredCurrency, timezone: $timezone, onboardingCompleted: $onboardingCompleted, onboardingCompletedAt: $onboardingCompletedAt, totpEnabled: $totpEnabled, cguAcceptedAt: $cguAcceptedAt, cguVersionAccepted: $cguVersionAccepted, privacyPolicyAcceptedAt: $privacyPolicyAcceptedAt, marketingConsent: $marketingConsent, accountDeletionRequestedAt: $accountDeletionRequestedAt, accountDeletionReason: $accountDeletionReason, deletedAt: $deletedAt, kycStatus: $kycStatus, kycVerifiedAt: $kycVerifiedAt, referralCode: $referralCode, referredBy: $referredBy, adminAllowedCountries: $adminAllowedCountries, adminAllowedSections: $adminAllowedSections, gameInterests: $gameInterests, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProfileImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.countryCode, countryCode) ||
                other.countryCode == countryCode) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.avatarColor, avatarColor) ||
                other.avatarColor == avatarColor) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.permanentBan, permanentBan) ||
                other.permanentBan == permanentBan) &&
            (identical(other.fcmToken, fcmToken) ||
                other.fcmToken == fcmToken) &&
            const DeepCollectionEquality().equals(other._stats, _stats) &&
            (identical(other.authProvider, authProvider) ||
                other.authProvider == authProvider) &&
            (identical(other.authProviderId, authProviderId) ||
                other.authProviderId == authProviderId) &&
            (identical(other.whatsappNumber, whatsappNumber) ||
                other.whatsappNumber == whatsappNumber) &&
            (identical(other.preferredLanguage, preferredLanguage) ||
                other.preferredLanguage == preferredLanguage) &&
            (identical(other.preferredCurrency, preferredCurrency) ||
                other.preferredCurrency == preferredCurrency) &&
            (identical(other.timezone, timezone) ||
                other.timezone == timezone) &&
            (identical(other.onboardingCompleted, onboardingCompleted) ||
                other.onboardingCompleted == onboardingCompleted) &&
            (identical(other.onboardingCompletedAt, onboardingCompletedAt) ||
                other.onboardingCompletedAt == onboardingCompletedAt) &&
            (identical(other.totpEnabled, totpEnabled) ||
                other.totpEnabled == totpEnabled) &&
            (identical(other.cguAcceptedAt, cguAcceptedAt) ||
                other.cguAcceptedAt == cguAcceptedAt) &&
            (identical(other.cguVersionAccepted, cguVersionAccepted) ||
                other.cguVersionAccepted == cguVersionAccepted) &&
            (identical(other.privacyPolicyAcceptedAt, privacyPolicyAcceptedAt) ||
                other.privacyPolicyAcceptedAt == privacyPolicyAcceptedAt) &&
            (identical(other.marketingConsent, marketingConsent) ||
                other.marketingConsent == marketingConsent) &&
            (identical(other.accountDeletionRequestedAt,
                    accountDeletionRequestedAt) ||
                other.accountDeletionRequestedAt ==
                    accountDeletionRequestedAt) &&
            (identical(other.accountDeletionReason, accountDeletionReason) ||
                other.accountDeletionReason == accountDeletionReason) &&
            (identical(other.deletedAt, deletedAt) ||
                other.deletedAt == deletedAt) &&
            (identical(other.kycStatus, kycStatus) ||
                other.kycStatus == kycStatus) &&
            (identical(other.kycVerifiedAt, kycVerifiedAt) ||
                other.kycVerifiedAt == kycVerifiedAt) &&
            (identical(other.referralCode, referralCode) ||
                other.referralCode == referralCode) &&
            (identical(other.referredBy, referredBy) ||
                other.referredBy == referredBy) &&
            const DeepCollectionEquality()
                .equals(other._adminAllowedCountries, _adminAllowedCountries) &&
            const DeepCollectionEquality()
                .equals(other._adminAllowedSections, _adminAllowedSections) &&
            const DeepCollectionEquality()
                .equals(other._gameInterests, _gameInterests) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        username,
        countryCode,
        email,
        avatarColor,
        avatarUrl,
        role,
        isActive,
        permanentBan,
        fcmToken,
        const DeepCollectionEquality().hash(_stats),
        authProvider,
        authProviderId,
        whatsappNumber,
        preferredLanguage,
        preferredCurrency,
        timezone,
        onboardingCompleted,
        onboardingCompletedAt,
        totpEnabled,
        cguAcceptedAt,
        cguVersionAccepted,
        privacyPolicyAcceptedAt,
        marketingConsent,
        accountDeletionRequestedAt,
        accountDeletionReason,
        deletedAt,
        kycStatus,
        kycVerifiedAt,
        referralCode,
        referredBy,
        const DeepCollectionEquality().hash(_adminAllowedCountries),
        const DeepCollectionEquality().hash(_adminAllowedSections),
        const DeepCollectionEquality().hash(_gameInterests),
        createdAt,
        updatedAt
      ]);

  /// Create a copy of Profile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProfileImplCopyWith<_$ProfileImpl> get copyWith =>
      __$$ProfileImplCopyWithImpl<_$ProfileImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProfileImplToJson(
      this,
    );
  }
}

abstract class _Profile extends Profile {
  const factory _Profile(
      {required final String id,
      required final String username,
      required final String countryCode,
      final String? email,
      final String avatarColor,
      final String? avatarUrl,
      @UserRoleConverter() final UserRole role,
      final bool isActive,
      final bool permanentBan,
      final String? fcmToken,
      final Map<String, dynamic> stats,
      final String authProvider,
      final String? authProviderId,
      final String? whatsappNumber,
      final String preferredLanguage,
      final String preferredCurrency,
      final String timezone,
      final bool onboardingCompleted,
      final DateTime? onboardingCompletedAt,
      final bool totpEnabled,
      final DateTime? cguAcceptedAt,
      final String? cguVersionAccepted,
      final DateTime? privacyPolicyAcceptedAt,
      final bool marketingConsent,
      final DateTime? accountDeletionRequestedAt,
      final String? accountDeletionReason,
      final DateTime? deletedAt,
      final String kycStatus,
      final DateTime? kycVerifiedAt,
      final String referralCode,
      final String? referredBy,
      final List<String>? adminAllowedCountries,
      final List<String>? adminAllowedSections,
      @GameInterestsConverter() final List<GameType>? gameInterests,
      final DateTime? createdAt,
      final DateTime? updatedAt}) = _$ProfileImpl;
  const _Profile._() : super._();

  factory _Profile.fromJson(Map<String, dynamic> json) = _$ProfileImpl.fromJson;

  @override
  String get id;
  @override
  String get username;
  @override
  String
      get countryCode; // Nullable depuis le fix C-1 résiduel : les lectures cross-user passent
// par la vue `public_profiles` qui n'expose PAS l'email (PII). Non-null
// en pratique pour le profil de l'utilisateur courant (lu sur la table).
  @override
  String? get email;
  @override
  String
      get avatarColor; // Photo d'avatar (bucket Storage `avatars`). NULL → repli cercle coloré
// + initiale via [avatarColor].
  @override
  String? get avatarUrl;
  @override
  @UserRoleConverter()
  UserRole get role;
  @override
  bool get isActive;
  @override
  bool get permanentBan;
  @override
  String? get fcmToken;
  @override
  Map<String, dynamic> get stats;
  @override
  String get authProvider;
  @override
  String? get authProviderId;
  @override
  String? get whatsappNumber;
  @override
  String get preferredLanguage;
  @override
  String get preferredCurrency;
  @override
  String get timezone;
  @override
  bool get onboardingCompleted;
  @override
  DateTime? get onboardingCompletedAt;
  @override
  bool get totpEnabled;
  @override
  DateTime? get cguAcceptedAt;
  @override
  String? get cguVersionAccepted;
  @override
  DateTime? get privacyPolicyAcceptedAt;
  @override
  bool get marketingConsent;
  @override
  DateTime? get accountDeletionRequestedAt;
  @override
  String? get accountDeletionReason;
  @override
  DateTime? get deletedAt;
  @override
  String get kycStatus;
  @override
  DateTime? get kycVerifiedAt; // Lot D — Système de parrainage (item 8).
  @override
  String get referralCode;
  @override
  String?
      get referredBy; // VOLET 3 — périmètre admin restreint (par code d'invitation). NULL ou
// liste vide = aucune restriction (voit tout). Sinon l'admin/super-admin
// est limité aux pays (ISO alpha-2) / sections listés. Propagé par l'EF
// `register-admin` depuis `invitation_codes.allowed_*`.
  @override
  List<String>? get adminAllowedCountries;
  @override
  List<String>?
      get adminAllowedSections; // Sondage « jeux d'intérêt » : jeux dont l'utilisateur veut disputer des
// compétitions. NULL = n'a JAMAIS répondu (nouveau compte → déclenche le
// dialogue obligatoire au 1er démarrage) ; liste (éventuellement vide) =
// a répondu. Écrit une seule fois via le RPC `set_game_interests`.
  @override
  @GameInterestsConverter()
  List<GameType>? get gameInterests;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;

  /// Create a copy of Profile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProfileImplCopyWith<_$ProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
