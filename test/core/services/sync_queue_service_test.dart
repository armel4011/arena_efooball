import 'package:arena/core/services/network_status_service.dart';
import 'package:arena/core/services/sync_queue_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/_supabase_mocks.dart';

/// Branche `client.from(table)` sur une chaîne dont l'`await` final LÈVE
/// [error] — pour exercer les branches d'erreur de `SyncAction.execute`.
void _stubError(MockSupabaseClient client, String table, Object error) {
  when(() => client.from(table))
      .thenAnswer((_) => FakeFromBuilder(Future<dynamic>.error(error)));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final epoch = DateTime.utc(2026, 1, 1, 12);

  group('generateUuidV4', () {
    final re = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );
    test('respecte le format UUID v4 (version + variant)', () {
      for (var i = 0; i < 50; i++) {
        expect(re.hasMatch(generateUuidV4()), isTrue);
      }
    });
    test('deux appels diffèrent', () {
      expect(generateUuidV4(), isNot(generateUuidV4()));
    });
  });

  group('SyncState', () {
    test('idle = 0 pending / pas de flush', () {
      expect(SyncState.idle.pending, 0);
      expect(SyncState.idle.flushing, isFalse);
    });
    test('copyWith + égalité de valeur', () {
      const a = SyncState(pending: 2, flushing: true);
      expect(
        a.copyWith(pending: 5),
        const SyncState(pending: 5, flushing: true),
      );
      expect(
        a.copyWith(flushing: false),
        const SyncState(pending: 2, flushing: false),
      );
      expect(a, const SyncState(pending: 2, flushing: true));
      expect(a, isNot(const SyncState(pending: 2, flushing: false)));
    });
  });

  group('SyncAction (de)sérialisation', () {
    test('chat.send round-trip', () {
      final a = SendChatMessageAction(
        id: 'id1',
        createdAt: epoch,
        channelId: 'c1',
        senderId: 's1',
        text: 'hello',
      );
      final back = SyncAction.fromJson(a.toJson());
      expect(back, isA<SendChatMessageAction>());
      final s = back! as SendChatMessageAction;
      expect(s.id, 'id1');
      expect(s.channelId, 'c1');
      expect(s.senderId, 's1');
      expect(s.text, 'hello');
      expect(s.type, 'chat.send');
    });

    test('notif.read round-trip', () {
      final a = MarkNotificationReadAction(
        id: 'id2',
        createdAt: epoch,
        notificationId: 'n1',
      );
      final back = SyncAction.fromJson(a.toJson())! as MarkNotificationReadAction;
      expect(back.notificationId, 'n1');
      expect(back.type, 'notif.read');
    });

    test('competition.register_free round-trip', () {
      final a = RegisterFreeCompetitionAction(
        id: 'id3',
        createdAt: epoch,
        competitionId: 'comp1',
        playerId: 'p1',
      );
      final back =
          SyncAction.fromJson(a.toJson())! as RegisterFreeCompetitionAction;
      expect(back.competitionId, 'comp1');
      expect(back.playerId, 'p1');
      expect(back.type, 'competition.register_free');
    });

    test('attempts préservé au décodage', () {
      final json = SendChatMessageAction(
        id: 'id',
        createdAt: epoch,
        channelId: 'c',
        senderId: 's',
        text: 't',
        attempts: 3,
      ).toJson();
      expect(SyncAction.fromJson(json)!.attempts, 3);
    });

    test('type inconnu → null (drop)', () {
      final json = {
        'id': 'x',
        'type': 'mystery.unknown',
        'created_at': epoch.toIso8601String(),
        'attempts': 0,
        'payload': <String, dynamic>{},
      };
      expect(SyncAction.fromJson(json), isNull);
    });

    test('copyWithAttempts conserve les champs métier', () {
      final a = SendChatMessageAction(
        id: 'id',
        createdAt: epoch,
        channelId: 'c',
        senderId: 's',
        text: 't',
      );
      final b = a.copyWithAttempts(7) as SendChatMessageAction;
      expect(b.attempts, 7);
      expect(b.channelId, 'c');
      expect(b.text, 't');
    });
  });

  group('SyncQueueService', () {
    late MockSupabaseClient client;
    late SharedPreferences prefs;
    late NetworkStatusService network;
    late SyncQueueService queue;

    SendChatMessageAction chatAction({String id = 'a1'}) => SendChatMessageAction(
          id: id,
          createdAt: epoch,
          channelId: 'c1',
          senderId: 's1',
          text: 'hi',
        );

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      prefs = await SharedPreferences.getInstance();
      client = MockSupabaseClient();
      // Réseau non démarré → current = unknown → isConnected = false :
      // enqueue ne déclenche PAS d'auto-flush, on pilote flush() à la main.
      network = NetworkStatusService(Connectivity());
      queue = SyncQueueService(prefs: prefs, client: client, network: network);
    });

    test("enqueue persiste, incrémente pending et l'état", () async {
      await queue.enqueue(chatAction());
      expect(queue.pending, hasLength(1));
      expect(queue.state.value.pending, 1);
      expect(prefs.getString('arena.sync_queue.v1'), isNotNull);
    });

    test('pending sur file corrompue → vide + clé effacée', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'arena.sync_queue.v1': 'pas-du-json',
      });
      final p = await SharedPreferences.getInstance();
      final q =
          SyncQueueService(prefs: p, client: client, network: network);
      expect(q.pending, isEmpty);
      expect(p.getString('arena.sync_queue.v1'), isNull);
    });

    test('flush — succès → action retirée de la file', () async {
      await queue.enqueue(chatAction());
      stubFrom(client, 'chat_messages', null); // insert résout OK
      await queue.flush();
      expect(queue.pending, isEmpty);
      expect(queue.state.value.flushing, isFalse);
    });

    test('flush — erreur réseau (non définitive) → conservée, attempts++',
        () async {
      await queue.enqueue(chatAction());
      _stubError(client, 'chat_messages', Exception('network down'));
      await queue.flush();
      expect(queue.pending, hasLength(1));
      expect(queue.pending.first.attempts, 1);
    });

    test('flush — erreur définitive (RLS 42501) → droppée', () async {
      await queue.enqueue(chatAction());
      _stubError(
        client,
        'chat_messages',
        const PostgrestException(message: 'denied', code: '42501'),
      );
      await queue.flush();
      expect(queue.pending, isEmpty);
    });

    test('flush — unique_violation (23505) traité comme idempotent → droppé',
        () async {
      await queue.enqueue(chatAction());
      _stubError(
        client,
        'chat_messages',
        const PostgrestException(message: 'dup', code: '23505'),
      );
      await queue.flush();
      expect(queue.pending, isEmpty);
    });

    test('dead-letter — droppée après maxAttempts flushes', () async {
      await queue.enqueue(chatAction());
      _stubError(client, 'chat_messages', Exception('always fails'));
      for (var i = 0; i < SyncQueueService.maxAttempts; i++) {
        await queue.flush();
      }
      expect(queue.pending, isEmpty);
    });

    test('flush concurrent — le 2e appel est ignoré (garde _flushing)',
        () async {
      await queue.enqueue(chatAction());
      stubFrom(client, 'chat_messages', null);
      await Future.wait([queue.flush(), queue.flush()]);
      expect(queue.pending, isEmpty);
    });
  });
}
