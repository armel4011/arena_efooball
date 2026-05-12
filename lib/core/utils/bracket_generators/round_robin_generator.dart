import 'package:arena/core/utils/bracket_generators/bracket_generator.dart';

/// Round-robin — every player plays every other player exactly once.
///
/// Uses the circle method: fix player 0, rotate the rest around them.
/// Odd count gets a virtual bye that's filtered out from the emitted
/// matches. Yields N*(N-1)/2 matches in `roundNumber` order so the
/// schedule rotates fairly.
///
/// Round-robin doesn't need `bracket_nodes` — the standings table is
/// the leaderboard. We emit an empty `nodes` list.
BracketPlan generateRoundRobin({
  required List<String> playerIds,
}) {
  if (playerIds.length < 2) {
    throw BracketGenerationException(
      'Need at least 2 players, got ${playerIds.length}.',
    );
  }
  if (playerIds.length > 32) {
    throw BracketGenerationException(
      'Round robin capped at 32 players — heavier counts belong to the '
      'groups+knockout format.',
    );
  }

  // Pad to even with a "bye" sentinel.
  final players = <String?>[...playerIds];
  if (players.length.isOdd) players.add(null);
  final n = players.length;
  final rounds = n - 1;
  final half = n ~/ 2;

  final matches = <PlannedMatch>[];

  // Circle method: position 0 is fixed, the others rotate clockwise.
  final rotation = List<String?>.from(players);

  for (var round = 1; round <= rounds; round++) {
    for (var i = 0; i < half; i++) {
      final a = rotation[i];
      final b = rotation[n - 1 - i];
      if (a == null || b == null) continue; // odd-count bye
      matches.add(PlannedMatch(
        roundNumber: round,
        matchNumber: matches.length + 1,
        player1Id: a,
        player2Id: b,
      ));
    }
    // Rotate everyone except index 0.
    final last = rotation.removeAt(n - 1);
    rotation.insert(1, last);
  }

  return BracketPlan(matches: matches, nodes: const <PlannedBracketNode>[]);
}
