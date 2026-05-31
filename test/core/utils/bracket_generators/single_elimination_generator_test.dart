import 'dart:math';

import 'package:arena/core/utils/bracket_generators/bracket_generator.dart';
import 'package:arena/core/utils/bracket_generators/single_elimination_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('generateSingleElimination', () {
    List<String> players(int n) =>
        List.generate(n, (i) => 'p${i.toString().padLeft(2, '0')}');

    test('throws below 2 players', () {
      expect(
        () => generateSingleElimination(playerIds: players(1)),
        throwsA(isA<BracketGenerationException>()),
      );
      expect(
        () => generateSingleElimination(playerIds: const []),
        throwsA(isA<BracketGenerationException>()),
      );
    });

    test('throws above 256 players', () {
      expect(
        () => generateSingleElimination(playerIds: players(257)),
        throwsA(isA<BracketGenerationException>()),
      );
    });

    test('power-of-two field yields N-1 matches and no byes', () {
      for (final n in [2, 4, 8, 16, 32]) {
        final plan =
            generateSingleElimination(playerIds: players(n), shuffle: false);
        expect(plan.matches.length, n - 1, reason: 'N=$n match count');
        expect(
          plan.nodes.where((node) => node.isBye),
          isEmpty,
          reason: 'N=$n should have no byes',
        );
        final totalRounds = (log(n) / log(2)).round();
        expect(
          plan.nodes.every((node) => node.totalRounds == totalRounds),
          isTrue,
          reason: 'N=$n totalRounds',
        );
      }
    });

    test('non-power-of-two field is padded up to the next power of two', () {
      // 7 players → field of 8 → 7 matches total (size - 1).
      final plan =
          generateSingleElimination(playerIds: players(7), shuffle: false);
      expect(plan.matches.length, 7);

      // Exactly one round-1 match has an empty slot: the lone top seed
      // auto-advances, and the bye node carries that player.
      final byeNodes = plan.nodes.where((node) => node.isBye).toList();
      expect(byeNodes.length, 1);
      expect(byeNodes.single.byePlayerId, isNotNull);
      expect(byeNodes.single.roundNumber, 1);
    });

    test('round 1 seats every player exactly once (no loss, no dup)', () {
      final input = players(6);
      final plan =
          generateSingleElimination(playerIds: input, shuffle: false);
      final round1 = plan.matches.where((m) => m.roundNumber == 1);
      final seated = <String>[];
      for (final m in round1) {
        if (m.player1Id != null) seated.add(m.player1Id!);
        if (m.player2Id != null) seated.add(m.player2Id!);
      }
      expect(seated.toSet(), input.toSet());
      expect(seated.length, input.length, reason: 'no duplicate seating');
    });

    test('later-round matches start with empty slots', () {
      final plan =
          generateSingleElimination(playerIds: players(8), shuffle: false);
      final later = plan.matches.where((m) => m.roundNumber > 1);
      expect(later, isNotEmpty);
      for (final m in later) {
        expect(m.player1Id, isNull);
        expect(m.player2Id, isNull);
      }
    });

    test('exactly one grand final, pointing nowhere', () {
      final plan =
          generateSingleElimination(playerIds: players(8), shuffle: false);
      final finals = plan.nodes.where((node) => node.isGrandFinal).toList();
      expect(finals.length, 1);
      expect(finals.single.nextNodeIndex, isNull);
      expect(finals.single.roundNumber, finals.single.totalRounds);
    });

    test('node links resolve to a valid round-N+1 node and alternate sides',
        () {
      final plan =
          generateSingleElimination(playerIds: players(8), shuffle: false);
      for (final node in plan.nodes) {
        if (node.isGrandFinal) continue;
        expect(node.nextNodeIndex, isNotNull);
        final target = plan.nodes[node.nextNodeIndex!];
        expect(target.roundNumber, node.roundNumber + 1);
        // Even positions feed player1 of the parent, odd feed player2.
        expect(node.nextPosition, node.positionInRound.isEven ? 'player1' : 'player2');
      }
    });

    test('matchIndex points back to a real match', () {
      final plan =
          generateSingleElimination(playerIds: players(8), shuffle: false);
      for (final node in plan.nodes) {
        expect(node.matchIndex, inInclusiveRange(0, plan.matches.length - 1));
      }
    });

    test('seeded shuffle is deterministic', () {
      final a = generateSingleElimination(playerIds: players(8), seed: 42);
      final b = generateSingleElimination(playerIds: players(8), seed: 42);
      String round1(BracketPlan p) => p.matches
          .where((m) => m.roundNumber == 1)
          .map((m) => '${m.player1Id}-${m.player2Id}')
          .join('|');
      expect(round1(a), round1(b));
    });

    test('does not mutate the caller list', () {
      final input = players(8);
      final copy = [...input];
      generateSingleElimination(playerIds: input, seed: 7);
      expect(input, copy);
    });
  });
}
