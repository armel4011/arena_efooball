// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payout.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PayoutImpl _$$PayoutImplFromJson(Map<String, dynamic> json) => _$PayoutImpl(
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
      autoChecks: json['auto_checks'] as Map<String, dynamic>? ??
          const <String, dynamic>{},
      payoutProvider: json['payout_provider'] as String?,
      payoutMethod: json['payout_method'] as String?,
      payoutDestination: json['payout_destination'] as Map<String, dynamic>? ??
          const <String, dynamic>{},
      providerTransactionId: json['provider_transaction_id'] as String?,
      providerResponse: json['provider_response'] as Map<String, dynamic>? ??
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

Map<String, dynamic> _$$PayoutImplToJson(_$PayoutImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'competition_id': instance.competitionId,
      if (instance.prizeId case final value?) 'prize_id': value,
      'amount_usd': instance.amountUsd,
      'amount_local': instance.amountLocal,
      'currency': instance.currency,
      'exchange_rate': instance.exchangeRate,
      'status': instance.status,
      if (instance.validatedByAdminId case final value?)
        'validated_by_admin_id': value,
      if (instance.validatedAt?.toIso8601String() case final value?)
        'validated_at': value,
      if (instance.validationJustification case final value?)
        'validation_justification': value,
      'auto_checks': instance.autoChecks,
      if (instance.payoutProvider case final value?) 'payout_provider': value,
      if (instance.payoutMethod case final value?) 'payout_method': value,
      'payout_destination': instance.payoutDestination,
      if (instance.providerTransactionId case final value?)
        'provider_transaction_id': value,
      'provider_response': instance.providerResponse,
      if (instance.scheduledFor?.toIso8601String() case final value?)
        'scheduled_for': value,
      if (instance.completedAt?.toIso8601String() case final value?)
        'completed_at': value,
      if (instance.createdAt?.toIso8601String() case final value?)
        'created_at': value,
      if (instance.updatedAt?.toIso8601String() case final value?)
        'updated_at': value,
    };
