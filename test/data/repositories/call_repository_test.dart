import 'package:arena/data/models/call_record.dart';
import 'package:arena/data/repositories/call_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '_supabase_mocks.dart';

void main() {
  late MockSupabaseClient client;
  late CallRepository repo;

  setUp(() {
    client = MockSupabaseClient();
    repo = CallRepository(client);
  });

  QueryProbe stub(String table, Object? result) =>
      stubFrom(client, table, result);

  Map<String, dynamic> callRow({
    String id = 'call1',
    String scope = 'friend',
    String scopeId = 'f1',
    String callerId = 'u1',
    String calleeId = 'u2',
    String status = 'ringing',
    String? answeredAt,
    String? endedAt,
  }) =>
      {
        'id': id,
        'scope': scope,
        'scope_id': scopeId,
        'caller_id': callerId,
        'callee_id': calleeId,
        'status': status,
        'agora_channel': 'call_${scope}_$scopeId',
        'created_at': '2026-06-01T10:00:00.000Z',
        if (answeredAt != null) 'answered_at': answeredAt,
        if (endedAt != null) 'ended_at': endedAt,
      };

  group('placeCall', () {
    test('non authentifié → StateError sans requête', () async {
      stubAuthUser(client, null);
      await expectLater(
        repo.placeCall(scope: 'friend', scopeId: 'f1', calleeId: 'u2'),
        throwsA(isA<StateError>()),
      );
      verifyNever(() => client.from(any()));
    });

    test('insère une ligne ringing avec channel + parse le retour', () async {
      stubAuthUser(client, 'u1');
      final from = stub('calls', callRow());
      final rec = await repo.placeCall(
        scope: 'friend',
        scopeId: 'f1',
        calleeId: 'u2',
      );
      expect(rec, isA<CallRecord>());
      expect(rec.id, 'call1');
      expect(rec.status, CallStatus.ringing);
      expect(rec.agoraChannel, 'call_friend_f1');

      final v = from.insertedValues! as Map<String, dynamic>;
      expect(v['scope'], 'friend');
      expect(v['scope_id'], 'f1');
      expect(v['caller_id'], 'u1');
      expect(v['callee_id'], 'u2');
      expect(v['status'], 'ringing');
      expect(v['agora_channel'], 'call_friend_f1');
    });

    test('scope match → channel call_match_<id>', () async {
      stubAuthUser(client, 'u1');
      final from = stub('calls', callRow(scope: 'match', scopeId: 'm9'));
      await repo.placeCall(scope: 'match', scopeId: 'm9', calleeId: 'u2');
      final v = from.insertedValues! as Map<String, dynamic>;
      expect(v['agora_channel'], 'call_match_m9');
    });
  });

  group('accept', () {
    test('status accepted + answered_at, cible le call', () async {
      final from = stub('calls', null);
      await repo.accept('call1');
      final v = from.updatedValues!;
      expect(v['status'], 'accepted');
      expect(v['answered_at'], isA<String>());
      expect(v.containsKey('ended_at'), isFalse);
      expect(from.filters.any((f) => f == 'eq:id=call1'), isTrue);
    });
  });

  group('decline', () {
    test('status declined sans horodatage', () async {
      final from = stub('calls', null);
      await repo.decline('call1');
      final v = from.updatedValues!;
      expect(v['status'], 'declined');
      expect(v.containsKey('answered_at'), isFalse);
      expect(v.containsKey('ended_at'), isFalse);
      expect(from.filters.any((f) => f == 'eq:id=call1'), isTrue);
    });
  });

  group('cancel', () {
    test('status cancelled sans horodatage', () async {
      final from = stub('calls', null);
      await repo.cancel('call1');
      expect(from.updatedValues!['status'], 'cancelled');
      expect(from.updatedValues!.containsKey('answered_at'), isFalse);
    });
  });

  group('markMissed', () {
    test('status missed', () async {
      final from = stub('calls', null);
      await repo.markMissed('call1');
      expect(from.updatedValues!['status'], 'missed');
    });
  });

  group('end', () {
    test('status ended + ended_at, sans answered_at', () async {
      final from = stub('calls', null);
      await repo.end('call1');
      final v = from.updatedValues!;
      expect(v['status'], 'ended');
      expect(v['ended_at'], isA<String>());
      expect(v.containsKey('answered_at'), isFalse);
    });
  });

  group('getById', () {
    test('ligne trouvée → CallRecord parsé', () async {
      final from = stub('calls', callRow(status: 'accepted'));
      final rec = await repo.getById('call1');
      expect(rec, isNotNull);
      expect(rec!.id, 'call1');
      expect(rec.status, CallStatus.accepted);
      expect(from.filters.any((f) => f == 'eq:id=call1'), isTrue);
      expect(from.hasFilter('maybeSingle', '_'), isTrue);
    });

    test('aucune ligne → null', () async {
      stub('calls', null);
      expect(await repo.getById('absent'), isNull);
    });
  });

  group('usernameOf', () {
    test('lit public_profiles.username filtré par id', () async {
      final from = stub('public_profiles', {'username': 'Zeus'});
      final name = await repo.usernameOf('u2');
      expect(name, 'Zeus');
      expect(from.selectedColumns, 'username');
      expect(from.filters.any((f) => f == 'eq:id=u2'), isTrue);
    });

    test('profil absent → fallback "Joueur"', () async {
      stub('public_profiles', null);
      expect(await repo.usernameOf('u2'), 'Joueur');
    });

    test('username null → fallback "Joueur"', () async {
      stub('public_profiles', <String, dynamic>{'username': null});
      expect(await repo.usernameOf('u2'), 'Joueur');
    });
  });
}
