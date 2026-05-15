import 'package:freezed_annotation/freezed_annotation.dart';

part 'reintegration_request.freezed.dart';
part 'reintegration_request.g.dart';

/// Mirror of `public.reintegration_requests` (Phase 12.6).
///
/// Canal "Arena Requête" : un utilisateur banni à vie par la règle
/// 3-strikes peut soumettre une requête de réintégration, analysée par
/// le super-admin sous 48h (SLA indicatif).
@Freezed(fromJson: true, toJson: true)
sealed class ReintegrationRequest with _$ReintegrationRequest {
  const factory ReintegrationRequest({
    required String id,
    required String userId,
    required String message,
    @Default('pending') String status, // pending | approved | rejected
    DateTime? createdAt,
    DateTime? resolvedAt,
    String? resolvedBy,
    String? resolutionReason,
    DateTime? updatedAt,
  }) = _ReintegrationRequest;

  const ReintegrationRequest._();

  factory ReintegrationRequest.fromJson(Map<String, dynamic> json) =>
      _$ReintegrationRequestFromJson(json);

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  /// `true` quand la requête est ouverte depuis plus de 48h (SLA Arena
  /// Requête dépassé). Indicatif uniquement — pas d'auto-décision.
  bool get isOverdue {
    if (!isPending || createdAt == null) return false;
    return DateTime.now().toUtc().difference(createdAt!.toUtc()) >
        const Duration(hours: 48);
  }
}
