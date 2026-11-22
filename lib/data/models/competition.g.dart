// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'competition.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Competition _$CompetitionFromJson(Map<String, dynamic> json) => _Competition(
  id: json['id'] as String,
  name: json['name'] as String,
  game: const GameTypeConverter().fromJson(json['game'] as String?),
  format: const TournamentFormatConverter().fromJson(json['format'] as String?),
  startDate: DateTime.parse(json['start_date'] as String),
  status: json['status'] == null
      ? CompetitionStatus.draft
      : const CompetitionStatusConverter().fromJson(json['status'] as String?),
  maxPlayers: (json['max_players'] as num?)?.toInt() ?? 2,
  currentPlayers: (json['current_players'] as num?)?.toInt() ?? 0,
  registrationFee: (json['registration_fee'] as num?)?.toDouble() ?? 0,
  registrationCurrency: json['registration_currency'] as String? ?? 'XAF',
  countryCode: json['country_code'] as String? ?? 'CM',
  commissionPct: (json['commission_pct'] as num?)?.toDouble() ?? 10,
  prizePoolLocal: (json['prize_pool_local'] as num?)?.toDouble() ?? 0,
  commissionXaf: (json['commission_xaf'] as num?)?.toDouble() ?? 0,
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
  prizeDistribution:
      (json['prize_distribution'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const <int>[0, 0, 0, 0],
  matchIntervalMinutes: (json['match_interval_minutes'] as num?)?.toInt() ?? 60,
  autoGenerateBracket: json['auto_generate_bracket'] as bool? ?? true,
  thirdPlaceMatch: json['third_place_match'] as bool? ?? false,
  referralQuota: (json['referral_quota'] as num?)?.toInt() ?? 0,
  referralActivityMode: json['referral_activity_mode'] as String? ?? 'any',
  roundIntervals: (json['round_intervals'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
  formatConfig:
      json['format_config'] as Map<String, dynamic>? ??
      const <String, dynamic>{},
  androidStoreUrl: json['android_store_url'] as String?,
  iosStoreUrl: json['ios_store_url'] as String?,
  lastBracketError: json['last_bracket_error'] as String?,
  lastBracketErrorAt: json['last_bracket_error_at'] == null
      ? null
      : DateTime.parse(json['last_bracket_error_at'] as String),
  isPinned: json['is_pinned'] as bool? ?? false,
  pinnedAt: json['pinned_at'] == null
      ? null
      : DateTime.parse(json['pinned_at'] as String),
  completedAt: json['completed_at'] == null
      ? null
      : DateTime.parse(json['completed_at'] as String),
  archivedAt: json['archived_at'] == null
      ? null
      : DateTime.parse(json['archived_at'] as String),
);

Map<String, dynamic> _$CompetitionToJson(
  _Competition instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'game': ?const GameTypeConverter().toJson(instance.game),
  'format': ?const TournamentFormatConverter().toJson(instance.format),
  'start_date': instance.startDate.toIso8601String(),
  'status': ?const CompetitionStatusConverter().toJson(instance.status),
  'max_players': instance.maxPlayers,
  'current_players': instance.currentPlayers,
  'registration_fee': instance.registrationFee,
  'registration_currency': instance.registrationCurrency,
  'country_code': instance.countryCode,
  'commission_pct': instance.commissionPct,
  'prize_pool_local': instance.prizePoolLocal,
  'commission_xaf': instance.commissionXaf,
  'sponsor_bonus_local': instance.sponsorBonusLocal,
  'description': ?instance.description,
  'banner_url': ?instance.bannerUrl,
  'registration_opens_at': ?instance.registrationOpensAt?.toIso8601String(),
  'registration_closes_at': ?instance.registrationClosesAt?.toIso8601String(),
  'end_date': ?instance.endDate?.toIso8601String(),
  'prize_pool_currency': ?instance.prizePoolCurrency,
  'created_by': ?instance.createdBy,
  'created_at': ?instance.createdAt?.toIso8601String(),
  'updated_at': ?instance.updatedAt?.toIso8601String(),
  'orange_money_code': ?instance.orangeMoneyCode,
  'mtn_momo_code': ?instance.mtnMomoCode,
  'prize_distribution': instance.prizeDistribution,
  'match_interval_minutes': instance.matchIntervalMinutes,
  'auto_generate_bracket': instance.autoGenerateBracket,
  'third_place_match': instance.thirdPlaceMatch,
  'referral_quota': instance.referralQuota,
  'referral_activity_mode': instance.referralActivityMode,
  'round_intervals': ?instance.roundIntervals,
  'format_config': instance.formatConfig,
  'android_store_url': ?instance.androidStoreUrl,
  'ios_store_url': ?instance.iosStoreUrl,
  'last_bracket_error': ?instance.lastBracketError,
  'last_bracket_error_at': ?instance.lastBracketErrorAt?.toIso8601String(),
  'is_pinned': instance.isPinned,
  'pinned_at': ?instance.pinnedAt?.toIso8601String(),
  'completed_at': ?instance.completedAt?.toIso8601String(),
  'archived_at': ?instance.archivedAt?.toIso8601String(),
};
