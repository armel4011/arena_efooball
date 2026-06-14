import 'package:arena/data/repositories/admin/admin_audit_log_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../_supabase_mocks.dart';

void main() {
  late MockSupabaseClient client;
  late AdminAuditLogRepository repo;

  setUp(() {
    client = MockSupabaseClient();
    repo = AdminAuditLogRepository(client);
  });

  QueryProbe stub(Object? result) =>
      stubFrom(client, 'admin_audit_log', result);

  Map<String, dynamic> logRow({
    String id = 'l1',
    String action = 'payout_validated',
    String? targetType = 'payout',
    String? targetId = 'po1',
  }) =>
      {
        'id': id,
        'admin_id': 'a1',
        'action': action,
        if (targetType != null) 'target_type': targetType,
        if (targetId != null) 'target_id': targetId,
        'before_state': {'status': 'pending'},
        'after_state': {'status': 'validated'},
        'created_at': '2026-06-01T10:00:00.000Z',
      };

  group('list', () {
    test('sans filtre → select all + order created_at desc + limit, parse',
        () async {
      final from = stub([logRow()]);
      final list = await repo.list();
      expect(list, hasLength(1));
      expect(list.first.id, 'l1');
      expect(list.first.adminId, 'a1');
      expect(list.first.action, 'payout_validated');
      expect(list.first.beforeState['status'], 'pending');
      expect(list.first.afterState['status'], 'validated');
      // tri descendant sur created_at + limite par défaut 50.
      expect(from.filters.any((f) => f == 'order:created_at=false'), isTrue);
      expect(from.filters.any((f) => f == 'limit:_=50'), isTrue);
    });

    test('liste vide → []', () async {
      stub(<Map<String, dynamic>>[]);
      expect(await repo.list(), isEmpty);
    });

    test('limit custom propagé', () async {
      final from = stub(<Map<String, dynamic>>[]);
      await repo.list(limit: 10);
      expect(from.filters.any((f) => f == 'limit:_=10'), isTrue);
    });

    test('periodDays → filtre gte sur created_at', () async {
      final from = stub(<Map<String, dynamic>>[]);
      await repo.list(periodDays: 7);
      expect(from.hasFilter('gte', 'created_at'), isTrue);
    });

    test('periodDays null → pas de filtre gte', () async {
      final from = stub(<Map<String, dynamic>>[]);
      await repo.list();
      expect(from.hasFilter('gte', 'created_at'), isFalse);
    });

    test('category payout → inFilter action sur les 3 actions payout',
        () async {
      final from = stub(<Map<String, dynamic>>[]);
      await repo.list(category: 'payout');
      expect(from.hasFilter('in', 'action'), isTrue);
      final f =
          from.filters.firstWhere((f) => f.startsWith('in:action='));
      expect(f, contains('payout_validated'));
      expect(f, contains('payout_refused'));
      expect(f, contains('payout_retried'));
    });

    test('category ban → inFilter action sur les actions ban', () async {
      final from = stub(<Map<String, dynamic>>[]);
      await repo.list(category: 'ban');
      final f =
          from.filters.firstWhere((f) => f.startsWith('in:action='));
      expect(f, contains('user_banned'));
      expect(f, contains('user_unbanned'));
      expect(f, contains('user_kyc_overridden'));
    });

    test('category inconnue → pas de filtre inFilter (actions vides)',
        () async {
      final from = stub(<Map<String, dynamic>>[]);
      await repo.list(category: 'inexistant');
      expect(from.hasFilter('in', 'action'), isFalse);
    });

    test('searchQuery → filtre or ilike action/target_id', () async {
      final from = stub(<Map<String, dynamic>>[]);
      await repo.list(searchQuery: 'ban');
      final orFilter =
          from.filters.firstWhere((f) => f.startsWith('or:'));
      // M-2 : la valeur est quotée (guillemets doubles) pour neutraliser
      // toute réécriture de la structure du filtre PostgREST `.or(...)`.
      expect(orFilter, contains('action.ilike."%ban%"'));
      expect(orFilter, contains('target_id::text.ilike."%ban%"'));
    });

    test('searchQuery vide (espaces) → pas de filtre or', () async {
      final from = stub(<Map<String, dynamic>>[]);
      await repo.list(searchQuery: '   ');
      expect(from.filters.any((f) => f.startsWith('or:')), isFalse);
    });

    test('combinaison période + catégorie + recherche', () async {
      final from = stub(<Map<String, dynamic>>[]);
      await repo.list(periodDays: 30, category: 'stream', searchQuery: 'cut');
      expect(from.hasFilter('gte', 'created_at'), isTrue);
      expect(from.hasFilter('in', 'action'), isTrue);
      expect(from.filters.any((f) => f.startsWith('or:')), isTrue);
    });
  });

  group('record', () {
    test('insert payload complet avec before/after state', () async {
      final from = stub(null);
      await repo.record(
        adminId: 'a1',
        action: 'payout_validated',
        targetType: 'payout',
        targetId: 'po1',
        beforeState: {'status': 'pending'},
        afterState: {'status': 'validated'},
      );
      final v = from.insertedValues! as Map<String, dynamic>;
      expect(v['admin_id'], 'a1');
      expect(v['action'], 'payout_validated');
      expect(v['target_type'], 'payout');
      expect(v['target_id'], 'po1');
      expect(v['before_state'], {'status': 'pending'});
      expect(v['after_state'], {'status': 'validated'});
    });

    test('insert minimal → champs optionnels absents', () async {
      final from = stub(null);
      await repo.record(adminId: 'a1', action: 'user_banned');
      final v = from.insertedValues! as Map<String, dynamic>;
      expect(v['admin_id'], 'a1');
      expect(v['action'], 'user_banned');
      expect(v.containsKey('target_type'), isFalse);
      expect(v.containsKey('target_id'), isFalse);
      expect(v.containsKey('before_state'), isFalse);
      expect(v.containsKey('after_state'), isFalse);
    });
  });
}
