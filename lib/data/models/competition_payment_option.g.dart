// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'competition_payment_option.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CompetitionPaymentOption _$CompetitionPaymentOptionFromJson(
  Map<String, dynamic> json,
) => _CompetitionPaymentOption(
  id: json['id'] as String,
  competitionId: json['competition_id'] as String,
  countryCode: json['country_code'] as String,
  operatorLabel: json['operator_label'] as String,
  transferCode: json['transfer_code'] as String,
  dialCode: json['dial_code'] as String?,
  paymentNumber: json['payment_number'] as String?,
  collectorId: json['collector_id'] as String?,
  sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  available: json['available'] as bool? ?? true,
);

Map<String, dynamic> _$CompetitionPaymentOptionToJson(
  _CompetitionPaymentOption instance,
) => <String, dynamic>{
  'id': instance.id,
  'competition_id': instance.competitionId,
  'country_code': instance.countryCode,
  'operator_label': instance.operatorLabel,
  'transfer_code': instance.transferCode,
  'dial_code': ?instance.dialCode,
  'payment_number': ?instance.paymentNumber,
  'collector_id': ?instance.collectorId,
  'sort_order': instance.sortOrder,
  'created_at': ?instance.createdAt?.toIso8601String(),
  'available': instance.available,
};
