import 'package:arena/core/utils/bracket_generators/bracket_generator.dart';
import 'package:arena/core/utils/bracket_generators/round_robin_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('generateRoundRobin', () {
    List<String> players(int n) =>
        List.generate(n, (i) => 'p${i.toString().padLeft(2, '0')}');

    String pairKey(PlannedMatch m) {
      final a = m.player1Id!;
      final b = m.player2Id!;
      return (a.compareTo(b) < 0) ? '$a|$b' : '$b|$a';
    }

    test('throws below 2 players', () {
      expect(
        () => generateRoundRobin(playerIds: players(1)),
        throwsA(isA<BracketGenerationException>()),
      );
    });

    test('throws above 32 players', () {
      expect(
        () => generateRoundRobin(playerIds: players(33)),
        throwsA(isA<BracketGenerationException>()),
      );
    });

    test('emits N*(N-1)/2 matches for both even and odd counts', () {
      for (final n in [2, 3, 4, 5, 6, 7, 8]) {
        final plan = generateRoundRobin(playerIds: players(n));
        expect(
          plan.matches.length,
          n * (n - 1) ~/ 2,
          reason: 'N=$n match count',
        );
      }
    });

    test('every unordered pair appears exactly once (full coverage)', () {
      for (final n in [3, 4, 5, 6]) {
        final plan = generateRoundRobin(playerIds: players(n));
        final keys = plan.matches.map(pairKey).toList();
        expect(keys.toSet().length, keys.length, reason: 'N=$n no dup pair');

        final expected = <String>{};
        final ids = players(n);
        for (var i = 0; i < ids.length; i++) {
          for (var j = i + 1; j < ids.length; j++) {
            expected.add('${ids[i]}|${ids[j]}');
          }
        }
        expect(keys.toSet(), expected, reason: 'N=$n covers all pairs');
      }
    });

    test('never schedules a player against themselves', () {
      final plan = generateRoundRobin(playerIds: players(7));
      for (final m in plan.matches) {
        expect(m.player1Id, isNot(equals(m.player2Id)));
      }
    });

    test('no player plays twice in the same round', () {
      final plan = generateRoundRobin(playerIds: players(6));
      final byRound = <int, List<String>>{};
      for (final m in plan.matches) {
        byRound.putIfAbsent(m.roundNumber, () => []).addAll([
          m.player1Id!,
          m.player2Id!,
        ]);
      }
      byRound.forEach((round, seats) {
        expect(seats.toSet().length, seats.length, reason: 'round $round');
      });
    });

    test('round-robin produces no bracket nodes', () {
      final plan = generateRoundRobin(playerIds: players(5));
      expect(plan.nodes, isEmpty);
    });

    test('matchNumber is contiguous starting at 1', () {
      final plan = generateRoundRobin(playerIds: players(4));
      final numbers = plan.matches.map((m) => m.matchNumber).toList();
      expect(numbers, List.generate(numbers.length, (i) => i + 1));
    });
  });
}
