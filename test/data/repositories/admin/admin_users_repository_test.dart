import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/data/repositories/admin/admin_users_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../_supabase_mocks.dart';

void main() {
  late MockSupabaseClient client;
  late AdminUsersRepository repo;

  setUp(() {
    client = MockSupabaseClient();
    repo = AdminUsersRepository(client);
  });

  QueryProbe stub(String table, Object? result) =>
      stubFrom(client, table, result);

  group("ban / unban (contrôle d'accès)", () {
    test('ban → is_active false, cible le user', () async {
      final from = stub('profiles', null);
      await repo.ban('u1');
      expect(from.updatedValues!['is_active'], false);
      expect(from.filters.any((f) => f == 'eq:id=u1'), isTrue);
    });

    test('unban → is_active true + reset permanent_ban (override 3-strikes)',
        () async {
      final from = stub('profiles', null);
      await repo.unban('u1');
      final v = from.updatedValues!;
      expect(v['is_active'], true);
      expect(v['permanent_ban'], false);
    });
  });

  group('overrideKyc', () {
    test('verified → stamp kyc_verified_at', () async {
      final from = stub('profiles', null);
      await repo.overrideKyc(userId: 'u1', status: 'verified');
      expect(from.updatedValues!['kyc_status'], 'verified');
      expect(from.updatedValues!['kyc_verified_at'], isA<String>());
    });

    test('rejected → pas de kyc_verified_at', () async {
      final from = stub('profiles', null);
      await repo.overrideKyc(userId: 'u1', status: 'rejected');
      expect(from.updatedValues!['kyc_status'], 'rejected');
      expect(from.updatedValues!.containsKey('kyc_verified_at'), isFalse);
    });
  });

  group('list (RPC admin_filter_users)', () {
    test('mappe les filtres : bool false → null, search trimmé, limit',
        () async {
      when(
        () => client.rpc<List<dynamic>>(
          'admin_filter_users',
          params: any(named: 'params'),
        ),
      ).thenAnswer(
        (_) => FakeQueryChain<List<dynamic>>(
          Future<List<dynamic>>.value([
            {'id': 'u1', 'username': 'bob', 'country_code': 'CM'},
          ]),
        ),
      );

      final list = await repo.list(
        filter: const AdminUsersFilter(
          searchQuery: '  bob  ',
          wonCompetition: true,
        ),
        limit: 50,
      );

      expect(list, hasLength(1));
      final captured = verify(
        () => client.rpc<List<dynamic>>(
          'admin_filter_users',
          params: captureAny(named: 'params'),
        ),
      ).captured.single as Map<String, dynamic>;
      expect(captured['p_search'], 'bob'); // trimmé
      expect(captured['p_won'], true); // actif → true
      expect(captured['p_paid'], isNull); // false → null
      expect(captured['p_limit'], 50);
    });

    test('filtre jeux : liste vide → p_games null, sinon liste de values',
        () async {
      when(
        () => client.rpc<List<dynamic>>(
          'admin_filter_users',
          params: any(named: 'params'),
        ),
      ).thenAnswer(
        (_) => FakeQueryChain<List<dynamic>>(
          Future<List<dynamic>>.value(const []),
        ),
      );

      // Vide → null.
      await repo.list(filter: const AdminUsersFilter());
      // Sélection → liste des GameType.value.
      await repo.list(
        filter: const AdminUsersFilter(
          games: [GameType.efootball, GameType.dreamLeague],
        ),
      );

      final captured = verify(
        () => client.rpc<List<dynamic>>(
          'admin_filter_users',
          params: captureAny(named: 'params'),
        ),
      ).captured.cast<Map<String, dynamic>>();
      expect(captured[0]['p_games'], isNull);
      expect(captured[1]['p_games'], ['efootball', 'dream_league']);
    });
  });

  group('gameInterestStats (RPC admin_game_interest_stats)', () {
    test('mappe respondents + counts (clés jeu → GameType)', () async {
      when(
        () => client.rpc<Map<String, dynamic>>(
          'admin_game_interest_stats',
          params: any(named: 'params'),
        ),
      ).thenAnswer(
        (_) => FakeQueryChain<Map<String, dynamic>>(
          Future<Map<String, dynamic>>.value({
            'respondents': 12,
            'counts': {'efootball': 8, 'dream_league': 3},
          }),
        ),
      );

      final stats = await repo.gameInterestStats();
      expect(stats.respondents, 12);
      expect(stats.countFor(GameType.efootball), 8);
      expect(stats.countFor(GameType.dreamLeague), 3);
      // Jeu absent des counts → 0.
      expect(stats.countFor(GameType.draughts), 0);
    });

    test('payload vide → 0 répondant, counts {}', () {
      final stats = GameInterestStats.fromJson(const {});
      expect(stats.respondents, 0);
      expect(stats.counts, isEmpty);
      expect(stats.countFor(GameType.efootball), 0);
    });
  });
}
