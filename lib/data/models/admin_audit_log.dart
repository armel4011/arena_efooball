import 'package:freezed_annotation/freezed_annotation.dart';

part 'admin_audit_log.freezed.dart';
part 'admin_audit_log.g.dart';

/// Mirror of `public.admin_audit_log` (PHASE 11).
///
/// Every consequential admin action (payout validate/refuse, dispute
/// resolve, user ban, score override, bracket reset, …) lands here so
/// the trail is auditable. Inserted client-side from each admin write
/// for now; PHASE 12.5 will likely move it into Edge Function side-
/// effects for tamper-resistance.
@Freezed(fromJson: true, toJson: true)
sealed class AdminAuditLog with _$AdminAuditLog {
  const factory AdminAuditLog({
    required String id,
    required String adminId,
    required String action,
    String? targetType,
    String? targetId,
    @Default(<String, dynamic>{}) Map<String, dynamic> beforeState,
    @Default(<String, dynamic>{}) Map<String, dynamic> afterState,
    String? ipAddress,
    String? userAgent,
    DateTime? createdAt,
  }) = _AdminAuditLog;

  const AdminAuditLog._();

  factory AdminAuditLog.fromJson(Map<String, dynamic> json) =>
      _$AdminAuditLogFromJson(json);
}
