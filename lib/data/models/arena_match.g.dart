// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'arena_match.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ArenaMatch _$ArenaMatchFromJson(Map<String, dynamic> json) => _ArenaMatch(
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
  player1Ready: json['player1_ready'] as bool? ?? false,
  player2Ready: json['player2_ready'] as bool? ?? false,
  nextMatchId: json['next_match_id'] as String?,
  isThirdPlace: json['is_third_place'] as bool? ?? false,
  isStreamed: json['is_streamed'] as bool? ?? false,
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

Map<String, dynamic> _$ArenaMatchToJson(_ArenaMatch instance) =>
    <String, dynamic>{
      'id': instance.id,
      'competition_id': instance.competitionId,
      'phase_id': ?instance.phaseId,
      'group_id': ?instance.groupId,
      'round': ?instance.round,
      'match_number': ?instance.matchNumber,
      'player1_id': ?instance.player1Id,
      'player2_id': ?instance.player2Id,
      'score1': ?instance.score1,
      'score2': ?instance.score2,
      'winner_id': ?instance.winnerId,
      'status': ?const MatchStatusConverter().toJson(instance.status),
      'home_player_id': ?instance.homePlayerId,
      'room_code': ?instance.roomCode,
      'player1_team_name': ?instance.player1TeamName,
      'player2_team_name': ?instance.player2TeamName,
      'player1_ready': instance.player1Ready,
      'player2_ready': instance.player2Ready,
      'next_match_id': ?instance.nextMatchId,
      'is_third_place': instance.isThirdPlace,
      'is_streamed': instance.isStreamed,
      'scheduled_at': ?instance.scheduledAt?.toIso8601String(),
      'started_at': ?instance.startedAt?.toIso8601String(),
      'finished_at': ?instance.finishedAt?.toIso8601String(),
      'created_at': ?instance.createdAt?.toIso8601String(),
      'updated_at': ?instance.updatedAt?.toIso8601String(),
    };
