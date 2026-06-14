import 'package:arena/data/repositories/admin/admin_matches_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

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

  group('setManualStreaming', () {
    test(
        'activation sans row existante → matches is_streamed=true + INSERT '
        'streams public/actif pour le home player', () async {
      final matchesProbe = stubFrom(client, 'matches', null);
      // 1er from('streams') = SELECT (maybeSingle → null) ; 2e = INSERT.
      final streamsProbes = <QueryProbe>[];
      var i = 0;
      when(() => client.from('streams')).thenAnswer((_) {
        // SELECT renvoie null (aucune row active), INSERT renvoie null.
        final from = FakeFromBuilder(Future<dynamic>.value(null));
        streamsProbes.add(from.probe);
        i++;
        return from;
      });

      await repo.setManualStreaming(
        matchId: 'm1',
        homePlayerId: 'p1',
        enabled: true,
        adminId: 'a1',
      );

      // matches : flag + métadonnées manual_admin.
      expect(matchesProbe.updatedValues!['is_streamed'], true);
      expect(
        matchesProbe.updatedValues!['streaming_activation_type'],
        'manual_admin',
      );

      // streams : 2 appels (SELECT puis INSERT).
      expect(i, 2);
      final selectProbe = streamsProbes[0];
      expect(selectProbe.filters.any((f) => f == 'eq:match_id=m1'), isTrue);
      expect(selectProbe.filters.any((f) => f == 'eq:player_id=p1'), isTrue);
      expect(selectProbe.filters.any((f) => f == 'eq:is_active=true'), isTrue);
      expect(selectProbe.hasFilter('maybeSingle', '_'), isTrue);

      final insertProbe = streamsProbes[1];
      final inserted = insertProbe.insertedValues! as Map<String, dynamic>;
      expect(inserted['match_id'], 'm1');
      expect(inserted['player_id'], 'p1');
      expect(inserted['is_public'], true);
      expect(inserted['is_active'], true);
    });

    test(
        'activation avec row active existante → UPDATE is_public=true sur la '
        'row, sans INSERT', () async {
      stubFrom(client, 'matches', null);
      final streamsProbes = <QueryProbe>[];
      var i = 0;
      when(() => client.from('streams')).thenAnswer((_) {
        // SELECT renvoie une row {id: s9}, UPDATE renvoie null.
        final result = i == 0 ? {'id': 's9'} : null;
        final from = FakeFromBuilder(Future<dynamic>.value(result));
        streamsProbes.add(from.probe);
        i++;
        return from;
      });

      await repo.setManualStreaming(
        matchId: 'm1',
        homePlayerId: 'p1',
        enabled: true,
        adminId: 'a1',
      );

      expect(i, 2);
      final updateProbe = streamsProbes[1];
      expect(updateProbe.updatedValues!['is_public'], true);
      expect(updateProbe.filters.any((f) => f == 'eq:id=s9'), isTrue);
      expect(updateProbe.insertedValues, isNull);
    });

    test(
        'désactivation → matches is_streamed=false + UPDATE streams '
        'is_public=false sur le match', () async {
      final matchesProbe = stubFrom(client, 'matches', null);
      final streamsProbe = stubFrom(client, 'streams', null);

      await repo.setManualStreaming(
        matchId: 'm1',
        homePlayerId: 'p1',
        enabled: false,
        adminId: 'a1',
      );

      expect(matchesProbe.updatedValues!['is_streamed'], false);
      expect(
        matchesProbe.updatedValues!['streaming_activation_type'],
        isNull,
      );
      expect(streamsProbe.updatedValues!['is_public'], false);
      expect(streamsProbe.filters.any((f) => f == 'eq:match_id=m1'), isTrue);
      expect(streamsProbe.filters.any((f) => f == 'eq:is_public=true'), isTrue);
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
