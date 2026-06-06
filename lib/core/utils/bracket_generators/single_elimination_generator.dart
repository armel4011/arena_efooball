import 'dart:math';

import 'package:arena/core/utils/bracket_generators/bracket_generator.dart';

/// Single-elimination bracket.
///
/// Players are seeded (Fisher-Yates shuffle by default) and dropped
/// into round 1. If the count isn't a power of two, the highest seeds
/// get byes into round 2. Subsequent rounds are emitted with empty
/// player slots — the DB trigger `cascade_match_winner` fills them in
/// as winners advance.
///
/// Yields N-1 matches (N = nextPowerOfTwo). Throws if fewer than 2
/// players or more than 256 (matches the master prompt cap).
///
/// Si [thirdPlace] est vrai ET qu'il y a au moins des demi-finales
/// (totalRounds >= 2, soit >= 4 slots), un match de classement
/// supplémentaire est ajouté : il oppose les 2 perdants des demi-finales
/// (câblés via `loserNextNodeIndex`). En dessous de 4 joueurs (pas de
/// vraies demi-finales) le flag est ignoré.
BracketPlan generateSingleElimination({
  required List<String> playerIds,
  bool shuffle = true,
  bool thirdPlace = false,
  int? seed,
}) {
  if (playerIds.length < 2) {
    throw BracketGenerationException(
      'Need at least 2 players, got ${playerIds.length}.',
    );
  }
  if (playerIds.length > 256) {
    throw BracketGenerationException(
      'Single elimination capped at 256 players.',
    );
  }

  final players = [...playerIds];
  if (shuffle) {
    final rng = seed != null ? Random(seed) : Random();
    players.shuffle(rng);
  }

  final size = _nextPowerOfTwo(players.length);
  final totalRounds = (log(size) / log(2)).round();
  final byes = size - players.length;

  // Slots in round 1 — last `byes` slots are nulls (auto-advance).
  final round1Players = <String?>[
    ...players,
    for (var i = 0; i < byes; i++) null,
  ];

  final matches = <PlannedMatch>[];
  final nodes = <PlannedBracketNode>[];

  // Per round: how many matches and an offset into `nodes`.
  final roundNodeOffsets = <int>[];
  var nodeCursor = 0;

  for (var round = 1; round <= totalRounds; round++) {
    final matchesThisRound = size >> round;
    roundNodeOffsets.add(nodeCursor);

    for (var pos = 0; pos < matchesThisRound; pos++) {
      String? p1;
      String? p2;
      if (round == 1) {
        p1 = round1Players[pos * 2];
        p2 = round1Players[pos * 2 + 1];
      }

      // A round-1 match with one null = bye: the lone player auto-
      // advances. We still create the match row (status will be
      // `forfeited` once we insert) so the bracket UI shows the slot.
      final isAutoBye = round == 1 && (p1 == null || p2 == null);
      final lonePlayer = p1 ?? p2;

      matches.add(PlannedMatch(
        roundNumber: round,
        matchNumber: matches.length + 1,
        player1Id: p1,
        player2Id: p2,
      ),);

      // Round R node points to round R+1's node at `pos ~/ 2`.
      int? nextNodeIndex;
      String? nextPosition;
      if (round < totalRounds) {
        final nextStart = nodeCursor + matchesThisRound;
        nextNodeIndex = nextStart + (pos ~/ 2);
        nextPosition = pos.isEven ? 'player1' : 'player2';
      }

      nodes.add(PlannedBracketNode(
        roundNumber: round,
        positionInRound: pos,
        totalRounds: totalRounds,
        matchIndex: matches.length - 1,
        nextNodeIndex: nextNodeIndex,
        nextPosition: nextPosition,
        isGrandFinal: round == totalRounds,
        isBye: isAutoBye,
        byePlayerId: isAutoBye ? lonePlayer : null,
      ),);
    }
    nodeCursor += matchesThisRound;
  }

  // ─── Match de classement (3e place) ──────────────────────────────────
  // Ajouté seulement s'il existe 2 VRAIES demi-finales : il faut au moins
  // 4 joueurs réels (totalRounds >= 2 ne suffit pas — 3 joueurs donnent un
  // field de 4 mais une seule demi réelle, l'autre étant un bye). Le match
  // 3e place occupe `positionInRound: 1` du round final (la finale reste à
  // la position 0) ; les 2 demi-finales (round totalRounds-1) routent leur
  // PERDANT vers ce nœud.
  if (thirdPlace && totalRounds >= 2 && players.length >= 4) {
    final thirdPlaceMatchIndex = matches.length;
    matches.add(PlannedMatch(
      roundNumber: totalRounds,
      matchNumber: matches.length + 1,
      isThirdPlace: true,
    ),);

    final thirdPlaceNodeIndex = nodes.length;
    nodes.add(PlannedBracketNode(
      roundNumber: totalRounds,
      positionInRound: 1,
      totalRounds: totalRounds,
      matchIndex: thirdPlaceMatchIndex,
      isThirdPlaceMatch: true,
    ),);

    // Câble les 2 demi-finales (positions 0 et 1 du round totalRounds-1)
    // vers le match 3e place. Les champs étant `final`, on remplace les
    // nœuds en place par des copies enrichies.
    for (var i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      if (node.roundNumber != totalRounds - 1) continue;
      nodes[i] = PlannedBracketNode(
        roundNumber: node.roundNumber,
        positionInRound: node.positionInRound,
        totalRounds: node.totalRounds,
        matchIndex: node.matchIndex,
        nextNodeIndex: node.nextNodeIndex,
        nextPosition: node.nextPosition,
        loserNextNodeIndex: thirdPlaceNodeIndex,
        loserNextPosition: node.positionInRound == 0 ? 'player1' : 'player2',
        isGrandFinal: node.isGrandFinal,
        isThirdPlaceMatch: node.isThirdPlaceMatch,
        isBye: node.isBye,
        byePlayerId: node.byePlayerId,
      );
    }
  }

  return BracketPlan(matches: matches, nodes: nodes);
}

int _nextPowerOfTwo(int n) {
  var p = 1;
  while (p < n) {
    p <<= 1;
  }
  return p;
}
