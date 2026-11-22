// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bracket_node.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BracketNode _$BracketNodeFromJson(Map<String, dynamic> json) => _BracketNode(
  id: json['id'] as String,
  phaseId: json['phase_id'] as String,
  competitionId: json['competition_id'] as String,
  roundNumber: (json['round_number'] as num).toInt(),
  positionInRound: (json['position_in_round'] as num).toInt(),
  totalRounds: (json['total_rounds'] as num).toInt(),
  matchId: json['match_id'] as String?,
  nextNodeId: json['next_node_id'] as String?,
  parentNodeId: json['parent_node_id'] as String?,
  nextPosition: json['next_position'] as String?,
  isGrandFinal: json['is_grand_final'] as bool? ?? false,
  isThirdPlaceMatch: json['is_third_place_match'] as bool? ?? false,
  isBye: json['is_bye'] as bool? ?? false,
  byePlayerId: json['bye_player_id'] as String?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$BracketNodeToJson(_BracketNode instance) =>
    <String, dynamic>{
      'id': instance.id,
      'phase_id': instance.phaseId,
      'competition_id': instance.competitionId,
      'round_number': instance.roundNumber,
      'position_in_round': instance.positionInRound,
      'total_rounds': instance.totalRounds,
      'match_id': ?instance.matchId,
      'next_node_id': ?instance.nextNodeId,
      'parent_node_id': ?instance.parentNodeId,
      'next_position': ?instance.nextPosition,
      'is_grand_final': instance.isGrandFinal,
      'is_third_place_match': instance.isThirdPlaceMatch,
      'is_bye': instance.isBye,
      'bye_player_id': ?instance.byePlayerId,
      'created_at': ?instance.createdAt?.toIso8601String(),
    };
