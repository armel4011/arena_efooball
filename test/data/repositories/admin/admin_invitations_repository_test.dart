import 'package:arena/data/models/user_role.dart';
import 'package:arena/data/repositories/admin/admin_invitations_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../_supabase_mocks.dart';

void main() {
  late MockSupabaseClient client;
  late AdminInvitationsRepository repo;

  setUp(() {
    client = MockSupabaseClient();
    repo = AdminInvitationsRepository(client);
  });

  QueryProbe stub(String table, Object? result) =>
      stubFrom(client, table, result);

  Map<String, dynamic> codeRow({String id = 'ic1'}) => {
        'id': id,
        'code': 'ABCD-EFGH-JKMN',
        'role': 'admin',
        'max_uses': 1,
        'uses_count': 0,
        'created_at': '2026-06-01T10:00:00.000Z',
      };

  group('create', () {
    test('génère un code XXXX-XXXX-XXXX + insère role/generated_by/max_uses',
        () async {
      final from = stub('invitation_codes', codeRow());
      await repo.create(generatedBy: 'a1', role: UserRole.admin, maxUses: 3);
      final ins = from.insertedValues! as Map<String, dynamic>;
      expect(ins['generated_by'], 'a1');
      expect(ins['role'], UserRole.admin.value);
      expect(ins['max_uses'], 3);
      expect(
        ins['code'] as String,
        matches(RegExp(r'^[A-Z2-9]{4}-[A-Z2-9]{4}-[A-Z2-9]{4}$')),
      );
      // Pas d'email cible quand non fourni.
      expect(ins.containsKey('target_email'), isFalse);
    });

    test('target_email trimmé + lowercased si fourni', () async {
      final from = stub('invitation_codes', codeRow());
      await repo.create(
        generatedBy: 'a1',
        role: UserRole.admin,
        targetEmail: '  BOB@X.COM ',
      );
      expect((from.insertedValues! as Map)['target_email'], 'bob@x.com');
    });

    test('périmètre pays/sections écrit seulement si non vide (VOLET 3)',
        () async {
      final from = stub('invitation_codes', codeRow());
      await repo.create(
        generatedBy: 'a1',
        role: UserRole.admin,
        allowedCountryCodes: const ['CM', 'SN'],
        allowedSections: const ['payouts'],
      );
      final ins = from.insertedValues! as Map<String, dynamic>;
      expect(ins['allowed_country_codes'], const ['CM', 'SN']);
      expect(ins['allowed_sections'], const ['payouts']);
    });

    test('périmètre vide/null → clés absentes (= aucune restriction)',
        () async {
      final from = stub('invitation_codes', codeRow());
      await repo.create(
        generatedBy: 'a1',
        role: UserRole.admin,
        allowedCountryCodes: const [],
        allowedSections: null,
      );
      final ins = from.insertedValues! as Map<String, dynamic>;
      expect(ins.containsKey('allowed_country_codes'), isFalse);
      expect(ins.containsKey('allowed_sections'), isFalse);
    });
  });

  group('markUsed', () {
    test('stamp used_at/used_by + uses_count=1', () async {
      final from = stub('invitation_codes', null);
      await repo.markUsed(codeId: 'ic1', userId: 'u1');
      final v = from.updatedValues!;
      expect(v['used_by'], 'u1');
      expect(v['uses_count'], 1);
      expect(v['used_at'], isA<String>());
      expect(from.filters.any((f) => f == 'eq:id=ic1'), isTrue);
    });
  });

  group('revoke', () {
    test('expire le code (jamais de DELETE car FK)', () async {
      final from = stub('invitation_codes', null);
      await repo.revoke('ic1');
      expect(from.updatedValues!['expires_at'], isA<String>());
      expect(from.filters.any((f) => f == 'eq:id=ic1'), isTrue);
    });
  });

  group('delete', () {
    test('supprime le code ciblé', () async {
      final from = stub('invitation_codes', null);
      await repo.delete('ic1');
      expect(from.filters.any((f) => f == 'eq:id=ic1'), isTrue);
    });
  });

  group('listAll', () {
    test('order created_at desc + parse', () async {
      final from = stub('invitation_codes', [codeRow()]);
      final list = await repo.listAll();
      expect(list, hasLength(1));
      expect(from.hasFilter('order', 'created_at'), isTrue);
    });
  });
}
