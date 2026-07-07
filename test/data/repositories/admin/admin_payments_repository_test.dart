import 'package:arena/data/repositories/admin/admin_payments_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../_supabase_mocks.dart';

void main() {
  late MockSupabaseClient client;
  late AdminPaymentsRepository repo;

  setUp(() {
    client = MockSupabaseClient();
    repo = AdminPaymentsRepository(client);
  });

  QueryProbe stub(String table, Object? result) =>
      stubFrom(client, table, result);

  Map<String, dynamic> paymentRow({
    String id = 'pay1',
    String status = 'awaiting_admin',
    String? username = 'bob',
    String? compName = 'Coupe Arena',
  }) =>
      {
        'id': id,
        'user_id': 'u1',
        'competition_id': 'c1',
        'amount_local': 1000,
        'status': status,
        'created_at': '2026-06-01T10:00:00.000Z',
        if (username != null) 'profiles': {'username': username},
        if (compName != null) 'competitions': {'name': compName},
      };

  group('listPending', () {
    test('filtre awaiting_admin + parse joints username/compétition',
        () async {
      final from = stub('payments', [paymentRow()]);
      final list = await repo.listPending();
      expect(list, hasLength(1));
      expect(list.first.payment.id, 'pay1');
      expect(list.first.username, 'bob');
      expect(list.first.competitionName, 'Coupe Arena');
      expect(from.filters.any((f) => f == 'eq:status=awaiting_admin'), isTrue);
      expect(from.hasFilter('order', 'created_at'), isTrue);
    });

    test('joints absents → fallbacks « — »', () async {
      stub('payments', [paymentRow(username: null, compName: null)]);
      final list = await repo.listPending();
      expect(list.first.username, '—');
      expect(list.first.competitionName, '—');
    });
  });

  group('listHistory', () {
    test('inFilter succeeded/rejected/refunded + order updated_at desc',
        () async {
      final from = stub('payments', <Map<String, dynamic>>[]);
      await repo.listHistory();
      expect(from.hasFilter('in', 'status'), isTrue);
      expect(from.hasFilter('order', 'updated_at'), isTrue);
    });
  });

  group('listRefundPending', () {
    test('filtre refund_pending', () async {
      final from = stub('payments', <Map<String, dynamic>>[]);
      await repo.listRefundPending();
      expect(from.filters.any((f) => f == 'eq:status=refund_pending'), isTrue);
    });
  });

  group('validate', () {
    test(
        'status succeeded + admin + validated_at, filtre id + awaiting_admin, '
        'retourne true si une ligne est affectée', () async {
      // Idempotence : l'UPDATE ne cible qu'un paiement encore awaiting_admin,
      // puis .select('id') renvoie la/les ligne(s) affectée(s).
      final from = stub('payments', [
        {'id': 'pay1'},
      ]);
      final applied = await repo.validate(paymentId: 'pay1', adminId: 'a1');
      expect(applied, isTrue);
      final v = from.updatedValues!;
      expect(v['status'], 'succeeded');
      expect(v['validated_by_admin_id'], 'a1');
      expect(v['validated_at'], isA<String>());
      expect(from.filters.any((f) => f == 'eq:id=pay1'), isTrue);
      expect(from.filters.any((f) => f == 'eq:status=awaiting_admin'), isTrue);
    });

    test('retourne false si aucune ligne affectée (paiement déjà traité)',
        () async {
      stub('payments', <Map<String, dynamic>>[]);
      final applied = await repo.validate(paymentId: 'pay1', adminId: 'a1');
      expect(applied, isFalse);
    });
  });

  group('reject', () {
    test('status rejected + justification, filtre awaiting_admin, retourne true',
        () async {
      final from = stub('payments', [
        {'id': 'pay1'},
      ]);
      final applied = await repo.reject(
        paymentId: 'pay1',
        adminId: 'a1',
        reason: 'preuve illisible',
      );
      expect(applied, isTrue);
      final v = from.updatedValues!;
      expect(v['status'], 'rejected');
      expect(v['rejection_reason'], 'preuve illisible');
      expect(v['validated_by_admin_id'], 'a1');
      expect(from.filters.any((f) => f == 'eq:status=awaiting_admin'), isTrue);
    });

    test("retourne false si le paiement n'est plus awaiting_admin", () async {
      stub('payments', <Map<String, dynamic>>[]);
      final applied = await repo.reject(
        paymentId: 'pay1',
        adminId: 'a1',
        reason: 'x',
      );
      expect(applied, isFalse);
    });
  });

  group('markRefunded (RPC)', () {
    test('délègue à mark_payment_refunded', () async {
      when(
        () => client.rpc<void>(
          'mark_payment_refunded',
          params: any(named: 'params'),
        ),
      ).thenAnswer((_) => FakeQueryChain<void>(Future<void>.value()));

      await repo.markRefunded('pay1');

      verify(
        () => client.rpc<void>(
          'mark_payment_refunded',
          params: {'p_payment_id': 'pay1'},
        ),
      ).called(1);
    });
  });
}
