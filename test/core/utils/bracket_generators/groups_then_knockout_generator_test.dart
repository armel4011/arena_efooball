import 'package:arena/core/utils/bracket_generators/bracket_generator.dart';
import 'package:arena/core/utils/bracket_generators/groups_then_knockout_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('generateGroupsThenKnockout', () {
    List<String> players(int n) =>
        List.generate(n, (i) => 'p${i.toString().padLeft(2, '0')}');

    Set<String> groupRoster(List<PlannedMatch> matches) {
      final ids = <String>{};
      for (final m in matches) {
        if (m.player1Id != null) ids.add(m.player1Id!);
        if (m.player2Id != null) ids.add(m.player2Id!);
      }
      return ids;
    }

    test('throws with fewer than 2 groups', () {
      expect(
        () => generateGroupsThenKnockout(
          playerIds: players(8),
          groupCount: 1,
          qualifiersPerGroup: 2,
        ),
        throwsA(isA<BracketGenerationException>()),
      );
    });

    test('throws with no qualifier per group', () {
      expect(
        () => generateGroupsThenKnockout(
          playerIds: players(8),
          groupCount: 2,
          qualifiersPerGroup: 0,
        ),
        throwsA(isA<BracketGenerationException>()),
      );
    });

    test('throws when too few players to fill groupCount x 2', () {
      expect(
        () => generateGroupsThenKnockout(
          playerIds: players(3),
          groupCount: 2,
          qualifiersPerGroup: 1,
        ),
        throwsA(isA<BracketGenerationException>()),
      );
    });

    test('labels groups A, B, C…', () {
      final plan = generateGroupsThenKnockout(
        playerIds: players(12),
        groupCount: 3,
        qualifiersPerGroup: 2,
        shuffle: false,
      );
      expect(plan.groups, ['A', 'B', 'C']);
      expect(plan.groupMatches.length, 3);
    });

    test('snake-draft covers every player once, balanced across groups', () {
      final input = players(12);
      final plan = generateGroupsThenKnockout(
        playerIds: input,
        groupCount: 3,
        qualifiersPerGroup: 2,
        shuffle: false,
      );

      final rosters = plan.groupMatches.map(groupRoster).toList();

      // No overlap between groups.
      for (var i = 0; i < rosters.length; i++) {
        for (var j = i + 1; j < rosters.length; j++) {
          expect(
            rosters[i].intersection(rosters[j]),
            isEmpty,
            reason: 'groups $i and $j overlap',
          );
        }
      }

      // Full coverage: union == all players.
      final union = rosters.fold(<String>{}, (acc, r) => acc..addAll(r));
      expect(union, input.toSet());

      // Balanced: group sizes differ by at most 1.
      final sizes = rosters.map((r) => r.length).toList();
      final maxSize = sizes.reduce((a, b) => a > b ? a : b);
      final minSize = sizes.reduce((a, b) => a < b ? a : b);
      expect(maxSize - minSize, lessThanOrEqualTo(1));
    });

    test('each group plays a full round-robin', () {
      final plan = generateGroupsThenKnockout(
        playerIds: players(8),
        groupCount: 2,
        qualifiersPerGroup: 2,
        shuffle: false,
      );
      for (final groupMatches in plan.groupMatches) {
        final k = groupRoster(groupMatches).length;
        expect(groupMatches.length, k * (k - 1) ~/ 2);
        // No self-matches inside a group.
        for (final m in groupMatches) {
          expect(m.player1Id, isNot(equals(m.player2Id)));
        }
      }
    });

    test('knockout phase is sized for qualifiers and starts empty', () {
      final plan = generateGroupsThenKnockout(
        playerIds: players(8),
        groupCount: 2,
        qualifiersPerGroup: 2, // 4 qualifiers → 3 KO matches
        shuffle: false,
      );
      final ko = plan.knockoutPlan;
      expect(ko.matches.length, 3);
      // Round 1 of the KO has no real players yet — admin advances them.
      final round1 = ko.matches.where((m) => m.roundNumber == 1);
      for (final m in round1) {
        expect(m.player1Id, isNull);
        expect(m.player2Id, isNull);
      }
      // The bracket tree itself is still laid out.
      expect(ko.nodes, isNotEmpty);
      expect(ko.nodes.where((n) => n.isGrandFinal).length, 1);
    });

    test('seeded shuffle is deterministic', () {
      List<List<String>> rosters(GroupsKnockoutPlan p) =>
          p.groupMatches.map((g) => groupRoster(g).toList()..sort()).toList();
      final a = generateGroupsThenKnockout(
        playerIds: players(12),
        groupCount: 3,
        qualifiersPerGroup: 2,
        seed: 99,
      );
      final b = generateGroupsThenKnockout(
        playerIds: players(12),
        groupCount: 3,
        qualifiersPerGroup: 2,
        seed: 99,
      );
      expect(rosters(a), rosters(b));
    });
  });
}
