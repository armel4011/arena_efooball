import 'package:arena/data/repositories/chat_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '_supabase_mocks.dart';

void main() {
  late MockSupabaseClient client;
  late ChatRepository repo;

  setUp(() {
    client = MockSupabaseClient();
    repo = ChatRepository(client);
  });

  QueryProbe stub(String table, Object? result) =>
      stubFrom(client, table, result);

  group('listMyFriendChannels', () {
    test('résout le peer (autre membre de la friendship) et filtre accepted',
        () async {
      final from = stub('chat_channels', [
        {
          'id': 'ch1',
          'friendship_id': 'f1',
          'friendships': {
            'requester_id': 'me',
            'addressee_id': 'peer',
            'status': 'accepted',
          },
          'chat_channel_user_state': <dynamic>[],
        },
      ]);

      final list = await repo.listMyFriendChannels('me');

      expect(list, hasLength(1));
      expect(list.first.channelId, 'ch1');
      expect(list.first.friendshipId, 'f1');
      expect(list.first.peerId, 'peer'); // requester == me → peer = addressee
      expect(from.filters.any((f) => f == 'eq:type=friend'), isTrue);
      expect(
        from.filters.any((f) => f == 'eq:friendships.status=accepted'),
        isTrue,
      );
    });

    test('saute les channels masqués pour moi (hidden=true)', () async {
      stub('chat_channels', [
        {
          'id': 'ch1',
          'friendship_id': 'f1',
          'friendships': {
            'requester_id': 'me',
            'addressee_id': 'peer',
            'status': 'accepted',
          },
          'chat_channel_user_state': [
            {'hidden': true},
          ],
        },
      ]);
      expect(await repo.listMyFriendChannels('me'), isEmpty);
    });

    test('friendships null → channel ignoré', () async {
      stub('chat_channels', [
        {'id': 'ch1', 'friendship_id': 'f1', 'friendships': null},
      ]);
      expect(await repo.listMyFriendChannels('me'), isEmpty);
    });
  });

  group('matchChannelIdsFor', () {
    test('liste vide → {} sans requête', () async {
      expect(await repo.matchChannelIdsFor(const []), isEmpty);
      verifyNever(() => client.from(any()));
    });

    test('mappe match_id → channel_id, filtre type=match + in', () async {
      final from = stub('chat_channels', [
        {'id': 'ch1', 'match_id': 'm1'},
        {'id': 'ch2', 'match_id': 'm2'},
      ]);
      final map = await repo.matchChannelIdsFor(['m1', 'm2']);
      expect(map, {'m1': 'ch1', 'm2': 'ch2'});
      expect(from.filters.any((f) => f == 'eq:type=match'), isTrue);
      expect(from.hasFilter('in', 'match_id'), isTrue);
    });
  });

  group('openedMatchChannelIds', () {
    test('liste vide → {} sans requête', () async {
      expect(await repo.openedMatchChannelIds(const []), isEmpty);
      verifyNever(() => client.from(any()));
    });

    test('renvoie les match_ids avec channel, saute les masqués', () async {
      stub('chat_channels', [
        {'id': 'ch1', 'match_id': 'm1', 'chat_channel_user_state': <dynamic>[]},
        {
          'id': 'ch2',
          'match_id': 'm2',
          'chat_channel_user_state': [
            {'hidden': true},
          ],
        },
      ]);
      final set = await repo.openedMatchChannelIds(['m1', 'm2']);
      expect(set, {'m1'});
    });
  });

  group('ensureMatchChannel', () {
    test('channel existant → renvoyé sans insert', () async {
      stub('chat_channels', {'id': 'ch1', 'type': 'match', 'match_id': 'm1'});
      final ch = await repo.ensureMatchChannel('m1');
      expect(ch.id, 'ch1');
      expect(ch.type, 'match');
    });

    test('aucun channel → insert puis renvoi du nouveau', () async {
      // 1er from() (maybeSingle) → null ; 2e from() (insert+single) → row.
      stubFromQueue(client, 'chat_channels', [
        null,
        {'id': 'ch9', 'type': 'match', 'match_id': 'm1'},
      ]);
      final ch = await repo.ensureMatchChannel('m1');
      expect(ch.id, 'ch9');
    });
  });

  group('sendMessage', () {
    test('contenu vide/espaces → aucun insert', () async {
      await repo.sendMessage(channelId: 'c1', senderId: 'me', content: '   ');
      verifyNever(() => client.from('chat_messages'));
    });

    test('trim + insert avec type text', () async {
      final from = stub('chat_messages', null);
      await repo.sendMessage(
        channelId: 'c1',
        senderId: 'me',
        content: '  salut  ',
      );
      final row = from.insertedValues! as Map<String, dynamic>;
      expect(row['channel_id'], 'c1');
      expect(row['sender_id'], 'me');
      expect(row['content'], 'salut');
      expect(row['type'], 'text');
    });

    test('cap le contenu à 2000 caractères', () async {
      final from = stub('chat_messages', null);
      await repo.sendMessage(
        channelId: 'c1',
        senderId: 'me',
        content: 'x' * 2500,
      );
      final row = from.insertedValues! as Map<String, dynamic>;
      expect((row['content'] as String).length, 2000);
    });
  });

  group('softDeleteMessage (modération)', () {
    test('pose deleted_at, vide content + media_url, cible le message',
        () async {
      final from = stub('chat_messages', null);
      await repo.softDeleteMessage('msg1');
      final values = from.updatedValues!;
      expect(values['deleted_at'], isA<String>());
      expect(values['content'], '');
      expect(values['media_url'], isNull);
      expect(from.filters.any((f) => f == 'eq:id=msg1'), isTrue);
    });
  });

  group('hideChannelForMe', () {
    test('non authentifié → no-op', () async {
      stubAuthUser(client, null);
      await repo.hideChannelForMe('c1');
      verifyNever(() => client.from('chat_channel_user_state'));
    });

    test('upsert hidden=true + cleared_at pour le user courant', () async {
      stubAuthUser(client, 'me');
      final from = stub('chat_channel_user_state', null);
      await repo.hideChannelForMe('c1');
      final values = from.upsertedValues! as Map<String, dynamic>;
      expect(values['user_id'], 'me');
      expect(values['channel_id'], 'c1');
      expect(values['hidden'], true);
      expect(values['cleared_at'], isA<String>());
    });
  });

  group('markChannelAsRead', () {
    test('upsert last_read_at', () async {
      stubAuthUser(client, 'me');
      final from = stub('chat_channel_user_state', null);
      await repo.markChannelAsRead('c1');
      final values = from.upsertedValues! as Map<String, dynamic>;
      expect(values['last_read_at'], isA<String>());
      expect(values['user_id'], 'me');
    });
  });

  group('getUnreadCounts', () {
    test('liste vide → {}', () async {
      expect(await repo.getUnreadCounts(const []), isEmpty);
    });

    test('non authentifié → {}', () async {
      stubAuthUser(client, null);
      expect(await repo.getUnreadCounts(['c1']), isEmpty);
    });

    test('compte les messages postérieurs au last_read, pas les miens',
        () async {
      stubAuthUser(client, 'me');
      stub('chat_channel_user_state', [
        {'channel_id': 'c1', 'last_read_at': '2026-01-02T00:00:00.000Z'},
      ]);
      stub('chat_messages', [
        // c1 : 1 après last_read (compté) + 1 avant (ignoré)
        {'channel_id': 'c1', 'created_at': '2026-01-03T00:00:00.000Z'},
        {'channel_id': 'c1', 'created_at': '2026-01-01T00:00:00.000Z'},
        // c2 : jamais lu → compté
        {'channel_id': 'c2', 'created_at': '2026-01-03T00:00:00.000Z'},
      ]);

      final counts = await repo.getUnreadCounts(['c1', 'c2']);
      expect(counts['c1'], 1);
      expect(counts['c2'], 1);
    });
  });

  group('myChatClearedAt', () {
    test('non authentifié → null', () async {
      stubAuthUser(client, null);
      expect(await repo.myChatClearedAt('c1'), isNull);
    });

    test('cleared_at présent → DateTime parsé', () async {
      stubAuthUser(client, 'me');
      stub('chat_channel_user_state', {
        'cleared_at': '2026-01-05T10:00:00.000Z',
      });
      final d = await repo.myChatClearedAt('c1');
      expect(d, DateTime.parse('2026-01-05T10:00:00.000Z'));
    });

    test('row sans cleared_at → null', () async {
      stubAuthUser(client, 'me');
      stub('chat_channel_user_state', {'cleared_at': null});
      expect(await repo.myChatClearedAt('c1'), isNull);
    });
  });

  group('ensureFriendChannel (RPC)', () {
    test('passe par ensure_friend_channel puis charge le channel', () async {
      when(
        () => client.rpc<String>(
          'ensure_friend_channel',
          params: any(named: 'params'),
        ),
      ).thenAnswer((_) => FakeQueryChain<String>(Future<String>.value('ch7')));
      stub('chat_channels', {'id': 'ch7', 'type': 'friend'});

      final ch = await repo.ensureFriendChannel('f1');

      expect(ch.id, 'ch7');
      verify(
        () => client.rpc<String>(
          'ensure_friend_channel',
          params: {'p_friendship_id': 'f1'},
        ),
      ).called(1);
    });
  });
}
