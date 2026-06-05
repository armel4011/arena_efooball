import 'package:arena/data/repositories/admin_chat_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '_supabase_mocks.dart';

void main() {
  late MockSupabaseClient client;
  late AdminChatRepository repo;

  setUp(() {
    client = MockSupabaseClient();
    repo = AdminChatRepository(client);
  });

  QueryProbe stub(String table, Object? result) =>
      stubFrom(client, table, result);

  Map<String, dynamic> threadRow({
    String id = 'msg1',
    String recipientId = 'u1',
    String? text = 'Bonjour',
    String? imageUrl,
    String? caption,
    String sentAt = '2026-06-05T10:00:00.000Z',
    String? readAt,
    String? username = 'joueur1',
  }) =>
      {
        'id': id,
        'admin_id': 'a1',
        'recipient_id': recipientId,
        'text': text,
        'image_url': imageUrl,
        'caption': caption,
        'sent_at': sentAt,
        'read_at': readAt,
        'profiles': username == null ? null : {'username': username},
      };

  group('AdminChatMessage.fromJson', () {
    test('parse texte seul', () {
      final m = AdminChatMessage.fromJson(threadRow());
      expect(m.id, 'msg1');
      expect(m.adminId, 'a1');
      expect(m.recipientId, 'u1');
      expect(m.text, 'Bonjour');
      expect(m.imageUrl, isNull);
      expect(m.isUnread, isTrue);
      expect(m.hasImage, isFalse);
    });

    test('parse image + caption + read_at', () {
      final m = AdminChatMessage.fromJson(threadRow(
        text: null,
        imageUrl: 'https://x/y.png',
        caption: 'jolie',
        readAt: '2026-06-05T11:00:00.000Z',
      ));
      expect(m.imageUrl, 'https://x/y.png');
      expect(m.caption, 'jolie');
      expect(m.hasImage, isTrue);
      expect(m.isUnread, isFalse);
      expect(m.readAt, isNotNull);
    });
  });

  group('send', () {
    test('insert text trimme + admin_id + recipient_id', () async {
      final from = stub('admin_chat_messages', null);
      await repo.send(adminId: 'a1', recipientId: 'u1', text: '  salut  ');
      final v = from.insertedValues! as Map<String, dynamic>;
      expect(v['admin_id'], 'a1');
      expect(v['recipient_id'], 'u1');
      expect(v['text'], 'salut');
    });
  });

  group('markRead', () {
    test('update read_at (ISO) ciblant le message', () async {
      final from = stub('admin_chat_messages', null);
      await repo.markRead('msg1');
      expect(from.updatedValues!['read_at'], isA<String>());
      expect(from.filters.any((f) => f == 'eq:id=msg1'), isTrue);
    });
  });

  group('broadcast', () {
    test('liste vide -> aucune requete (early return)', () async {
      final from = stub('admin_chat_messages', null);
      await repo.broadcast(
        adminId: 'a1',
        recipientIds: const [],
        text: 'coucou',
      );
      // Early return : aucun insert n'a ete tente.
      expect(from.insertedValues, isNull);
    });

    test('ni texte ni image -> ArgumentError', () async {
      stub('admin_chat_messages', null);
      expect(
        () => repo.broadcast(adminId: 'a1', recipientIds: const ['u1']),
        throwsArgumentError,
      );
    });

    test('texte seul -> 1 row par recipient avec text trimme', () async {
      final from = stub('admin_chat_messages', null);
      await repo.broadcast(
        adminId: 'a1',
        recipientIds: const ['u1', 'u2'],
        text: '  hello  ',
      );
      final rows = from.insertedValues! as List;
      expect(rows, hasLength(2));
      final r0 = rows[0] as Map<String, dynamic>;
      expect(r0['admin_id'], 'a1');
      expect(r0['recipient_id'], 'u1');
      expect(r0['text'], 'hello');
      expect(r0.containsKey('image_url'), isFalse);
      expect((rows[1] as Map<String, dynamic>)['recipient_id'], 'u2');
    });

    test('image + caption -> image_url + caption, pas de text', () async {
      final from = stub('admin_chat_messages', null);
      await repo.broadcast(
        adminId: 'a1',
        recipientIds: const ['u1'],
        imageUrl: 'https://x/y.png',
        caption: '  vois ca  ',
      );
      final rows = from.insertedValues! as List;
      final r0 = rows[0] as Map<String, dynamic>;
      expect(r0['image_url'], 'https://x/y.png');
      expect(r0['caption'], 'vois ca');
      expect(r0.containsKey('text'), isFalse);
    });

    test('texte vide (espaces) seul -> ArgumentError', () async {
      stub('admin_chat_messages', null);
      expect(
        () => repo.broadcast(
          adminId: 'a1',
          recipientIds: const ['u1'],
          text: '   ',
        ),
        throwsArgumentError,
      );
    });
  });

  group('listAdminThreads', () {
    test('filtre admin_id + order sent_at desc', () async {
      final from = stub('admin_chat_messages', [threadRow()]);
      await repo.listAdminThreads('a1');
      expect(from.filters.any((f) => f == 'eq:admin_id=a1'), isTrue);
      expect(from.hasFilter('order', 'sent_at'), isTrue);
    });

    test('groupe par user, compte les non-lus, preview = caption/text/image',
        () async {
      final rows = [
        threadRow(
          id: 'm1',
          recipientId: 'u1',
          text: 'dernier',
          sentAt: '2026-06-05T12:00:00.000Z',
          readAt: null,
        ),
        threadRow(
          id: 'm2',
          recipientId: 'u1',
          text: 'ancien',
          sentAt: '2026-06-05T09:00:00.000Z',
          readAt: '2026-06-05T09:30:00.000Z',
        ),
        threadRow(
          id: 'm3',
          recipientId: 'u2',
          text: null,
          imageUrl: 'https://x/y.png',
          sentAt: '2026-06-05T08:00:00.000Z',
          readAt: null,
          username: 'joueur2',
        ),
      ];
      stub('admin_chat_messages', rows);
      final list = await repo.listAdminThreads('a1');
      // Le grouping conserve l'ordre d'arrivee (deja trie desc en DB).
      expect(list, hasLength(2));

      final t1 = list.firstWhere((t) => t.userId == 'u1');
      expect(t1.username, 'joueur1');
      expect(t1.lastMessage, 'dernier');
      expect(t1.unreadCount, 1);

      final t2 = list.firstWhere((t) => t.userId == 'u2');
      expect(t2.username, 'joueur2');
      expect(t2.lastMessage, '📷 Image');
      expect(t2.unreadCount, 1);
    });

    test('username absent -> Inconnu', () async {
      stub('admin_chat_messages', [threadRow(username: null)]);
      final list = await repo.listAdminThreads('a1');
      expect(list.first.username, 'Inconnu');
    });

    test('aucun message -> liste vide', () async {
      stub('admin_chat_messages', <Map<String, dynamic>>[]);
      expect(await repo.listAdminThreads('a1'), isEmpty);
    });
  });
}
