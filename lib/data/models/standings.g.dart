// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'standings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CompetitionGroupImpl _$$CompetitionGroupImplFromJson(
        Map<String, dynamic> json) =>
    _$CompetitionGroupImpl(
      id: json['id'] as String,
      competitionId: json['competition_id'] as String,
      name: json['name'] as String,
      groupNumber: (json['group_number'] as num).toInt(),
    );

Map<String, dynamic> _$$CompetitionGroupImplToJson(
        _$CompetitionGroupImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'competition_id': instance.competitionId,
      'name': instance.name,
      'group_number': instance.groupNumber,
    };

_$GroupStandingRowImpl _$$GroupStandingRowImplFromJson(
        Map<String, dynamic> json) =>
    _$GroupStandingRowImpl(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      profileId: json['profile_id'] as String,
      position: (json['position'] as num?)?.toInt(),
      points: (json['points'] as num?)?.toInt() ?? 0,
      played: (json['played'] as num?)?.toInt() ?? 0,
      wins: (json['wins'] as num?)?.toInt() ?? 0,
      draws: (json['draws'] as num?)?.toInt() ?? 0,
      losses: (json['losses'] as num?)?.toInt() ?? 0,
      goalsFor: (json['goals_for'] as num?)?.toInt() ?? 0,
      goalsAgainst: (json['goals_against'] as num?)?.toInt() ?? 0,
      goalDiff: (json['goal_diff'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$GroupStandingRowImplToJson(
        _$GroupStandingRowImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'group_id': instance.groupId,
      'profile_id': instance.profileId,
      if (instance.position case final value?) 'position': value,
      'points': instance.points,
      'played': instance.played,
      'wins': instance.wins,
      'draws': instance.draws,
      'losses': instance.losses,
      'goals_for': instance.goalsFor,
      'goals_against': instance.goalsAgainst,
      'goal_diff': instance.goalDiff,
    };
