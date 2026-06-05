import 'package:arena/data/repositories/admin/admin_matches_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../_supabase_mocks.dart';

void main() {
  late MockSupabaseClient client;
  late AdminMatchesRepository repo;

  setUp(() {
    client = MockSupabaseClient();
    repo = AdminMatchesRepository(client);
  });

  QueryProbe stub(String table, Object? result) =>
      stubFrom(client, table, result);

  group('setVerdict (autorité admin)', () {
    test('stamp score/winner/completed + finished_at, cible le match',
        () async {
      final from = stub('matches', null);
      await repo.setVerdict(
        matchId: 'm1',
        scoreP1: 2,
        scoreP2: 1,
        winnerId: 'p1',
      );
      final v = from.updatedValues!;
      expect(v['score1'], 2);
      expect(v['score2'], 1);
      expect(v['winner_id'], 'p1');
      expect(v['status'], 'completed');
      expect(v['finished_at'], isA<String>());
      expect(from.filters.any((f) => f == 'eq:id=m1'), isTrue);
    });

    test('match nul (sans gagnant) → winner_id null', () async {
      final from = stub('matches', null);
      await repo.setVerdict(matchId: 'm1', scoreP1: 1, scoreP2: 1);
      expect(from.updatedValues!['winner_id'], isNull);
      expect(from.updatedValues!['status'], 'completed');
    });
  });

  group('cancel', () {
    test('status cancelled + finished_at, sans toucher au winner', () async {
      final from = stub('matches', null);
      await repo.cancel('m1');
      final v = from.updatedValues!;
      expect(v['status'], 'cancelled');
      expect(v['finished_at'], isA<String>());
      expect(v.containsKey('winner_id'), isFalse);
      expect(from.filters.any((f) => f == 'eq:id=m1'), isTrue);
    });
  });

  group('setStreamingEnabled', () {
    test('activation → flag + type manual_admin + admin + horodatage',
        () async {
      final from = stub('matches', null);
      await repo.setStreamingEnabled(
        matchId: 'm1',
        enabled: true,
        adminId: 'a1',
      );
      final v = from.updatedValues!;
      expect(v['is_streamed'], true);
      expect(v['streaming_activation_type'], 'manual_admin');
      expect(v['streaming_activated_by_admin_id'], 'a1');
      expect(v['streaming_activated_at'], isA<String>());
    });

    test('désactivation → flag false + champs streaming remis à null',
        () async {
      final from = stub('matches', null);
      await repo.setStreamingEnabled(
        matchId: 'm1',
        enabled: false,
        adminId: 'a1',
      );
      final v = from.updatedValues!;
      expect(v['is_streamed'], false);
      expect(v['streaming_activation_type'], isNull);
      expect(v['streaming_activated_by_admin_id'], isNull);
      expect(v['streaming_activated_at'], isNull);
    });
  });

  group('reschedule', () {
    test('stamp scheduled_at (UTC ISO) + repasse en scheduled', () async {
      final from = stub('matches', null);
      final when = DateTime.utc(2026, 7, 1, 18);
      await repo.reschedule(matchId: 'm1', scheduledAt: when);
      expect(from.updatedValues!['status'], 'scheduled');
      expect(
        from.updatedValues!['scheduled_at'],
        when.toUtc().toIso8601String(),
      );
    });
  });
}
