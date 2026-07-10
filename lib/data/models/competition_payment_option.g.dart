// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'competition_payment_option.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CompetitionPaymentOptionImpl _$$CompetitionPaymentOptionImplFromJson(
        Map<String, dynamic> json) =>
    _$CompetitionPaymentOptionImpl(
      id: json['id'] as String,
      competitionId: json['competition_id'] as String,
      countryCode: json['country_code'] as String,
      operatorLabel: json['operator_label'] as String,
      transferCode: json['transfer_code'] as String,
      dialCode: json['dial_code'] as String?,
      paymentNumber: json['payment_number'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$CompetitionPaymentOptionImplToJson(
        _$CompetitionPaymentOptionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'competition_id': instance.competitionId,
      'country_code': instance.countryCode,
      'operator_label': instance.operatorLabel,
      'transfer_code': instance.transferCode,
      if (instance.dialCode case final value?) 'dial_code': value,
      if (instance.paymentNumber case final value?) 'payment_number': value,
      'sort_order': instance.sortOrder,
      if (instance.createdAt?.toIso8601String() case final value?)
        'created_at': value,
    };
