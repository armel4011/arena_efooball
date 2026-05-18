// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'competition.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CompetitionImpl _$$CompetitionImplFromJson(Map<String, dynamic> json) =>
    _$CompetitionImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      game: const GameTypeConverter().fromJson(json['game'] as String?),
      format:
          const TournamentFormatConverter().fromJson(json['format'] as String?),
      startDate: DateTime.parse(json['start_date'] as String),
      status: json['status'] == null
          ? CompetitionStatus.draft
          : const CompetitionStatusConverter()
              .fromJson(json['status'] as String?),
      maxPlayers: (json['max_players'] as num?)?.toInt() ?? 2,
      currentPlayers: (json['current_players'] as num?)?.toInt() ?? 0,
      registrationFee: (json['registration_fee'] as num?)?.toDouble() ?? 0,
      registrationCurrency: json['registration_currency'] as String? ?? 'XAF',
      commissionPct: (json['commission_pct'] as num?)?.toDouble() ?? 10,
      prizePoolLocal: (json['prize_pool_local'] as num?)?.toDouble() ?? 0,
      sponsorBonusLocal: (json['sponsor_bonus_local'] as num?)?.toDouble() ?? 0,
      description: json['description'] as String?,
      bannerUrl: json['banner_url'] as String?,
      registrationOpensAt: json['registration_opens_at'] == null
          ? null
          : DateTime.parse(json['registration_opens_at'] as String),
      registrationClosesAt: json['registration_closes_at'] == null
          ? null
          : DateTime.parse(json['registration_closes_at'] as String),
      endDate: json['end_date'] == null
          ? null
          : DateTime.parse(json['end_date'] as String),
      prizePoolCurrency: json['prize_pool_currency'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      orangeMoneyCode: json['orange_money_code'] as String?,
      mtnMomoCode: json['mtn_momo_code'] as String?,
      prizeDistribution: (json['prize_distribution'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const <int>[0, 0, 0, 0],
      matchIntervalMinutes:
          (json['match_interval_minutes'] as num?)?.toInt() ?? 60,
      autoGenerateBracket: json['auto_generate_bracket'] as bool? ?? true,
    );

Map<String, dynamic> _$$CompetitionImplToJson(_$CompetitionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      if (const GameTypeConverter().toJson(instance.game) case final value?)
        'game': value,
      if (const TournamentFormatConverter().toJson(instance.format)
          case final value?)
        'format': value,
      'start_date': instance.startDate.toIso8601String(),
      if (const CompetitionStatusConverter().toJson(instance.status)
          case final value?)
        'status': value,
      'max_players': instance.maxPlayers,
      'current_players': instance.currentPlayers,
      'registration_fee': instance.registrationFee,
      'registration_currency': instance.registrationCurrency,
      'commission_pct': instance.commissionPct,
      'prize_pool_local': instance.prizePoolLocal,
      'sponsor_bonus_local': instance.sponsorBonusLocal,
      if (instance.description case final value?) 'description': value,
      if (instance.bannerUrl case final value?) 'banner_url': value,
      if (instance.registrationOpensAt?.toIso8601String() case final value?)
        'registration_opens_at': value,
      if (instance.registrationClosesAt?.toIso8601String() case final value?)
        'registration_closes_at': value,
      if (instance.endDate?.toIso8601String() case final value?)
        'end_date': value,
      if (instance.prizePoolCurrency case final value?)
        'prize_pool_currency': value,
      if (instance.createdBy case final value?) 'created_by': value,
      if (instance.createdAt?.toIso8601String() case final value?)
        'created_at': value,
      if (instance.updatedAt?.toIso8601String() case final value?)
        'updated_at': value,
      if (instance.orangeMoneyCode case final value?)
        'orange_money_code': value,
      if (instance.mtnMomoCode case final value?) 'mtn_momo_code': value,
      'prize_distribution': instance.prizeDistribution,
      'match_interval_minutes': instance.matchIntervalMinutes,
      'auto_generate_bracket': instance.autoGenerateBracket,
    };
