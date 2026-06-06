// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'arena_match.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ArenaMatchImpl _$$ArenaMatchImplFromJson(Map<String, dynamic> json) =>
    _$ArenaMatchImpl(
      id: json['id'] as String,
      competitionId: json['competition_id'] as String,
      phaseId: json['phase_id'] as String?,
      groupId: json['group_id'] as String?,
      round: (json['round'] as num?)?.toInt(),
      matchNumber: (json['match_number'] as num?)?.toInt(),
      player1Id: json['player1_id'] as String?,
      player2Id: json['player2_id'] as String?,
      score1: (json['score1'] as num?)?.toInt(),
      score2: (json['score2'] as num?)?.toInt(),
      winnerId: json['winner_id'] as String?,
      status: json['status'] == null
          ? MatchStatus.pending
          : const MatchStatusConverter().fromJson(json['status'] as String?),
      homePlayerId: json['home_player_id'] as String?,
      roomCode: json['room_code'] as String?,
      player1TeamName: json['player1_team_name'] as String?,
      player2TeamName: json['player2_team_name'] as String?,
      nextMatchId: json['next_match_id'] as String?,
      isThirdPlace: json['is_third_place'] as bool? ?? false,
      scheduledAt: json['scheduled_at'] == null
          ? null
          : DateTime.parse(json['scheduled_at'] as String),
      startedAt: json['started_at'] == null
          ? null
          : DateTime.parse(json['started_at'] as String),
      finishedAt: json['finished_at'] == null
          ? null
          : DateTime.parse(json['finished_at'] as String),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$ArenaMatchImplToJson(_$ArenaMatchImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'competition_id': instance.competitionId,
      if (instance.phaseId case final value?) 'phase_id': value,
      if (instance.groupId case final value?) 'group_id': value,
      if (instance.round case final value?) 'round': value,
      if (instance.matchNumber case final value?) 'match_number': value,
      if (instance.player1Id case final value?) 'player1_id': value,
      if (instance.player2Id case final value?) 'player2_id': value,
      if (instance.score1 case final value?) 'score1': value,
      if (instance.score2 case final value?) 'score2': value,
      if (instance.winnerId case final value?) 'winner_id': value,
      if (const MatchStatusConverter().toJson(instance.status)
          case final value?)
        'status': value,
      if (instance.homePlayerId case final value?) 'home_player_id': value,
      if (instance.roomCode case final value?) 'room_code': value,
      if (instance.player1TeamName case final value?)
        'player1_team_name': value,
      if (instance.player2TeamName case final value?)
        'player2_team_name': value,
      if (instance.nextMatchId case final value?) 'next_match_id': value,
      'is_third_place': instance.isThirdPlace,
      if (instance.scheduledAt?.toIso8601String() case final value?)
        'scheduled_at': value,
      if (instance.startedAt?.toIso8601String() case final value?)
        'started_at': value,
      if (instance.finishedAt?.toIso8601String() case final value?)
        'finished_at': value,
      if (instance.createdAt?.toIso8601String() case final value?)
        'created_at': value,
      if (instance.updatedAt?.toIso8601String() case final value?)
        'updated_at': value,
    };
