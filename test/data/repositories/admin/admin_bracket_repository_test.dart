import 'package:arena/data/repositories/admin/admin_bracket_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../_supabase_mocks.dart';

void main() {
  late MockSupabaseClient client;
  late AdminBracketRepository repo;

  setUp(() {
    client = MockSupabaseClient();
    repo = AdminBracketRepository(client);
  });

  group('listConfirmedRegistrations', () {
    test('filtre competition_id + status confirmed + order registered_at, '
        'mappe player_id', () async {
      final from = stubFrom(client, 'competition_registrations', [
        {'player_id': 'p1'},
        {'player_id': 'p2'},
      ]);

      final ids = await repo.listConfirmedRegistrations('c1');

      expect(ids, ['p1', 'p2']);
      expect(from.selectedColumns, 'player_id');
      expect(from.filters.any((f) => f == 'eq:competition_id=c1'), isTrue);
      expect(from.filters.any((f) => f == 'eq:status=confirmed'), isTrue);
      expect(from.hasFilter('order', 'registered_at'), isTrue);
    });

    test('liste vide → []', () async {
      stubFrom(client, 'competition_registrations', <Map<String, dynamic>>[]);
      expect(await repo.listConfirmedRegistrations('c1'), isEmpty);
    });
  });

  group('generateSingleElim', () {
    test('insère 1 phase knockout puis les matches et bracket_nodes', () async {
      // Phase: insert().select('id').single() → {id}
      final phaseProbe =
          _stubInsertReturningId(client, 'phases', 'phase-ko');
      // matches & bracket_nodes: chaque insert renvoie un id via une file.
      stubFromQueue(client, 'matches', [
        {'id': 'm0'},
        {'id': 'm1'},
        {'id': 'm2'},
      ]);
      stubFromQueue(client, 'bracket_nodes', [
        {'id': 'n0'},
        {'id': 'n1'},
        {'id': 'n2'},
      ]);

      // 4 joueurs → puissance de 2, 3 matches, 3 nodes, seed déterministe.
      await repo.generateSingleElim(
        competitionId: 'c1',
        playerIds: const ['p1', 'p2', 'p3', 'p4'],
        seed: 42,
      );

      // Payload de la phase insérée.
      final phaseVals = phaseProbe.insertedValues! as Map<String, dynamic>;
      expect(phaseVals['competition_id'], 'c1');
      expect(phaseVals['type'], 'knockout');
      expect(phaseVals['phase_order'], 1);
      expect(phaseVals['status'], 'pending');
    });
  });

  group('generateRoundRobinTournament', () {
    test('insère 1 phase round_robin puis 1 match par paire (pas de nodes)',
        () async {
      final phaseProbe =
          _stubInsertReturningId(client, 'phases', 'phase-rr');
      final matchProbe = stubFrom(client, 'matches', null);

      // 3 joueurs → 3 matches round-robin.
      await repo.generateRoundRobinTournament(
        competitionId: 'c1',
        playerIds: const ['p1', 'p2', 'p3'],
      );

      final phaseVals = phaseProbe.insertedValues! as Map<String, dynamic>;
      expect(phaseVals['type'], 'round_robin');
      expect(phaseVals['phase_order'], 1);

      // Le dernier match inséré expose un payload valide.
      final matchVals = matchProbe.insertedValues! as Map<String, dynamic>;
      expect(matchVals['competition_id'], 'c1');
      expect(matchVals['phase_id'], 'phase-rr');
      expect(matchVals['status'], 'pending');
      expect(matchVals.containsKey('round'), isTrue);
      expect(matchVals.containsKey('match_number'), isTrue);
    });
  });

  group('generateGroupsKnockoutTournament', () {
    test('insère 2 phases (groups + knockout), les groupes, '
        'les matches de groupe et le bracket KO', () async {
      // 2 phases successives : groups (order 1) puis knockout (order 2).
      final phaseProbe = _stubInsertQueueReturningId(
        client,
        'phases',
        [
          {'id': 'phase-groups'},
          {'id': 'phase-ko'},
        ],
      );
      // groups : insert().select('id').single() → renvoie un id par groupe.
      _stubInsertQueueReturningId(
        client,
        'groups',
        [
          {'id': 'g0'},
          {'id': 'g1'},
        ],
      );
      // matches : group matches (insert simple) + KO matches (insert+select).
      stubFromQueue(client, 'matches', List.generate(
        40,
        (i) => {'id': 'm$i'},
      ));
      stubFromQueue(client, 'bracket_nodes', List.generate(
        40,
        (i) => {'id': 'n$i'},
      ));

      await repo.generateGroupsKnockoutTournament(
        competitionId: 'c1',
        playerIds: const ['p1', 'p2', 'p3', 'p4', 'p5', 'p6', 'p7', 'p8'],
        groupCount: 2,
        qualifiersPerGroup: 2,
        seed: 7,
      );

      // La dernière phase insérée est la phase knockout (order 2).
      final phaseVals = phaseProbe.insertedValues! as Map<String, dynamic>;
      expect(phaseVals['type'], 'knockout');
      expect(phaseVals['phase_order'], 2);
    });
  });

  group('resetBracket', () {
    test('supprime bracket_nodes, matches et phases filtrés sur '
        'competition_id', () async {
      final nodesProbe = stubFrom(client, 'bracket_nodes', null);
      final matchesProbe = stubFrom(client, 'matches', null);
      final phasesProbe = stubFrom(client, 'phases', null);

      await repo.resetBracket('c1');

      expect(nodesProbe.filters.any((f) => f == 'eq:competition_id=c1'),
          isTrue);
      expect(matchesProbe.filters.any((f) => f == 'eq:competition_id=c1'),
          isTrue);
      expect(phasesProbe.filters.any((f) => f == 'eq:competition_id=c1'),
          isTrue);
    });
  });
}

