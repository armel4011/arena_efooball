// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payout.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Payout _$PayoutFromJson(Map<String, dynamic> json) => _Payout(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  competitionId: json['competition_id'] as String,
  prizeId: json['prize_id'] as String?,
  amountUsd: (json['amount_usd'] as num?)?.toDouble() ?? 0,
  amountLocal: (json['amount_local'] as num?)?.toDouble() ?? 0,
  currency: json['currency'] as String? ?? 'XAF',
  exchangeRate: (json['exchange_rate'] as num?)?.toDouble() ?? 1.0,
  status: json['status'] as String? ?? 'pending',
  validatedByAdminId: json['validated_by_admin_id'] as String?,
  validatedAt: json['validated_at'] == null
      ? null
      : DateTime.parse(json['validated_at'] as String),
  validationJustification: json['validation_justification'] as String?,
  autoChecks:
      json['auto_checks'] as Map<String, dynamic>? ?? const <String, dynamic>{},
  payoutProvider: json['payout_provider'] as String?,
  payoutMethod: json['payout_method'] as String?,
  payoutDestination:
      json['payout_destination'] as Map<String, dynamic>? ??
      const <String, dynamic>{},
  providerTransactionId: json['provider_transaction_id'] as String?,
  providerResponse:
      json['provider_response'] as Map<String, dynamic>? ??
      const <String, dynamic>{},
  scheduledFor: json['scheduled_for'] == null
      ? null
      : DateTime.parse(json['scheduled_for'] as String),
  completedAt: json['completed_at'] == null
      ? null
      : DateTime.parse(json['completed_at'] as String),
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$PayoutToJson(_Payout instance) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'competition_id': instance.competitionId,
  'prize_id': ?instance.prizeId,
  'amount_usd': instance.amountUsd,
  'amount_local': instance.amountLocal,
  'currency': instance.currency,
  'exchange_rate': instance.exchangeRate,
  'status': instance.status,
  'validated_by_admin_id': ?instance.validatedByAdminId,
  'validated_at': ?instance.validatedAt?.toIso8601String(),
  'validation_justification': ?instance.validationJustification,
  'auto_checks': instance.autoChecks,
  'payout_provider': ?instance.payoutProvider,
  'payout_method': ?instance.payoutMethod,
  'payout_destination': instance.payoutDestination,
  'provider_transaction_id': ?instance.providerTransactionId,
  'provider_response': instance.providerResponse,
  'scheduled_for': ?instance.scheduledFor?.toIso8601String(),
  'completed_at': ?instance.completedAt?.toIso8601String(),
  'created_at': ?instance.createdAt?.toIso8601String(),
  'updated_at': ?instance.updatedAt?.toIso8601String(),
};
