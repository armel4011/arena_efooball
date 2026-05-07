import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/models/match_status.dart';
import 'package:arena/data/repositories/match_stats_repository.dart';
import 'package:flutter_test/flutter_test.dart';

ArenaMatch _m({
  required String id,
  required String p1,
  required String p2,
  int? s1,
  int? s2,
  String? winner,
}) {
  return ArenaMatch(
    id: id,
    competitionId: 'comp',
    player1Id: p1,
    player2Id: p2,
    score1: s1,
    score2: s2,
    winnerId: winner,
    status: MatchStatus.completed,
  );
}

void main() {
  const me = 'me';
  const opp = 'opp';

  group('MatchStatsRepository.foldMatches', () {
    test('empty input → empty stats', () {
      final stats = MatchStatsRepository.foldMatches(me, const []);
      expect(stats.totalMatches, 0);
      expect(stats.winRatio, 0.0);
    });

    test('counts wins as player1 and player2', () {
      final stats = MatchStatsRepository.foldMatches(me, [
        _m(id: '1', p1: me, p2: opp, s1: 3, s2: 1, winner: me),
        _m(id: '2', p1: opp, p2: me, s1: 0, s2: 2, winner: me),
      ]);
      expect(stats.wins, 2);
      expect(stats.losses, 0);
      expect(stats.draws, 0);
      expect(stats.goalsScored, 5);
      expect(stats.goalsConceded, 1);
      expect(stats.winRatio, 1.0);
    });

    test('counts losses (opponent wins)', () {
      final stats = MatchStatsRepository.foldMatches(me, [
        _m(id: '1', p1: me, p2: opp, s1: 1, s2: 4, winner: opp),
      ]);
      expect(stats.wins, 0);
      expect(stats.losses, 1);
      expect(stats.draws, 0);
      expect(stats.goalsScored, 1);
      expect(stats.goalsConceded, 4);
    });

    test('null winner_id is counted as a draw', () {
      final stats = MatchStatsRepository.foldMatches(me, [
        _m(id: '1', p1: me, p2: opp, s1: 2, s2: 2),
      ]);
      expect(stats.draws, 1);
      expect(stats.wins, 0);
      expect(stats.losses, 0);
    });

    test('mixed sample folds correctly with score perspective', () {
      final stats = MatchStatsRepository.foldMatches(me, [
        _m(id: 'a', p1: me, p2: opp, s1: 3, s2: 1, winner: me), // W 3-1
        _m(id: 'b', p1: opp, p2: me, s1: 0, s2: 2, winner: me), // W 2-0
        _m(id: 'c', p1: me, p2: opp, s1: 1, s2: 4, winner: opp), // L 1-4
        _m(id: 'd', p1: opp, p2: me, s1: 1, s2: 1), // D 1-1
      ]);
      expect(stats.wins, 2);
      expect(stats.losses, 1);
      expect(stats.draws, 1);
      expect(stats.goalsScored, 3 + 2 + 1 + 1);
      expect(stats.goalsConceded, 1 + 0 + 4 + 1);
      expect(stats.totalMatches, 4);
      expect(stats.winRatio, 0.5);
      expect(stats.goalDifference, 1);
    });

    test('matches not involving the player are skipped', () {
      final stats = MatchStatsRepository.foldMatches(me, [
        _m(id: '1', p1: 'foo', p2: 'bar', s1: 5, s2: 0, winner: 'foo'),
      ]);
      expect(stats.totalMatches, 0);
    });

    test('null scores fall back to 0 in the running totals', () {
      final stats = MatchStatsRepository.foldMatches(me, [
        _m(id: '1', p1: me, p2: opp, winner: me),
      ]);
      expect(stats.wins, 1);
      expect(stats.goalsScored, 0);
      expect(stats.goalsConceded, 0);
    });
  });
}
