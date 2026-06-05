import 'package:arena/data/repositories/payout_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '_supabase_mocks.dart';

void main() {
  late MockSupabaseClient client;
  late PayoutRepository repo;

  setUp(() {
    client = MockSupabaseClient();
    repo = PayoutRepository(client);
  });

  QueryProbe stub(String table, Object? result) =>
      stubFrom(client, table, result);

  Map<String, dynamic> payoutRow({
    String id = 'po1',
    String status = 'pending_admin_validation',
    int? rank,
    String? compName,
  }) =>
      {
        'id': id,
        'user_id': 'u1',
        'competition_id': 'c1',
        'amount_local': 5000,
        'status': status,
        'created_at': '2026-06-01T10:00:00.000Z',
        if (rank != null) 'rank': rank,
        if (compName != null) 'competitions': {'name': compName},
      };

  group('listMine', () {
    test('non authentifié → [] sans requête', () async {
      stubAuthUser(client, null);
      expect(await repo.listMine(), isEmpty);
      verifyNever(() => client.from(any()));
    });

    test('filtre user_id + order created_at desc + limit + parse', () async {
      stubAuthUser(client, 'u1');
      final from = stub('payouts', [payoutRow(rank: 1)]);
      final list = await repo.listMine(limit: 10);
      expect(list, hasLength(1));
      expect(list.first.id, 'po1');
      expect(list.first.amountLocal, 5000);
      expect(list.first.isPending, isTrue);
      expect(from.filters.any((f) => f == 'eq:user_id=u1'), isTrue);
      expect(from.filters.any((f) => f == 'limit:_=10'), isTrue);
    });
  });

  group('listPendingGlobal', () {
    test('filtre pending_admin_validation, embed compétition, tri claimed/created',
        () async {
      final from = stub('payouts', [payoutRow(compName: 'Coupe Arena')]);
      final list = await repo.listPendingGlobal();
      expect(list.first.competitionName, 'Coupe Arena');
      expect(
        from.filters.any((f) => f == 'eq:status=pending_admin_validation'),
        isTrue,
      );
      expect(from.hasFilter('order', 'claimed_at'), isTrue);
    });
  });

  group('listByCompetition', () {
    test('filtre competition_id + order rank', () async {
      final from = stub('payouts', <Map<String, dynamic>>[]);
      await repo.listByCompetition('c1');
      expect(from.filters.any((f) => f == 'eq:competition_id=c1'), isTrue);
      expect(from.hasFilter('order', 'rank'), isTrue);
    });
  });

  group('claim (RPC propriété vérifiée serveur)', () {
    test('appelle claim_payout avec phone + method', () async {
      when(
        () => client.rpc<void>('claim_payout', params: any(named: 'params')),
      ).thenAnswer((_) => FakeQueryChain<void>(Future<void>.value()));

      await repo.claim(payoutId: 'po1', phone: '0700000000', method: 'MTN_MOMO');

      verify(
        () => client.rpc<void>(
          'claim_payout',
          params: {
            'p_payout_id': 'po1',
            'p_phone': '0700000000',
            'p_method': 'MTN_MOMO',
          },
        ),
      ).called(1);
    });
  });

  group('generate (RPC)', () {
    test('renvoie le nombre de gagnants', () async {
      when(
        () => client.rpc<dynamic>(
          'generate_payouts',
          params: any(named: 'params'),
        ),
      ).thenAnswer((_) => FakeQueryChain<dynamic>(Future<dynamic>.value(3)));
      expect(await repo.generate('c1'), 3);
    });

    test('résultat null → 0', () async {
      when(
        () => client.rpc<dynamic>(
          'generate_payouts',
          params: any(named: 'params'),
        ),
      ).thenAnswer((_) => FakeQueryChain<dynamic>(Future<dynamic>.value(null)));
      expect(await repo.generate('c1'), 0);
    });
  });

  group('markPaid (RPC)', () {
    test('appelle mark_payout_paid', () async {
      when(
        () => client.rpc<void>('mark_payout_paid', params: any(named: 'params')),
      ).thenAnswer((_) => FakeQueryChain<void>(Future<void>.value()));

      await repo.markPaid('po1');

      verify(
        () => client.rpc<void>(
          'mark_payout_paid',
          params: {'p_payout_id': 'po1'},
        ),
      ).called(1);
    });
  });

  group('listCompetitionsPendingPayout (RPC)', () {
    test('parse les compétitions à générer', () async {
      when(
        () => client.rpc<dynamic>('competitions_pending_payout'),
      ).thenAnswer(
        (_) => FakeQueryChain<dynamic>(
          Future<dynamic>.value([
            {
              'id': 'c1',
              'name': 'Coupe Arena',
              'prize_pool_local': 10000,
              'currency': 'XAF',
            },
          ]),
        ),
      );

      final list = await repo.listCompetitionsPendingPayout();
      expect(list, hasLength(1));
      expect(list.first.id, 'c1');
      expect(list.first.name, 'Coupe Arena');
      expect(list.first.prizePoolLocal, 10000);
    });
  });
}
