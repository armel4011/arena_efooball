import 'package:arena/data/repositories/stream_comment_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '_supabase_mocks.dart';

void main() {
  late MockSupabaseClient client;
  late StreamCommentRepository repo;

  setUp(() {
    client = MockSupabaseClient();
    repo = StreamCommentRepository(client);
  });

  QueryProbe stub(String table, Object? result) =>
      stubFrom(client, table, result);

  Map<String, dynamic> commentRow({
    String id = 'sc1',
    String matchId = 'm1',
    String? authorId = 'u1',
    String content = 'gg',
  }) =>
      {
        'id': id,
        'match_id': matchId,
        'author_id': authorId,
        'content': content,
        'created_at': '2026-06-01T10:00:00.000Z',
      };

  group('fetchRecent', () {
    test('filtre match_id + order created_at + limit 100 + parse', () async {
      final from = stub('stream_comments', [
        commentRow(),
        commentRow(id: 'sc2', authorId: null, content: 'salut'),
      ]);

      final list = await repo.fetchRecent('m1');

      expect(list, hasLength(2));
      expect(list.first.id, 'sc1');
      expect(list.first.matchId, 'm1');
      expect(list.first.authorId, 'u1');
      expect(list.first.content, 'gg');
      // author_id null toléré (commentaire anonyme / système).
      expect(list[1].authorId, isNull);
      expect(from.filters.any((f) => f == 'eq:match_id=m1'), isTrue);
      expect(from.hasFilter('order', 'created_at'), isTrue);
      expect(from.filters.any((f) => f == 'limit:_=100'), isTrue);
    });

    test('aucune ligne → liste vide', () async {
      stub('stream_comments', <Map<String, dynamic>>[]);
      expect(await repo.fetchRecent('m1'), isEmpty);
    });
  });

  group('post', () {
    test('non authentifié → StateError sans requête', () async {
      stubAuthUser(client, null);
      await expectLater(
        repo.post(matchId: 'm1', content: 'hello'),
        throwsA(isA<StateError>()),
      );
      verifyNever(() => client.from(any()));
    });

    test('contenu vide après trim → no-op (aucune insertion)', () async {
      stubAuthUser(client, 'u1');
      await repo.post(matchId: 'm1', content: '   ');
      verifyNever(() => client.from(any()));
    });

    test('insert match_id + author_id (user courant) + content trimmé',
        () async {
      stubAuthUser(client, 'u1');
      final from = stub('stream_comments', null);

      await repo.post(matchId: 'm1', content: '  gg wp  ');

      final v = from.insertedValues! as Map<String, dynamic>;
      expect(v['match_id'], 'm1');
      expect(v['author_id'], 'u1');
      expect(v['content'], 'gg wp');
    });
  });
}
