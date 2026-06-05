import 'package:arena/data/repositories/standings_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '_supabase_mocks.dart';

void main() {
  late MockSupabaseClient client;
  late StandingsRepository repo;

  setUp(() {
    client = MockSupabaseClient();
    repo = StandingsRepository(client);
  });

  Map<String, dynamic> groupRow({
    String id = 'g1',
    String competitionId = 'c1',
    String name = 'Groupe A',
    int groupNumber = 1,
  }) =>
      {
        'id': id,
        'competition_id': competitionId,
        'name': name,
        'group_number': groupNumber,
      };

  Map<String, dynamic> membershipRow({
    String id = 'm1',
    String groupId = 'g1',
    String profileId = 'p1',
    int? position,
    int points = 0,
    int goalDiff = 0,
  }) =>
      {
        'id': id,
        'group_id': groupId,
        'profile_id': profileId,
        if (position != null) 'position': position,
        'points': points,
        'goal_diff': goalDiff,
      };

  group('forCompetition', () {
    test('aucune poule → [] sans interroger group_memberships', () async {
      final groups = stubFrom(client, 'groups', <Map<String, dynamic>>[]);
      final result = await repo.forCompetition('c1');
      expect(result, isEmpty);
      // filtre competition_id + order group_number asc
      expect(groups.filters.any((f) => f == 'eq:competition_id=c1'), isTrue);
      expect(groups.filters.any((f) => f == 'order:group_number=true'), isTrue);
    });

    test('filtre les memberships par in(group_id, ids)', () async {
      stubFrom(client, 'groups', [
        groupRow(id: 'g1', groupNumber: 1),
        groupRow(id: 'g2', name: 'Groupe B', groupNumber: 2),
      ]);
      final memberships = stubFrom(
        client,
        'group_memberships',
        <Map<String, dynamic>>[],
      );

      final result = await repo.forCompetition('c1');

      expect(result, hasLength(2));
      // un bucket vide par groupe quand il n'y a pas de membres
      expect(result[0].rows, isEmpty);
      expect(result[1].rows, isEmpty);
      // le filtre in porte sur group_id avec les ids des groupes
      expect(memberships.filters.any((f) => f.startsWith('in:group_id=')), isTrue);
      expect(memberships.hasFilter('in', 'group_id'), isTrue);
      final inFilter =
          memberships.filters.firstWhere((f) => f.startsWith('in:group_id='));
      expect(inFilter.contains('g1'), isTrue);
      expect(inFilter.contains('g2'), isTrue);
    });

    test('parse les rows et les associe au bon groupe', () async {
      stubFrom(client, 'groups', [groupRow(id: 'g1')]);
      stubFrom(client, 'group_memberships', [
        membershipRow(id: 'r1', groupId: 'g1', profileId: 'p1', points: 6),
      ]);

      final result = await repo.forCompetition('c1');

      expect(result, hasLength(1));
      final bucket = result.first;
      expect(bucket.group.id, 'g1');
      expect(bucket.group.name, 'Groupe A');
      expect(bucket.group.groupNumber, 1);
      expect(bucket.rows, hasLength(1));
      expect(bucket.rows.first.id, 'r1');
      expect(bucket.rows.first.profileId, 'p1');
      expect(bucket.rows.first.points, 6);
    });

    test('tri par position croissante quand position est defini', () async {
      stubFrom(client, 'groups', [groupRow(id: 'g1')]);
      stubFrom(client, 'group_memberships', [
        membershipRow(id: 'r2', position: 2, points: 3),
        membershipRow(id: 'r1', position: 1, points: 9),
        membershipRow(id: 'r3', position: 3, points: 0),
      ]);

      final result = await repo.forCompetition('c1');
      final rows = result.first.rows;
      expect(rows.map((r) => r.id).toList(), ['r1', 'r2', 'r3']);
    });

    test('fallback sur points desc puis goal_diff desc quand position nulle',
        () async {
      stubFrom(client, 'groups', [groupRow(id: 'g1')]);
      stubFrom(client, 'group_memberships', [
        membershipRow(id: 'low', points: 3, goalDiff: 5),
        membershipRow(id: 'high', points: 9, goalDiff: -1),
        membershipRow(id: 'tieA', points: 9, goalDiff: 2),
      ]);

      final result = await repo.forCompetition('c1');
      final rows = result.first.rows;
      // high (9pts) et tieA (9pts) avant low (3pts) ; entre les deux 9pts,
      // celui au meilleur goal_diff passe devant.
      expect(rows.map((r) => r.id).toList(), ['tieA', 'high', 'low']);
    });

    test('groupe sans membre → bucket avec rows vides', () async {
      stubFrom(client, 'groups', [
        groupRow(id: 'g1', groupNumber: 1),
        groupRow(id: 'g2', name: 'Groupe B', groupNumber: 2),
      ]);
      stubFrom(client, 'group_memberships', [
        membershipRow(id: 'r1', groupId: 'g1', position: 1),
      ]);

      final result = await repo.forCompetition('c1');
      expect(result, hasLength(2));
      expect(result[0].rows, hasLength(1));
      expect(result[1].rows, isEmpty);
    });
  });
}
