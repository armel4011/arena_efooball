import 'dart:math';

import 'package:arena/core/utils/bracket_generators/bracket_generator.dart';
import 'package:arena/core/utils/bracket_generators/single_elimination_generator.dart';

/// Plan for a groups-then-knockout tournament.
///
/// Unlike the other two generators this one needs two passes: the
/// group rows must be inserted first (so we know their UUIDs), the
/// admin repo wires the group_id back on each match, and then once the
/// group standings are settled, the qualifiers seed a single-elim
/// knockout phase. We can plan both phases up front though — the KO
/// phase just has empty player slots until the standings are computed
/// at the end of the group stage.
class GroupsKnockoutPlan {
  GroupsKnockoutPlan({
    required this.groups,
    required this.groupMatches,
    required this.knockoutPlan,
  });

  /// One label per group ("A", "B", …) so the caller can INSERT into
  /// `groups` before resolving group_id back on each match.
  final List<String> groups;

  /// Round-robin matches per group, in the order returned. The caller
  /// must associate `groupMatches[groupIndex][i]` with `groups[groupIndex]`'s
  /// UUID before insert.
  final List<List<PlannedMatch>> groupMatches;

  /// KO bracket plan with placeholder player IDs — the admin advances
  /// the qualifiers once the group stage closes.
  final BracketPlan knockoutPlan;
}

/// Groups + knockout phase.
///
/// Splits the players into [groupCount] groups, each playing a
/// round-robin. The top [qualifiersPerGroup] from every group advance
/// to a single-elim KO. The KO plan starts with null slots — the admin
/// runs `advanceQualifiers` once the group stage is closed.
GroupsKnockoutPlan generateGroupsThenKnockout({
  required List<String> playerIds,
  required int groupCount,
  required int qualifiersPerGroup,
  bool shuffle = true,
  int? seed,
}) {
  if (groupCount < 2) {
    throw BracketGenerationException('Need at least 2 groups.');
  }
  if (qualifiersPerGroup < 1) {
    throw BracketGenerationException(
      'Need at least 1 qualifier per group.',
    );
  }
  if (playerIds.length < groupCount * 2) {
    throw BracketGenerationException(
      'Need at least $groupCount × 2 = ${groupCount * 2} players, got '
      '${playerIds.length}.',
    );
  }

  final players = [...playerIds];
  if (shuffle) {
    final rng = seed != null ? Random(seed) : Random();
    players.shuffle(rng);
  }

  // Snake-draft distribute players into groups so the strongest seeds
  // don't end up in the same group.
  final groupAssignments = List.generate(groupCount, (_) => <String>[]);
  for (var i = 0; i < players.length; i++) {
    final row = i ~/ groupCount;
    final col =
        row.isEven ? i % groupCount : groupCount - 1 - (i % groupCount);
    groupAssignments[col].add(players[i]);
  }

  final groupLabels = List.generate(
    groupCount,
    (i) => String.fromCharCode('A'.codeUnitAt(0) + i),
  );

  // Round-robin within each group. We delegate to the round-robin
  // generator and just rebase round + match numbers per group so the
  // sequence makes sense end-to-end.
  final groupMatches = <List<PlannedMatch>>[];
  for (final group in groupAssignments) {
    final inner = _roundRobinMatches(group);
    groupMatches.add(inner);
  }

  // KO phase: empty single-elim bracket sized for `qualifiers * groups`.
  final qualifierCount = groupCount * qualifiersPerGroup;
  final placeholders = List<String>.generate(
    qualifierCount,
    (i) => 'placeholder_${i.toString().padLeft(2, '0')}',
  );
  final knockoutPlan = generateSingleElimination(
    playerIds: placeholders,
    shuffle: false,
  );

  // Wipe out the placeholder IDs so the admin can fill them in after
  // the group stage closes. The match rows stay (so the bracket UI has
  // empty slots to render) but players are null.
  final cleanedMatches = knockoutPlan.matches.map((m) {
    if (m.roundNumber != 1) return m;
    return PlannedMatch(
      roundNumber: m.roundNumber,
      matchNumber: m.matchNumber,
    );
  }).toList();

  return GroupsKnockoutPlan(
    groups: groupLabels,
    groupMatches: groupMatches,
    knockoutPlan: BracketPlan(
      matches: cleanedMatches,
      nodes: knockoutPlan.nodes,
    ),
  );
}

/// Inlined round-robin so we keep the round / matchNumber numbering
/// local to each group.
List<PlannedMatch> _roundRobinMatches(List<String> players) {
  if (players.length < 2) return const <PlannedMatch>[];

  final padded = <String?>[...players];
  if (padded.length.isOdd) padded.add(null);
  final n = padded.length;
  final rounds = n - 1;
  final half = n ~/ 2;
  final rotation = List<String?>.from(padded);

  final out = <PlannedMatch>[];
  for (var round = 1; round <= rounds; round++) {
    for (var i = 0; i < half; i++) {
      final a = rotation[i];
      final b = rotation[n - 1 - i];
      if (a == null || b == null) continue;
      out.add(PlannedMatch(
        roundNumber: round,
        matchNumber: out.length + 1,
        player1Id: a,
        player2Id: b,
      ),);
    }
    final last = rotation.removeAt(n - 1);
    rotation.insert(1, last);
  }
  return out;
}
