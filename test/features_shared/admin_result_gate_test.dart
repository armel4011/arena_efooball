import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/models/competition.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/data/models/match_status.dart';
import 'package:arena/features_shared/admin_result_gate.dart';
import 'package:flutter_test/flutter_test.dart';

Competition _comp({
  double prize = 0,
  List<int> dist = const [0, 0, 0, 0],
  CompetitionStatus status = CompetitionStatus.ongoing,
}) =>
    Competition(
      id: 'c1',
      name: 'C',
      game: GameType.values.first,
      format: TournamentFormat.values.first,
      startDate: DateTime(2026, 1, 1),
      prizePoolLocal: prize,
      prizeDistribution: dist,
      status: status,
    );

ArenaMatch _match({String? winner, MatchStatus status = MatchStatus.pending}) =>
    ArenaMatch(id: 'm1', competitionId: 'c1', winnerId: winner, status: status);

void main() {
  group('competitionHasPrize', () {
    test('cagnotte déclarée → true', () {
      expect(competitionHasPrize(_comp(prize: 50000)), isTrue);
    });
    test('part de distribution > 0 → true', () {
      expect(competitionHasPrize(_comp(dist: const [0, 0, 3000, 0])), isTrue);
    });
    test('aucun enjeu → false', () {
      expect(competitionHasPrize(_comp()), isFalse);
    });
  });

  group('matchResultLockedForAdmin', () {
    test('super-admin → jamais verrouillé (même prix + décidé)', () {
      expect(
        matchResultLockedForAdmin(
          isSuperAdmin: true,
          competition: _comp(prize: 50000),
          match: _match(winner: 'p1', status: MatchStatus.completed),
        ),
        isFalse,
      );
    });
    test('compétition sans prix → non verrouillé', () {
      expect(
        matchResultLockedForAdmin(
          isSuperAdmin: false,
          competition: _comp(),
          match: _match(winner: 'p1', status: MatchStatus.completed),
        ),
        isFalse,
      );
    });
    test('à prix, admin simple, match NON décidé → 1re saisie permise', () {
      expect(
        matchResultLockedForAdmin(
          isSuperAdmin: false,
          competition: _comp(prize: 50000),
          match: _match(),
        ),
        isFalse,
      );
    });
    test('à prix, admin simple, vainqueur déjà posé → VERROUILLÉ', () {
      expect(
        matchResultLockedForAdmin(
          isSuperAdmin: false,
          competition: _comp(prize: 50000),
          match: _match(winner: 'p1'),
        ),
        isTrue,
      );
    });
    test('à prix, admin simple, match terminal → VERROUILLÉ', () {
      expect(
        matchResultLockedForAdmin(
          isSuperAdmin: false,
          competition: _comp(prize: 50000),
          match: _match(status: MatchStatus.forfeited),
        ),
        isTrue,
      );
    });
  });

  group('finalRankLockedForAdmin', () {
    test('super-admin → jamais verrouillé', () {
      expect(
        finalRankLockedForAdmin(
          isSuperAdmin: true,
          competition: _comp(prize: 50000, status: CompetitionStatus.completed),
        ),
        isFalse,
      );
    });
    test('sans prix → non verrouillé', () {
      expect(
        finalRankLockedForAdmin(
          isSuperAdmin: false,
          competition: _comp(status: CompetitionStatus.completed),
        ),
        isFalse,
      );
    });
    test('à prix, admin simple, compétition EN COURS → permis (avant clôture)',
        () {
      expect(
        finalRankLockedForAdmin(
          isSuperAdmin: false,
          competition: _comp(prize: 50000),
        ),
        isFalse,
      );
    });
    test('à prix, admin simple, compétition CLÔTURÉE → VERROUILLÉ', () {
      expect(
        finalRankLockedForAdmin(
          isSuperAdmin: false,
          competition: _comp(prize: 50000, status: CompetitionStatus.completed),
        ),
        isTrue,
      );
    });
  });
}
