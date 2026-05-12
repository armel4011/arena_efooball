import 'package:freezed_annotation/freezed_annotation.dart';

part 'dispute.freezed.dart';
part 'dispute.g.dart';

/// Mirror of `public.disputes` (PHASE 11).
///
/// `status` is a free-form string: `open`, `bot_review`, `escalated`,
/// `resolved`, `cancelled`. `resolution` carries the admin's written
/// verdict on close, and `evidence` is a JSONB envelope the bot fills
/// with score votes, replay metadata, chat snippets, etc.
@Freezed(fromJson: true, toJson: true)
sealed class Dispute with _$Dispute {
  const factory Dispute({
    required String id,
    required String matchId,
    required String openedBy,
    @Default('open') String status,
    String? reason,
    @Default(<String, dynamic>{}) Map<String, dynamic> evidence,
    @Default(0) int escalationLevel,
    DateTime? botAttemptedAt,
    DateTime? escalatedAt,
    DateTime? resolvedAt,
    String? resolvedBy,
    String? resolution,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Dispute;

  const Dispute._();

  factory Dispute.fromJson(Map<String, dynamic> json) =>
      _$DisputeFromJson(json);

  bool get isOpen => status == 'open' || status == 'escalated';
  bool get isResolved => status == 'resolved' || status == 'cancelled';
}
