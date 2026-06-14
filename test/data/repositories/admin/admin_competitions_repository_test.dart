import 'package:arena/data/models/user_role.dart';
import 'package:arena/data/repositories/admin/admin_audit_log_repository.dart';
import 'package:arena/data/repositories/admin/admin_competitions_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../_supabase_mocks.dart';

void main() {
  late MockSupabaseClient client;
  late AdminCompetitionsRepository repo;

  setUp(() {
    client = MockSupabaseClient();
    repo = AdminCompetitionsRepository(
      client,
      AdminAuditLogRepository(client),
    );
  });

  QueryProbe stub(String table, Object? result) =>
      stubFrom(client, table, result);

  Map<String, dynamic> competitionRow({
    String id = 'c1',
    String name = 'Coupe Arena',
    String status = 'registration_open',
  }) =>
      {
        'id': id,
        'name': name,
        'game': 'efootball',
        'format': 'single_elimination',
        'start_date': '2026-07-01T18:00:00.000Z',
        'status': status,
        'max_players': 16,
      };

  Map<String, dynamic> registrationRow({
    String playerId = 'p1',
    String status = 'confirmed',
    int? finalRank,
    Map<String, dynamic>? profile = const {
      'username': 'Zoro',
      'country_code': 'CI',
      'avatar_color': '#FF0000',
      'role': 'player',
    },
  }) =>
      {
        'player_id': playerId,
        'registered_at': '2026-06-01T10:00:00.000Z',
        'status': status,
        if (finalRank != null) 'final_rank': finalRank,
        'profiles': profile,
      };

  group('create', () {
    test('insert payload + select.single + parse', () async {
      final from = stub('competitions', competitionRow());
      final payload = <String, dynamic>{
        'name': 'Coupe Arena',
        'game': 'efootball',
        'format': 'single_elimination',
        'start_date': '2026-07-01T18:00:00.000Z',
      };
      final comp = await repo.create(payload);
      expect(comp.id, 'c1');
      expect(comp.name, 'Coupe Arena');
      expect(from.insertedValues, payload);
      expect(from.hasFilter('single', '_'), isTrue);
    });
  });

  group('update', () {
    test('patch + eq id + select.single + parse', () async {
      final from = stub('competitions', competitionRow(name: 'Renommée'));
      final comp = await repo.update('c1', {'name': 'Renommée'});
      expect(comp.name, 'Renommée');
      expect(from.updatedValues, {'name': 'Renommée'});
      expect(from.filters.any((f) => f == 'eq:id=c1'), isTrue);
    });
  });

  group('regenerate (RPC)', () {
    test('appelle regenerate_competition + parse la 1re ligne', () async {
      when(
        () => client.rpc<dynamic>(
          'regenerate_competition',
          params: any(named: 'params'),
        ),
      ).thenAnswer(
        (_) => FakeQueryChain<dynamic>(
          Future<dynamic>.value([competitionRow(id: 'c2', name: 'Coupe v2')]),
        ),
      );

      final comp = await repo.regenerate('c1');
      expect(comp.id, 'c2');
      expect(comp.name, 'Coupe v2');

      final captured = verify(
        () => client.rpc<dynamic>(
          'regenerate_competition',
          params: captureAny(named: 'params'),
        ),
      ).captured.single as Map<String, dynamic>;
      expect(captured, {'p_competition_id': 'c1'});
    });

    test('liste vide → StateError', () async {
      when(
        () => client.rpc<dynamic>(
          'regenerate_competition',
          params: any(named: 'params'),
        ),
      ).thenAnswer(
        (_) => FakeQueryChain<dynamic>(Future<dynamic>.value(<dynamic>[])),
      );
      expect(() => repo.regenerate('c1'), throwsStateError);
    });
  });

  group('listRegistrations', () {
    test('eq competition_id + order registered_at + parse profil', () async {
      final from = stub('competition_registrations', [
        registrationRow(playerId: 'p1', finalRank: 1),
      ]);
      final list = await repo.listRegistrations('c1');
      expect(list, hasLength(1));
      final r = list.first;
      expect(r.playerId, 'p1');
      expect(r.username, 'Zoro');
      expect(r.countryCode, 'CI');
      expect(r.avatarColor, '#FF0000');
      expect(r.role, UserRole.player);
      expect(r.status, 'confirmed');
      expect(r.finalRank, 1);
      expect(from.filters.any((f) => f == 'eq:competition_id=c1'), isTrue);
      expect(from.hasFilter('order', 'registered_at'), isTrue);
    });

    test('profil manquant → valeurs de repli', () async {
      stub('competition_registrations', [
        registrationRow(playerId: 'p2', profile: null),
      ]);
      final list = await repo.listRegistrations('c1');
      final r = list.first;
      expect(r.username, '—');
      expect(r.countryCode, '');
      expect(r.avatarColor, '#4C7AFF');
      expect(r.role, UserRole.player);
    });

    test('liste vide → []', () async {
      stub('competition_registrations', <Map<String, dynamic>>[]);
      expect(await repo.listRegistrations('c1'), isEmpty);
    });
  });

  group('setFinalRank', () {
    test('update final_rank + eq competition_id + eq player_id', () async {
      final from = stub('competition_registrations', null);
      await repo.setFinalRank('c1', 'p1', 3);
      expect(from.updatedValues, {'final_rank': 3});
      expect(from.filters.any((f) => f == 'eq:competition_id=c1'), isTrue);
      expect(from.filters.any((f) => f == 'eq:player_id=p1'), isTrue);
    });

    test('rank null → efface (final_rank null)', () async {
      final from = stub('competition_registrations', null);
      await repo.setFinalRank('c1', 'p1', null);
      expect(from.updatedValues, {'final_rank': null});
    });
  });

  group('autoRankFromResults', () {
    test('sans inscrits → ne touche pas matches', () async {
      stub('competition_registrations', <Map<String, dynamic>>[]);
      await repo.autoRankFromResults('c1');
      verifyNever(() => client.from('matches'));
    });

    test('classe par niveau > buts > pseudo et upsert rangs séquentiels',
        () async {
      // On capture chaque FakeFromBuilder créé pour la table registrations :
      // le 1er sert à listRegistrations, le 2e porte le payload upsert.
      final regBuilders = <FakeFromBuilder>[];
      when(() => client.from('competition_registrations')).thenAnswer((_) {
        final from = regBuilders.isEmpty
            ? FakeFromBuilder(
                Future<dynamic>.value([
                  registrationRow(
                    playerId: 'pAlpha',
                    profile: const {'username': 'Alpha', 'role': 'player'},
                  ),
                  registrationRow(
                    playerId: 'pBravo',
                    profile: const {'username': 'Bravo', 'role': 'player'},
                  ),
                  registrationRow(
                    playerId: 'pCharlie',
                    profile: const {'username': 'Charlie', 'role': 'player'},
                  ),
                ]),
              )
            : FakeFromBuilder(Future<dynamic>.value(null));
        regBuilders.add(from);
        return from;
      });

      // Bravo bat Alpha en finale (round 3) → Bravo et Alpha atteignent le
      // round 3. Charlie tombe au round 1. Donc Bravo=1, Alpha=2, Charlie=3.
      final matchesProbe = stub('matches', [
        {
          'round': 3,
          'player1_id': 'pBravo',
          'player2_id': 'pAlpha',
          'score1': 2,
          'score2': 0,
        },
        {
          'round': 1,
          'player1_id': 'pCharlie',
          'player2_id': 'pBravo',
          'score1': 0,
          'score2': 1,
        },
      ]);

      await repo.autoRankFromResults('c1');

      expect(matchesProbe.filters.any((f) => f == 'eq:competition_id=c1'),
          isTrue,);

      // Le builder qui porte le payload upsert (peu importe son rang).
      final upsertBuilder = regBuilders.firstWhere(
        (b) => b.probe.upsertedValues != null,
      );
      final upserted = upsertBuilder.probe.upsertedValues! as List<dynamic>;
      expect(upserted, hasLength(3));
      final ranks = {
        for (final e in upserted)
          (e as Map<String, dynamic>)['player_id'] as String:
              e['final_rank'] as int,
      };
      // Bravo (round 3) = 1 ; Alpha (round 3, perdant) = 2 ; Charlie (r1) = 3.
      expect(ranks['pBravo'], 1);
      expect(ranks['pAlpha'], 2);
      expect(ranks['pCharlie'], 3);
      // competition_id propagé sur chaque ligne.
      expect(
        upserted.every(
          (e) => (e as Map<String, dynamic>)['competition_id'] == 'c1',
        ),
        isTrue,
      );
    });
  });

  group('setPinned', () {
    test('épingle → update is_pinned/pinned_at + audit competition_pinned',
        () async {
      final comp = stub('competitions', null);
      final audit = stub('admin_audit_log', null);

      await repo.setPinned(
        competitionId: 'c1',
        pinned: true,
        adminId: 'admin-1',
      );

      // UPDATE sur competitions : is_pinned = true + pinned_at horodaté.
      final updated = comp.updatedValues!;
      expect(updated['is_pinned'], isTrue);
      expect(updated['pinned_at'], isA<String>());
      expect(updated['pinned_at'], isNotNull);
      expect(comp.filters.any((f) => f == 'eq:id=c1'), isTrue);

      // Audit log : insert competition_pinned ciblant la compétition.
      final logged = audit.insertedValues! as Map<String, dynamic>;
      expect(logged['admin_id'], 'admin-1');
      expect(logged['action'], 'competition_pinned');
      expect(logged['target_type'], 'competition');
      expect(logged['target_id'], 'c1');
      expect(logged['after_state'], {'is_pinned': true});
    });

    test('désépingle → pinned_at null + audit competition_unpinned',
        () async {
      final comp = stub('competitions', null);
      final audit = stub('admin_audit_log', null);

      await repo.setPinned(
        competitionId: 'c1',
        pinned: false,
        adminId: 'admin-1',
      );

      final updated = comp.updatedValues!;
      expect(updated['is_pinned'], isFalse);
      expect(updated['pinned_at'], isNull);

      final logged = audit.insertedValues! as Map<String, dynamic>;
      expect(logged['action'], 'competition_unpinned');
      expect(logged['after_state'], {'is_pinned': false});
    });
  });

  group('cancel (RPC)', () {
    test('appelle cancel_competition + renvoie le nombre notifié', () async {
      when(
        () => client.rpc<dynamic>(
          'cancel_competition',
          params: any(named: 'params'),
        ),
      ).thenAnswer((_) => FakeQueryChain<dynamic>(Future<dynamic>.value(4)));

      expect(await repo.cancel('c1'), 4);

      final captured = verify(
        () => client.rpc<dynamic>(
          'cancel_competition',
          params: captureAny(named: 'params'),
        ),
      ).captured.single as Map<String, dynamic>;
      expect(captured, {'p_competition_id': 'c1'});
    });

    test('résultat null → 0', () async {
      when(
        () => client.rpc<dynamic>(
          'cancel_competition',
          params: any(named: 'params'),
        ),
      ).thenAnswer((_) => FakeQueryChain<dynamic>(Future<dynamic>.value(null)));
      expect(await repo.cancel('c1'), 0);
    });
  });

  group('delete (RPC)', () {
    test('appelle delete_competition_cascade', () async {
      when(
        () => client.rpc<void>(
          'delete_competition_cascade',
          params: any(named: 'params'),
        ),
      ).thenAnswer((_) => FakeQueryChain<void>(Future<void>.value()));

      await repo.delete('c1');

      final captured = verify(
        () => client.rpc<void>(
          'delete_competition_cascade',
          params: captureAny(named: 'params'),
        ),
      ).captured.single as Map<String, dynamic>;
      expect(captured, {'p_competition_id': 'c1'});
    });
  });
}
