import 'package:arena/data/repositories/notification_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '_supabase_mocks.dart';

void main() {
  late MockSupabaseClient client;
  late NotificationRepository repo;

  setUp(() {
    client = MockSupabaseClient();
    repo = NotificationRepository(client);
  });

  QueryProbe stub(String table, Object? result) =>
      stubFrom(client, table, result);

  group('markRead', () {
    test('stamp read_at, cible la notif, seulement si non-lue', () async {
      final from = stub('notifications', null);
      await repo.markRead('n1');
      expect(from.updatedValues!['read_at'], isA<String>());
      expect(from.filters.any((f) => f == 'eq:id=n1'), isTrue);
      expect(from.hasFilter('is', 'read_at'), isTrue);
    });
  });

  group('markAllRead', () {
    test('stamp read_at sur les non-lues du user', () async {
      final from = stub('notifications', null);
      await repo.markAllRead('u1');
      expect(from.filters.any((f) => f == 'eq:user_id=u1'), isTrue);
      expect(from.hasFilter('is', 'read_at'), isTrue);
    });
  });

  group('saveFcmToken (anti-echo Realtime)', () {
    test('token inchangé → aucun update', () async {
      final from = stub('profiles', {'fcm_token': 'tok'});
      await repo.saveFcmToken(userId: 'u1', token: 'tok');
      expect(from.updatedValues, isNull);
    });

    test('token différent → update', () async {
      final from = stub('profiles', {'fcm_token': 'old'});
      await repo.saveFcmToken(userId: 'u1', token: 'new');
      expect(from.updatedValues!['fcm_token'], 'new');
    });

    test('aucun profil (null) → update quand même', () async {
      final from = stub('profiles', null);
      await repo.saveFcmToken(userId: 'u1', token: 'new');
      expect(from.updatedValues!['fcm_token'], 'new');
    });
  });

  group('clearFcmToken', () {
    test('met fcm_token à null', () async {
      final from = stub('profiles', null);
      await repo.clearFcmToken('u1');
      expect(from.updatedValues!.containsKey('fcm_token'), isTrue);
      expect(from.updatedValues!['fcm_token'], isNull);
      expect(from.filters.any((f) => f == 'eq:id=u1'), isTrue);
    });
  });

  group('clearVoipToken', () {
    test('met voip_token à null', () async {
      final from = stub('profiles', null);
      await repo.clearVoipToken('u1');
      expect(from.updatedValues!['voip_token'], isNull);
    });
  });
}
