import 'package:freezed_annotation/freezed_annotation.dart';

part 'bracket_node.freezed.dart';
part 'bracket_node.g.dart';

/// Mirror of `public.bracket_nodes` (PHASE 11).
///
/// Each node represents one slot in the elimination tree. The match
/// itself lives in `matches.id` referenced by `match_id`; once a winner
/// is set, the trigger `cascade_match_winner` plants them into
/// `next_node_id` at position `next_position`.
@Freezed(fromJson: true, toJson: true)
sealed class BracketNode with _$BracketNode {
  const factory BracketNode({
    required String id,
    required String phaseId,
    required String competitionId,
    required int roundNumber,
    required int positionInRound,
    required int totalRounds,
    String? matchId,
    String? nextNodeId,
    String? parentNodeId,
    String? nextPosition,
    @Default(false) bool isGrandFinal,
    @Default(false) bool isThirdPlaceMatch,
    @Default(false) bool isBye,
    String? byePlayerId,
    DateTime? createdAt,
  }) = _BracketNode;

  factory BracketNode.fromJson(Map<String, dynamic> json) =>
      _$BracketNodeFromJson(json);
}
