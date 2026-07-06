import 'package:arena/data/models/user_role.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile.freezed.dart';
part 'profile.g.dart';

/// Mirror of the `profiles` table (subset relevant to client code).
///
/// Snake-case columns are mapped automatically via `fieldRename: snake`.
/// For the `role` column we use a custom converter — Postgres stores
/// `'super_admin'` while Dart's enum value is [UserRole.superAdmin].
@Freezed(fromJson: true, toJson: true)
sealed class Profile with _$Profile {
  const factory Profile({
    required String id,
    required String username,
    required String countryCode,
    // Nullable depuis le fix C-1 résiduel : les lectures cross-user passent
    // par la vue `public_profiles` qui n'expose PAS l'email (PII). Non-null
    // en pratique pour le profil de l'utilisateur courant (lu sur la table).
    String? email,
    @Default('#4C7AFF') String avatarColor,
    // Photo d'avatar (bucket Storage `avatars`). NULL → repli cercle coloré
    // + initiale via [avatarColor].
    String? avatarUrl,
    @Default(UserRole.player) @UserRoleConverter() UserRole role,
    @Default(true) bool isActive,
    @Default(false) bool permanentBan,
    String? fcmToken,
    @Default(<String, dynamic>{}) Map<String, dynamic> stats,
    @Default('email') String authProvider,
    String? authProviderId,
    String? whatsappNumber,
    @Default('fr') String preferredLanguage,
    @Default('XAF') String preferredCurrency,
    @Default('Africa/Douala') String timezone,
    @Default(false) bool onboardingCompleted,
    DateTime? onboardingCompletedAt,
    @Default(false) bool totpEnabled,
    DateTime? cguAcceptedAt,
    String? cguVersionAccepted,
    DateTime? privacyPolicyAcceptedAt,
    @Default(false) bool marketingConsent,
    DateTime? accountDeletionRequestedAt,
    String? accountDeletionReason,
    DateTime? deletedAt,
    @Default('none') String kycStatus,
    DateTime? kycVerifiedAt,
    // Lot D — Système de parrainage (item 8).
    @Default('') String referralCode,
    String? referredBy,
    // VOLET 3 — périmètre admin restreint (par code d'invitation). NULL ou
    // liste vide = aucune restriction (voit tout). Sinon l'admin/super-admin
    // est limité aux pays (ISO alpha-2) / sections listés. Propagé par l'EF
    // `register-admin` depuis `invitation_codes.allowed_*`.
    List<String>? adminAllowedCountries,
    List<String>? adminAllowedSections,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Profile;

  const Profile._();

  factory Profile.fromJson(Map<String, dynamic> json) =>
      _$ProfileFromJson(_normalize(json));

  bool get isPlayer => role == UserRole.player;
  bool get isAdmin => role == UserRole.admin || role == UserRole.superAdmin;
  bool get isSuperAdmin => role == UserRole.superAdmin;

  bool get hasAcceptedCgu => cguAcceptedAt != null;
  bool get isDeleted => deletedAt != null;

  /// Postgres rows include columns we don't model (e.g. `totp_secret`,
  /// `backup_codes`). Strip them so Freezed's generated `fromJson`
  /// doesn't reject the payload.
  static Map<String, dynamic> _normalize(Map<String, dynamic> raw) {
    return Map<String, dynamic>.fromEntries(
      raw.entries.where((e) => !_ignoredKeys.contains(e.key)),
    );
  }

  static const _ignoredKeys = <String>{
    'totp_secret',
    'backup_codes',
  };
}

/// Maps the Postgres string value (e.g. `"super_admin"`) to [UserRole].
class UserRoleConverter implements JsonConverter<UserRole, String?> {
  const UserRoleConverter();

  @override
  UserRole fromJson(String? value) => UserRole.fromValue(value);

  @override
  String toJson(UserRole role) => role.value;
}