/// Branche `from(table)` sur une chaîne dont l'`await` final renvoie une
/// Map `{id: ...}` — modélise le pattern `insert().select('id').single()`.
/// Renvoie le probe pour asserter le payload inséré.
QueryProbe _stubInsertReturningId(
  MockSupabaseClient client,
  String table,
  String id,
) =>
    stubFrom(client, table, {'id': id});

/// Variante file : chaque appel à `from(table)` renvoie le résultat suivant.
/// Renvoie le probe du DERNIER builder créé (le payload le plus récent).
QueryProbe _stubInsertQueueReturningId(
  MockSupabaseClient client,
  String table,
  List<Map<String, dynamic>> results,
) {
  var i = 0;
  late QueryProbe lastProbe;
  when(() => client.from(table)).thenAnswer((_) {
    final r = results[i < results.length ? i : results.length - 1];
    i++;
    final from = FakeFromBuilder(Future<dynamic>.value(r));
    lastProbe = from.probe;
    return from;
  });
  // Le probe est créé à l'appel ; on renvoie un proxy lazy via closure.
  return _LazyProbe(() => lastProbe);
}

/// Probe qui délègue à la dernière instance capturée (résolue après les
/// appels). Permet d'asserter le payload du dernier `from()` exécuté.
class _LazyProbe implements QueryProbe {
  _LazyProbe(this._resolve);
  final QueryProbe Function() _resolve;

  @override
  Object? get insertedValues => _resolve().insertedValues;
  @override
  set insertedValues(Object? v) => _resolve().insertedValues = v;

  @override
  Object? get upsertedValues => _resolve().upsertedValues;
  @override
  set upsertedValues(Object? v) => _resolve().upsertedValues = v;

  @override
  Map<dynamic, dynamic>? get updatedValues => _resolve().updatedValues;
  @override
  set updatedValues(Map<dynamic, dynamic>? v) => _resolve().updatedValues = v;

  @override
  String? get selectedColumns => _resolve().selectedColumns;
  @override
  set selectedColumns(String? v) => _resolve().selectedColumns = v;

  @override
  List<String> get filters => _resolve().filters;

  @override
  void record(String op, String column, Object? value) =>
      _resolve().record(op, column, value);

  @override
  bool hasFilter(String op, String column) =>
      _resolve().hasFilter(op, column);
}
