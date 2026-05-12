import 'package:arena/data/models/profile.dart';
import 'package:arena/data/models/user_role.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'invitation_code.freezed.dart';
part 'invitation_code.g.dart';

/// Mirror of `public.invitation_codes` (PHASE 11 super-admin).
///
/// The super-admin generates a code with a target role + optional email
/// (binds the code to one address) + expiration. A redeemed code stamps
/// `used_at` and `used_by`. The actual redeem flow + role grant is done
/// by an Edge Function (`register_admin`) — PHASE 12.5.
@Freezed(fromJson: true, toJson: true)
sealed class InvitationCode with _$InvitationCode {
  const factory InvitationCode({
    required String id,
    required String code,
    @UserRoleConverter() @Default(UserRole.admin) UserRole role,
    String? generatedBy,
    String? targetEmail,
    DateTime? expiresAt,
    @Default(1) int maxUses,
    @Default(0) int usesCount,
    DateTime? usedAt,
    String? usedBy,
    DateTime? createdAt,
  }) = _InvitationCode;

  const InvitationCode._();

  factory InvitationCode.fromJson(Map<String, dynamic> json) =>
      _$InvitationCodeFromJson(json);

  bool get isActive {
    if (usedAt != null && usesCount >= maxUses) return false;
    final exp = expiresAt;
    if (exp != null && DateTime.now().isAfter(exp)) return false;
    return true;
  }

  bool get isUsed => usesCount > 0 || usedAt != null;
}
