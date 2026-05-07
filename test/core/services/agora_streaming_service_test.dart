import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:arena/core/services/agora_streaming_service.dart';
import 'package:arena/core/services/agora_token_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockTokenClient extends Mock implements AgoraTokenClient {}

class _FakeRtcEngine extends Fake implements RtcEngine {}

class _StubAgoraEnginePlatform implements AgoraEnginePlatform {
  final RtcEngine fakeEngine = _FakeRtcEngine();
  String? lastChannelId;
  AgoraRole? lastRole;
  bool engineReleased = false;
  bool channelLeft = false;

  // Hooks set by joinChannel — tests fire them to simulate native callbacks.
  VoidCallback? onLocalJoinedHook;
  void Function(int)? onRemoteJoinedHook;

  @override
  Future<RtcEngine> createAndInit({required String appId}) async => fakeEngine;

  @override
  Future<void> joinChannel({
    required RtcEngine engine,
    required String token,
    required String channelId,
    required int uid,
    required AgoraRole role,
    required VoidCallback onLocalJoined,
    required void Function(int remoteUid) onRemoteJoined,
  }) async {
    lastChannelId = channelId;
    lastRole = role;
    onLocalJoinedHook = onLocalJoined;
    onRemoteJoinedHook = onRemoteJoined;
  }

  @override
  Future<void> leaveChannel(RtcEngine engine) async {
    channelLeft = true;
  }

  @override
  Future<void> releaseEngine(RtcEngine engine) async {
    engineReleased = true;
  }
}

const _stubToken = AgoraToken(
  token: 'tok',
  channelName: 'match_42',
  uid: 1234,
  expiresAt: 9999999999,
  role: AgoraRole.audience,
);

const _stubBroadcasterToken = AgoraToken(
  token: 'tok-b',
  channelName: 'match_42',
  uid: 4242,
  expiresAt: 9999999999,
  role: AgoraRole.broadcaster,
);

void main() {
  setUpAll(() {
    // The service reads AGORA_APP_ID from dotenv during _ensureEngine.
    dotenv.testLoad(fileInput: 'AGORA_APP_ID=test_app_id\n');
    registerFallbackValue(AgoraRole.audience);
  });

  test('joinAsAudience fetches token and transitions Joined on local join',
      () async {
    final tokenClient = _MockTokenClient();
    when(
      () => tokenClient.fetch(
        matchId: any(named: 'matchId'),
        role: any(named: 'role'),
      ),
    ).thenAnswer((_) async => _stubToken);

    final platform = _StubAgoraEnginePlatform();
    final svc = AgoraStreamingService(
      tokenClient: tokenClient,
      platform: platform,
    );

    final emitted = <AgoraSessionState>[];
    final sub = svc.stateStream.listen(emitted.add);

    await svc.joinAsAudience(matchId: '42');
    platform.onLocalJoinedHook!();
    await Future<void>.delayed(Duration.zero);

    expect(svc.state, isA<AgoraJoined>());
    final j = svc.state as AgoraJoined;
    expect(j.channel, 'match_42');
    expect(j.role, AgoraRole.audience);
    expect(j.localUid, 1234);
    expect(emitted.whereType<AgoraJoining>().isNotEmpty, isTrue);

    await sub.cancel();
    await svc.dispose();
  });

  test('joinAsBroadcaster passes broadcaster role to platform', () async {
    final tokenClient = _MockTokenClient();
    when(
      () => tokenClient.fetch(
        matchId: any(named: 'matchId'),
        role: any(named: 'role'),
      ),
    ).thenAnswer((_) async => _stubBroadcasterToken);

    final platform = _StubAgoraEnginePlatform();
    final svc = AgoraStreamingService(
      tokenClient: tokenClient,
      platform: platform,
    );

    await svc.joinAsBroadcaster(matchId: '42');
    expect(platform.lastRole, AgoraRole.broadcaster);
    expect(platform.lastChannelId, 'match_42');
    await svc.dispose();
  });

  test('remote join updates AgoraJoined.remoteUid', () async {
    final tokenClient = _MockTokenClient();
    when(
      () => tokenClient.fetch(
        matchId: any(named: 'matchId'),
        role: any(named: 'role'),
      ),
    ).thenAnswer((_) async => _stubToken);

    final platform = _StubAgoraEnginePlatform();
    final svc = AgoraStreamingService(
      tokenClient: tokenClient,
      platform: platform,
    );

    await svc.joinAsAudience(matchId: '42');
    platform.onLocalJoinedHook!();
    await Future<void>.delayed(Duration.zero);
    platform.onRemoteJoinedHook!(7777);
    await Future<void>.delayed(Duration.zero);

    final s = svc.state as AgoraJoined;
    expect(s.remoteUid, 7777);

    await svc.dispose();
  });

  test('joinAsAudience emits AgoraFailed on token fetch error', () async {
    final tokenClient = _MockTokenClient();
    when(
      () => tokenClient.fetch(
        matchId: any(named: 'matchId'),
        role: any(named: 'role'),
      ),
    ).thenThrow(const AgoraTokenException('forbidden'));

    final platform = _StubAgoraEnginePlatform();
    final svc = AgoraStreamingService(
      tokenClient: tokenClient,
      platform: platform,
    );

    await expectLater(
      svc.joinAsAudience(matchId: '42'),
      throwsA(isA<AgoraTokenException>()),
    );
    expect(svc.state, isA<AgoraFailed>());
    final f = svc.state as AgoraFailed;
    expect(f.reason, contains('token_fetch_failed'));

    await svc.dispose();
  });

  test('leave() emits AgoraLeft', () async {
    final tokenClient = _MockTokenClient();
    when(
      () => tokenClient.fetch(
        matchId: any(named: 'matchId'),
        role: any(named: 'role'),
      ),
    ).thenAnswer((_) async => _stubToken);
    final platform = _StubAgoraEnginePlatform();
    final svc = AgoraStreamingService(
      tokenClient: tokenClient,
      platform: platform,
    );

    await svc.joinAsAudience(matchId: '42');
    platform.onLocalJoinedHook!();
    await svc.leave();

    expect(svc.state, isA<AgoraLeft>());
    expect(platform.channelLeft, isTrue);

    await svc.dispose();
  });

  group('AgoraToken', () {
    test('parses Edge Function payload', () {
      final t = AgoraToken.fromJson({
        'token': 'abc',
        'channelName': 'match_xy',
        'uid': 99,
        'expiresAt': 1700000000,
        'role': 'broadcaster',
      });
      expect(t.token, 'abc');
      expect(t.channelName, 'match_xy');
      expect(t.uid, 99);
      expect(t.role, AgoraRole.broadcaster);
    });

    test('isExpired reflects timestamp', () {
      const fresh = AgoraToken(
        token: 't',
        channelName: 'c',
        uid: 1,
        expiresAt: 9999999999,
        role: AgoraRole.audience,
      );
      const old = AgoraToken(
        token: 't',
        channelName: 'c',
        uid: 1,
        expiresAt: 1,
        role: AgoraRole.audience,
      );
      expect(fresh.isExpired, isFalse);
      expect(old.isExpired, isTrue);
    });
  });
}
