import 'package:arena/data/models/friendship.dart';
import 'package:arena/data/repositories/friends_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '_supabase_mocks.dart';

void main() {
  late MockSupabaseClient client;
  late FriendsRepository repo;

  setUp(() {
    client = MockSupabaseClient();
    repo = FriendsRepository(client);
  });

  QueryProbe stub(String table, Object? result) =>
      stubFrom(client, table, result);

  Map<String, dynamic> friendshipRow({
    String id = 'f1',
    String requester = 'me',
    String addressee = 'other',
    String status = 'accepted',
    String? blockedBy,
  }) =>
      {
        'id': id,
        'requester_id': requester,
        'addressee_id': addressee,
        'status': status,
        'blocked_by': blockedBy,
      };

  Map<String, dynamic> profileRow({
    required String id,
    required String username,
  }) =>
      {
        'id': id,
        'username': username,
        'country_code': 'CM',
        'avatar_color': '#4C7AFF',
        'role': 'player',
      };

  group('getById', () {
    test('row → Friendship parsée', () async {
      stub('friendships', friendshipRow(id: 'f9', status: 'pending'));
      final f = await repo.getById('f9');
      expect(f, isNotNull);
      expect(f!.id, 'f9');
      expect(f.isPending, isTrue);
    });

    test('row null → null', () async {
      stub('friendships', null);
      expect(await repo.getById('absent'), isNull);
    });
  });

  group('findBetween', () {
    test('utilise un OR symétrique requester/addressee + limit', () async {
      final from = stub('friendships', [friendshipRow()]);
      final f = await repo.findBetween(me: 'me', target: 'other');
      expect(f, isNotNull);
      // Le filtre OR doit mentionner les deux sens de la paire.
      final orFilter = from.filters.firstWhere((s) => s.startsWith('or:'));
      expect(orFilter, contains('requester_id.eq.me'));
      expect(orFilter, contains('addressee_id.eq.other'));
      expect(orFilter, contains('requester_id.eq.other'));
    });

    test('liste vide → null', () async {
      stub('friendships', <Map<String, dynamic>>[]);
      expect(await repo.findBetween(me: 'me', target: 'x'), isNull);
    });
  });

  group('listAccepted', () {
    test('filtre status accepted + OR sur me, parse les rows', () async {
      final from = stub('friendships', [
        friendshipRow(id: 'a'),
        friendshipRow(id: 'b'),
      ]);
      final list = await repo.listAccepted('me');
      expect(list, hasLength(2));
      expect(list.every((f) => f.isAccepted), isTrue);
      expect(
        from.filters.any((f) => f == 'eq:status=accepted'),
        isTrue,
      );
    });
  });

  group('listIncomingPending', () {
    test('filtre addressee = me + status pending', () async {
      final from = stub('friendships', [
        friendshipRow(id: 'p', status: 'pending'),
      ]);
      final list = await repo.listIncomingPending('me');
      expect(list, hasLength(1));
      expect(from.filters.any((f) => f == 'eq:addressee_id=me'), isTrue);
      expect(from.filters.any((f) => f == 'eq:status=pending'), isTrue);
    });
  });

  group('listOutgoingPending', () {
    test('filtre requester = me + status pending', () async {
      final from = stub('friendships', <Map<String, dynamic>>[]);
      await repo.listOutgoingPending('me');
      expect(from.filters.any((f) => f == 'eq:requester_id=me'), isTrue);
      expect(from.filters.any((f) => f == 'eq:status=pending'), isTrue);
    });
  });

  group('listBlockedByMe', () {
    test('filtre status blocked + blocked_by = me', () async {
      final from = stub('friendships', [
        friendshipRow(id: 'b', status: 'blocked', blockedBy: 'me'),
      ]);
      final list = await repo.listBlockedByMe('me');
      expect(list, hasLength(1));
      expect(from.filters.any((f) => f == 'eq:status=blocked'), isTrue);
      expect(from.filters.any((f) => f == 'eq:blocked_by=me'), isTrue);
    });
  });

  group('resolvePeers', () {
    test('liste vide → [] sans requête', () async {
      final result = await repo.resolvePeers(me: 'me', friendships: const []);
      expect(result, isEmpty);
      verifyNever(() => client.from(any()));
    });

    test('résout les peers via la vue publique (colonnes restreintes)',
        () async {
      final from = stub('public_profiles', [
        profileRow(id: 'other', username: 'pote'),
      ]);
      final fs = [friendshipRow()];
      final friendships = [Friendship.fromJson(fs.first)];

      final pairs = await repo.resolvePeers(me: 'me', friendships: friendships);

      expect(pairs, hasLength(1));
      expect(pairs.first.$1.id, 'f1');
      expect(pairs.first.$2.id, 'other');
      expect(pairs.first.$2.username, 'pote');
      // Sélection partielle : ni email ni stats lourdes.
      expect(from.selectedColumns, isNot(contains('email')));
      expect(from.selectedColumns, isNot(contains('stats')));
      expect(from.hasFilter('in', 'id'), isTrue);
    });

    test('peer introuvable → friendship omise de la sortie', () async {
      stub('public_profiles', <Map<String, dynamic>>[]);
      final friendships = [Friendship.fromJson(friendshipRow())];
      final pairs = await repo.resolvePeers(me: 'me', friendships: friendships);
      expect(pairs, isEmpty);
    });
  });

  group('searchByUsername', () {
    test('query < 2 caractères → [] sans requête', () async {
      expect(
        await repo.searchByUsername(query: 'a', me: 'me'),
        isEmpty,
      );
      verifyNever(() => client.from(any()));
    });

    test('ilike sur la vue publique + exclusions (actif, non banni, pas moi)',
        () async {
      final from = stub('public_profiles', [
        profileRow(id: 'u2', username: 'bob'),
      ]);
      final res = await repo.searchByUsername(query: 'bo', me: 'me');
      expect(res, hasLength(1));
      expect(res.first.username, 'bob');
      expect(from.hasFilter('ilike', 'username'), isTrue);
      expect(from.filters.any((f) => f == 'eq:is_active=true'), isTrue);
      expect(from.filters.any((f) => f == 'eq:permanent_ban=false'), isTrue);
      expect(from.filters.any((f) => f == 'neq:id=me'), isTrue);
    });

    test('échappe le % dans la query (anti-wildcard injection)', () async {
      final from = stub('public_profiles', <Map<String, dynamic>>[]);
      await repo.searchByUsername(query: '50%off', me: 'me');
      final ilike = from.filters.firstWhere((f) => f.startsWith('ilike:'));
      expect(ilike, contains(r'50\%off'));
    });
  });

  group('findByUsername', () {
    test('chaîne vide → null sans requête', () async {
      expect(await repo.findByUsername('  '), isNull);
      verifyNever(() => client.from(any()));
    });

    test('row → Profile parsé via la vue publique', () async {
      final from = stub('public_profiles', profileRow(id: 'u1', username: 'x'));
      final p = await repo.findByUsername('x');
      expect(p, isNotNull);
      expect(p!.username, 'x');
      expect(from.hasFilter('ilike', 'username'), isTrue);
      expect(from.filters.any((f) => f == 'eq:is_active=true'), isTrue);
    });

    test('row null → null', () async {
      stub('public_profiles', null);
      expect(await repo.findByUsername('ghost'), isNull);
    });
  });

  group('mutations RPC', () {
    test('sendRequest appelle send_friend_request et renvoie le résultat',
        () async {
      when(
        () => client.rpc<String>(
          'send_friend_request',
          params: any(named: 'params'),
        ),
      ).thenAnswer((_) => FakeQueryChain<String>(Future<String>.value('f-new')));

      final id = await repo.sendRequest('target');
      expect(id, 'f-new');
      verify(
        () => client.rpc<String>(
          'send_friend_request',
          params: {'p_target': 'target'},
        ),
      ).called(1);
    });

    test('accept appelle accept_friend_request avec le friendship_id',
        () async {
      when(
        () => client.rpc<void>(
          'accept_friend_request',
          params: any(named: 'params'),
        ),
      ).thenAnswer((_) => FakeQueryChain<void>(Future<void>.value()));

      await repo.accept('f1');
      verify(
        () => client.rpc<void>(
          'accept_friend_request',
          params: {'p_friendship_id': 'f1'},
        ),
      ).called(1);
    });

    test('block appelle block_user avec la cible', () async {
      when(
        () => client.rpc<void>('block_user', params: any(named: 'params')),
      ).thenAnswer((_) => FakeQueryChain<void>(Future<void>.value()));

      await repo.block('bad');
      verify(
        () => client.rpc<void>('block_user', params: {'p_target': 'bad'}),
      ).called(1);
    });
  });
}
