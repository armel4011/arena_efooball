import 'package:arena/core/services/agora_token_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AgoraToken.fromJson', () {
    int futureEpoch() =>
        DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
            1000;
    int pastEpoch() =>
        DateTime.now().subtract(const Duration(hours: 1)).millisecondsSinceEpoch ~/
            1000;

    test('happy path broadcaster', () {
      final token = AgoraToken.fromJson({
        'token': 'tok-xxx',
        'channelName': 'match-abc',
        'uid': 42,
        'expiresAt': futureEpoch(),
        'role': 'broadcaster',
      });
      expect(token.token, 'tok-xxx');
      expect(token.channelName, 'match-abc');
      expect(token.uid, 42);
      expect(token.role, AgoraRole.broadcaster);
    });

    test('role audience', () {
      final token = AgoraToken.fromJson({
        'token': 'tok',
        'channelName': 'c',
        'uid': 1,
        'expiresAt': futureEpoch(),
        'role': 'audience',
      });
      expect(token.role, AgoraRole.audience);
    });

    test('role inconnu → audience (fallback safe)', () {
      final token = AgoraToken.fromJson({
        'token': 'tok',
        'channelName': 'c',
        'uid': 1,
        'expiresAt': futureEpoch(),
        'role': 'unknown',
      });
      expect(token.role, AgoraRole.audience);
    });

    test('uid as double → cast en int', () {
      final token = AgoraToken.fromJson({
        'token': 'tok',
        'channelName': 'c',
        'uid': 99.0,
        'expiresAt': futureEpoch(),
        'role': 'broadcaster',
      });
      expect(token.uid, 99);
      expect(token.uid, isA<int>());
    });

    test('isExpired false quand expiresAt dans le futur', () {
      final token = AgoraToken.fromJson({
        'token': 'tok',
        'channelName': 'c',
        'uid': 1,
        'expiresAt': futureEpoch(),
        'role': 'broadcaster',
      });
      expect(token.isExpired, isFalse);
    });

    test('isExpired true quand expiresAt dans le passé', () {
      final token = AgoraToken.fromJson({
        'token': 'tok',
        'channelName': 'c',
        'uid': 1,
        'expiresAt': pastEpoch(),
        'role': 'broadcaster',
      });
      expect(token.isExpired, isTrue);
    });
  });

  group('AgoraTokenException', () {
    test('toString inclut le message', () {
      const e = AgoraTokenException('bad payload');
      expect(e.toString(), 'AgoraTokenException: bad payload');
    });
  });
}
