import 'package:arena/data/repositories/admin/admin_payouts_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../_supabase_mocks.dart';

void main() {
  late MockSupabaseClient client;
  late AdminPayoutsRepository repo;

  setUp(() {
    client = MockSupabaseClient();
    repo = AdminPayoutsRepository(client);
  });

  QueryProbe stub(String table, Object? result) =>
      stubFrom(client, table, result);

  Map<String, dynamic> payoutRow({
    String id = 'po1',
    String status = 'pending_admin_validation',
    double amountLocal = 5000,
  }) =>
      {
        'id': id,
        'user_id': 'u1',
        'competition_id': 'c1',
        'amount_local': amountLocal,
        'status': status,
        'created_at': '2026-06-01T10:00:00.000Z',
      };

  group('listAll', () {
    test('order created_at desc + parse, sans filtre status', () async {
      final from = stub('payouts', [
        payoutRow(id: 'po1', status: 'pending_admin_validation'),
        payoutRow(id: 'po2', status: 'validated'),
      ]);
      final list = await repo.listAll();
      expect(list, hasLength(2));
      expect(list.first.id, 'po1');
      expect(list.first.amountLocal, 5000);
      expect(from.hasFilter('order', 'created_at'), isTrue);
      // ordre desc → ascending == false
      expect(from.filters.any((f) => f == 'order:created_at=false'), isTrue);
    });

    test('filtre status appliqué côté client', () async {
      stub('payouts', [
        payoutRow(id: 'po1', status: 'pending_admin_validation'),
        payoutRow(id: 'po2', status: 'validated'),
        payoutRow(id: 'po3', status: 'pending_admin_validation'),
      ]);
      final list = await repo.listAll(status: 'pending_admin_validation');
      expect(list, hasLength(2));
      expect(list.every((p) => p.status == 'pending_admin_validation'), isTrue);
      expect(list.map((p) => p.id), containsAll(<String>['po1', 'po3']));
    });

    test('liste vide → []', () async {
      stub('payouts', <Map<String, dynamic>>[]);
      expect(await repo.listAll(), isEmpty);
      expect(await repo.listAll(status: 'validated'), isEmpty);
    });

    test('aucun row ne matche le status → []', () async {
      stub('payouts', [payoutRow(status: 'validated')]);
      expect(await repo.listAll(status: 'cancelled'), isEmpty);
    });
  });

  group('validate', () {
    test('status validated + stamp admin/justification + cible le payout',
        () async {
      final from = stub('payouts', null);
      await repo.validate(
        payoutId: 'po1',
        adminId: 'a1',
        justification: 'KYC OK',
      );
      final v = from.updatedValues!;
      expect(v['status'], 'validated');
      expect(v['validated_by_admin_id'], 'a1');
      expect(v['validation_justification'], 'KYC OK');
      expect(v['validated_at'], isA<String>());
      expect(from.filters.any((f) => f == 'eq:id=po1'), isTrue);
    });
  });

  group('refuse', () {
    test('status cancelled + stamp admin/justification + cible le payout',
        () async {
      final from = stub('payouts', null);
      await repo.refuse(
        payoutId: 'po1',
        adminId: 'a1',
        justification: 'Suspicion triche',
      );
      final v = from.updatedValues!;
      expect(v['status'], 'cancelled');
      expect(v['validated_by_admin_id'], 'a1');
      expect(v['validation_justification'], 'Suspicion triche');
      expect(v['validated_at'], isA<String>());
      expect(from.filters.any((f) => f == 'eq:id=po1'), isTrue);
    });
  });
}
