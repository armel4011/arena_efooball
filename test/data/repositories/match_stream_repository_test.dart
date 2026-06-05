import 'package:arena/data/repositories/match_stream_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '_supabase_mocks.dart';

void main() {
  late MockSupabaseClient client;
  late MatchStreamRepository repo;

  setUp(() {
    client = MockSupabaseClient();
    repo = MatchStreamRepository(client);
  });

  QueryProbe stub(String table, Object? result) =>
      stubFrom(client, table, result);

  Map<String, dynamic> streamRow({
    String id = 's1',
    String matchId = 'm1',
    String playerId = 'p1',
    bool isPublic = false,
    bool isActive = true,
    String? url,
  }) =>
      {
        'id': id,
        'match_id': matchId,
        'player_id': playerId,
        'is_public': isPublic,
        'is_active': isActive,
        if (url != null) 'url': url,
        'started_at': '2026-06-01T10:00:00.000Z',
      };

  group('openSession', () {
    test('insert payload (privé + actif) + parse la row retournée', () async {
      final from = stub('streams', streamRow(url: 'chan'));
      final result = await repo.openSession(matchId: 'm1', playerId: 'p1');

      final v = from.insertedValues! as Map<String, dynamic>;
      expect(v['match_id'], 'm1');
      expect(v['player_id'], 'p1');
      expect(v['is_public'], false);
      expect(v['is_active'], true);
      // select().single() utilisés pour récupérer la row insérée.
      expect(from.hasFilter('single', '_'), isTrue);

      expect(result.id, 's1');
      expect(result.matchId, 'm1');
      expect(result.playerId, 'p1');
      expect(result.isPublic, false);
      expect(result.url, 'chan');
    });
  });

  group('markEnded', () {
    test('flip is_active=false + stamp ended_at ISO, cible le stream', () async {
      final from = stub('streams', null);
      await repo.markEnded('s1');

      final v = from.updatedValues!;
      expect(v['is_active'], false);
      expect(v['ended_at'], isA<String>());
      expect(v.containsKey('url'), isFalse);
      expect(from.filters.any((f) => f == 'eq:id=s1'), isTrue);
    });
  });

  group('attachUrl', () {
    test('update url seul, cible le stream', () async {
      final from = stub('streams', null);
      await repo.attachUrl('s1', 'https://x/clip.mp4');

      final v = from.updatedValues!;
      expect(v['url'], 'https://x/clip.mp4');
      expect(v.length, 1);
      expect(from.filters.any((f) => f == 'eq:id=s1'), isTrue);
    });
  });

  group('listForPlayer', () {
    test('filtre player_id + order started_at desc + limit + parse', () async {
      final from = stub('streams', [streamRow(), streamRow(id: 's2')]);
      final list = await repo.listForPlayer('p1', limit: 5);

      expect(list, hasLength(2));
      expect(list.first.id, 's1');
      expect(from.filters.any((f) => f == 'eq:player_id=p1'), isTrue);
      expect(from.hasFilter('order', 'started_at'), isTrue);
      expect(from.filters.any((f) => f == 'limit:_=5'), isTrue);
    });

    test('liste vide → []', () async {
      stub('streams', <Map<String, dynamic>>[]);
      expect(await repo.listForPlayer('p1'), isEmpty);
    });
  });

  group('setStreamingPublic', () {
    test('update is_public + cible le stream', () async {
      final from = stub('streams', null);
      await repo.setStreamingPublic(streamId: 's1', isPublic: true);

      final v = from.updatedValues!;
      expect(v['is_public'], true);
      expect(from.filters.any((f) => f == 'eq:id=s1'), isTrue);
    });
  });

  group('listActivePublic', () {
    test('filtre is_public + is_active + order + limit + parse', () async {
      final from = stub('streams', [streamRow(isPublic: true)]);
      final list = await repo.listActivePublic(limit: 30);

      expect(list, hasLength(1));
      expect(list.first.isPublic, true);
      expect(from.filters.any((f) => f == 'eq:is_public=true'), isTrue);
      expect(from.filters.any((f) => f == 'eq:is_active=true'), isTrue);
      expect(from.hasFilter('order', 'started_at'), isTrue);
      expect(from.filters.any((f) => f == 'limit:_=30'), isTrue);
    });

    test('liste vide → []', () async {
      stub('streams', <Map<String, dynamic>>[]);
      expect(await repo.listActivePublic(), isEmpty);
    });
  });
}
