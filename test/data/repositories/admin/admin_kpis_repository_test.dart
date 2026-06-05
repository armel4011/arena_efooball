import 'package:arena/data/repositories/admin/admin_kpis_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../_supabase_mocks.dart';

void main() {
  late MockSupabaseClient client;
  late AdminKpisRepository repo;

  setUp(() {
    client = MockSupabaseClient();
    repo = AdminKpisRepository(client);
  });

  QueryProbe stub(String table, Object? result) =>
      stubFrom(client, table, result);

  group('fetch', () {
    test('compte les lignes par table + somme des payouts pending', () async {
      final comps = stub('competitions', [
        {'id': 'c1'},
        {'id': 'c2'},
      ]);
      final matches = stub('matches', [
        {'id': 'm1'},
      ]);
      final disputes = stub('disputes', [
        {'id': 'd1'},
        {'id': 'd2'},
        {'id': 'd3'},
      ]);
      final payouts = stub('payouts', [
        {'amount_local': 5000},
        {'amount_local': 2500},
      ]);

      final kpis = await repo.fetch();

      expect(kpis.activeCompetitions, 2);
      expect(kpis.liveMatches, 1);
      expect(kpis.openDisputes, 3);
      expect(kpis.pendingPayouts, 2);
      expect(kpis.pendingPayoutsAmountLocal, 7500);

      // competitions : statut in (registration_open, ongoing) + cap
      expect(comps.selectedColumns, 'id');
      expect(comps.hasFilter('in', 'status'), isTrue);
      expect(comps.hasFilter('limit', '_'), isTrue);

      // matches : eq status in_progress
      expect(matches.selectedColumns, 'id');
      expect(matches.filters.any((f) => f == 'eq:status=in_progress'), isTrue);

      // disputes : statut in (open, escalated)
      expect(disputes.hasFilter('in', 'status'), isTrue);

      // payouts : eq status pending + select amount_local
      expect(payouts.selectedColumns, 'amount_local');
      expect(payouts.filters.any((f) => f == 'eq:status=pending'), isTrue);
    });

    test('listes vides → tout à zéro', () async {
      stub('competitions', <Map<String, dynamic>>[]);
      stub('matches', <Map<String, dynamic>>[]);
      stub('disputes', <Map<String, dynamic>>[]);
      stub('payouts', <Map<String, dynamic>>[]);

      final kpis = await repo.fetch();

      expect(kpis.activeCompetitions, 0);
      expect(kpis.liveMatches, 0);
      expect(kpis.openDisputes, 0);
      expect(kpis.pendingPayouts, 0);
      expect(kpis.pendingPayoutsAmountLocal, 0);
    });

    test('amount_local non numérique ou null → ignoré dans la somme', () async {
      stub('competitions', <Map<String, dynamic>>[]);
      stub('matches', <Map<String, dynamic>>[]);
      stub('disputes', <Map<String, dynamic>>[]);
      stub('payouts', [
        {'amount_local': 1000},
        {'amount_local': null},
        {'amount_local': 'oops'},
        {'amount_local': 4000.5},
      ]);

      final kpis = await repo.fetch();

      expect(kpis.pendingPayouts, 4);
      expect(kpis.pendingPayoutsAmountLocal, 5000.5);
    });
  });
}
