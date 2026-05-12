/// Shared types for the three bracket generators (PHASE 11).
///
/// The generators are pure Dart — they map a player list + tournament
/// settings to a plan of `matches` + `bracket_nodes` rows. The admin
/// repository then inserts the plan; the cascade trigger
/// `cascade_match_winner` already handles winner propagation, so the
/// generators only have to lay out the empty tree correctly.
library;

/// One match row to insert. `playerIds` are seeded for round 1 (or for
/// every match in round-robin), and left empty for later rounds — the
/// trigger fills them in as winners cascade.
class PlannedMatch {
  PlannedMatch({
    required this.roundNumber,
    required this.matchNumber,
    this.player1Id,
    this.player2Id,
    this.groupId,
    this.scheduledAt,
  });

  final int roundNumber;
  final int matchNumber;
  final String? player1Id;
  final String? player2Id;
  final String? groupId;
  final DateTime? scheduledAt;

  Map<String, dynamic> toRow({required String competitionId, String? phaseId}) {
    return <String, dynamic>{
      'competition_id': competitionId,
      if (phaseId != null) 'phase_id': phaseId,
      if (groupId != null) 'group_id': groupId,
      'round': roundNumber,
      'match_number': matchNumber,
      if (player1Id != null) 'player1_id': player1Id,
      if (player2Id != null) 'player2_id': player2Id,
      if (scheduledAt != null) 'scheduled_at': scheduledAt!.toIso8601String(),
      'status': 'pending',
    };
  }
}

/// One bracket_node row. Links to a [PlannedMatch] by index and points
/// to the round-N+1 node by index (resolved to UUIDs at insert time
/// because the rows don't have IDs yet at plan-time).
class PlannedBracketNode {
  PlannedBracketNode({
    required this.roundNumber,
    required this.positionInRound,
    required this.totalRounds,
    required this.matchIndex,
    this.nextNodeIndex,
    this.nextPosition,
    this.isGrandFinal = false,
    this.isThirdPlaceMatch = false,
    this.isBye = false,
    this.byePlayerId,
  });

  final int roundNumber;
  final int positionInRound;
  final int totalRounds;

  /// Index into the matches list. -1 if no match yet (pure bye nodes).
  final int matchIndex;
  final int? nextNodeIndex;
  final String? nextPosition;
  final bool isGrandFinal;
  final bool isThirdPlaceMatch;
  final bool isBye;
  final String? byePlayerId;
}

/// Output of every generator. The repository walks `matches` first,
/// inserts them, then resolves [PlannedBracketNode.matchIndex] /
/// `nextNodeIndex` into real UUIDs before inserting the nodes.
class BracketPlan {
  BracketPlan({required this.matches, required this.nodes});
  final List<PlannedMatch> matches;
  final List<PlannedBracketNode> nodes;
}

class BracketGenerationException implements Exception {
  BracketGenerationException(this.message);
  final String message;

  @override
  String toString() => 'BracketGenerationException: $message';
}
