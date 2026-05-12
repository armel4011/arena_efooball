import 'package:freezed_annotation/freezed_annotation.dart';

part 'payout.freezed.dart';
part 'payout.g.dart';

/// Mirror of `public.payouts` (PHASE 11).
///
/// `status`: `pending` → admin validation → `validated` → provider
/// dispatch → `completed` (or `failed`). The provider dispatch step
/// lives in PHASE 11bis / 12.5; until then `validated` is the terminal
/// state on the client side.
///
/// `auto_checks` is a JSONB envelope with KYC, anti-cheat, dispute
/// flags computed at competition close — the UI surfaces it as the
/// "vérifications auto" block on each card.
@Freezed(fromJson: true, toJson: true)
sealed class Payout with _$Payout {
  const factory Payout({
    required String id,
    required String userId,
    required String competitionId,
    String? prizeId,
    @Default(0) double amountUsd,
    @Default(0) double amountLocal,
    @Default('XAF') String currency,
    @Default(1.0) double exchangeRate,
    @Default('pending') String status,
    String? validatedByAdminId,
    DateTime? validatedAt,
    String? validationJustification,
    @Default(<String, dynamic>{}) Map<String, dynamic> autoChecks,
    String? payoutProvider,
    String? payoutMethod,
    @Default(<String, dynamic>{}) Map<String, dynamic> payoutDestination,
    String? providerTransactionId,
    @Default(<String, dynamic>{}) Map<String, dynamic> providerResponse,
    DateTime? scheduledFor,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Payout;

  const Payout._();

  factory Payout.fromJson(Map<String, dynamic> json) =>
      _$PayoutFromJson(json);

  bool get isPending => status == 'pending';
  bool get isValidated => status == 'validated' || status == 'completed';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isRefused => status == 'refused';

  /// True iff every auto check stamped on `auto_checks` is `true`. Missing
  /// keys count as failures so the admin always has the full picture.
  bool get allAutoChecksPassed {
    if (autoChecks.isEmpty) return false;
    return autoChecks.values.every((v) => v == true);
  }
}
