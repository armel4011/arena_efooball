import 'package:arena/data/repositories/reintegration_requests_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '_supabase_mocks.dart';

void main() {
  late MockSupabaseClient client;
  late ReintegrationRequestsRepository repo;

  setUp(() {
    client = MockSupabaseClient();
    repo = ReintegrationRequestsRepository(client);
  });

  QueryProbe stub(String table, Object? result) =>
      stubFrom(client, table, result);

  Map<String, dynamic> reqRow({String id = 'r1', String status = 'pending'}) =>
      {
        'id': id,
        'user_id': 'u1',
        'message': 'je conteste mon bannissement',
        'status': status,
        'created_at': '2026-06-01T10:00:00.000Z',
      };

  group('submit', () {
    test('insert message trimmé + user_id, parse la requête', () async {
      final from = stub('reintegration_requests', reqRow());
      final r = await repo.submit(userId: 'u1', message: '  je conteste  ');
      expect(r.id, 'r1');
      final inserted = from.insertedValues! as Map<String, dynamic>;
      expect(inserted['message'], 'je conteste');
      expect(inserted['user_id'], 'u1');
    });
  });

  group('latestForUser', () {
    test('aucune requête → null', () async {
      stub('reintegration_requests', <Map<String, dynamic>>[]);
      expect(await repo.latestForUser('u1'), isNull);
    });

    test('filtre user_id + order desc + parse', () async {
      final from = stub('reintegration_requests', [reqRow()]);
      final r = await repo.latestForUser('u1');
      expect(r!.id, 'r1');
      expect(from.filters.any((f) => f == 'eq:user_id=u1'), isTrue);
      expect(from.hasFilter('order', 'created_at'), isTrue);
    });
  });

  group('list', () {
    test('pendingOnly (défaut) → filtre status pending', () async {
      final from = stub('reintegration_requests', [reqRow()]);
      await repo.list();
      expect(from.filters.any((f) => f == 'eq:status=pending'), isTrue);
    });

    test('pendingOnly:false → pas de filtre status', () async {
      final from = stub('reintegration_requests', <Map<String, dynamic>>[]);
      await repo.list(pendingOnly: false);
      expect(from.hasFilter('eq', 'status'), isFalse);
    });
  });

  group('approve (déban via trigger)', () {
    test('status approved + resolved_at/by + raison si fournie', () async {
      final from = stub('reintegration_requests', null);
      await repo.approve(
        requestId: 'r1',
        adminId: 'a1',
        reason: 'ok cette fois',
      );
      final v = from.updatedValues!;
      expect(v['status'], 'approved');
      expect(v['resolved_by'], 'a1');
      expect(v['resolved_at'], isA<String>());
      expect(v['resolution_reason'], 'ok cette fois');
      expect(from.filters.any((f) => f == 'eq:id=r1'), isTrue);
    });

    test('raison vide/espaces → pas de resolution_reason', () async {
      final from = stub('reintegration_requests', null);
      await repo.approve(requestId: 'r1', adminId: 'a1', reason: '   ');
      expect(from.updatedValues!.containsKey('resolution_reason'), isFalse);
    });
  });

  group('reject', () {
    test('status rejected + raison trimmée', () async {
      final from = stub('reintegration_requests', null);
      await repo.reject(requestId: 'r1', adminId: 'a1', reason: '  récidive  ');
      final v = from.updatedValues!;
      expect(v['status'], 'rejected');
      expect(v['resolution_reason'], 'récidive');
    });
  });
}
