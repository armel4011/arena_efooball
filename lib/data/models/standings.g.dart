// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'standings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CompetitionGroup _$CompetitionGroupFromJson(Map<String, dynamic> json) =>
    _CompetitionGroup(
      id: json['id'] as String,
      competitionId: json['competition_id'] as String,
      name: json['name'] as String,
      groupNumber: (json['group_number'] as num).toInt(),
    );

Map<String, dynamic> _$CompetitionGroupToJson(_CompetitionGroup instance) =>
    <String, dynamic>{
      'id': instance.id,
      'competition_id': instance.competitionId,
      'name': instance.name,
      'group_number': instance.groupNumber,
    };

_GroupStandingRow _$GroupStandingRowFromJson(Map<String, dynamic> json) =>
    _GroupStandingRow(
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

Map<String, dynamic> _$GroupStandingRowToJson(_GroupStandingRow instance) =>
    <String, dynamic>{
      'id': instance.id,
      'group_id': instance.groupId,
      'profile_id': instance.profileId,
      'position': ?instance.position,
      'points': instance.points,
      'played': instance.played,
      'wins': instance.wins,
      'draws': instance.draws,
      'losses': instance.losses,
      'goals_for': instance.goalsFor,
      'goals_against': instance.goalsAgainst,
      'goal_diff': instance.goalDiff,
    };
