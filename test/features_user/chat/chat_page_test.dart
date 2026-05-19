import 'dart:io';

import 'package:arena/data/models/chat_channel.dart';
import 'package:arena/data/models/chat_message.dart';
import 'package:arena/data/repositories/chat_repository.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
import 'package:arena/features_user/chat/chat_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

const _selfId = 'self-id';
const _opponentId = 'opponent-id';
const _channelId = 'channel-1';
const _matchId = 'match-1';

sb.Session _fakeSession(String userId) {
  return sb.Session.fromJson({
    'access_token': 'fake-token',
    'token_type': 'bearer',
    'expires_in': 3600,
    'refresh_token': 'fake-refresh',
    'user': {
      'id': userId,
      'aud': 'authenticated',
      'app_metadata': <String, dynamic>{},
      'user_metadata': <String, dynamic>{},
      'created_at': DateTime.now().toIso8601String(),
    },
  })!;
}

ChatMessage _msg({
  required String id,
  required String senderId,
  required String content,
  DateTime? createdAt,
}) =>
    ChatMessage(
      id: id,
      channelId: _channelId,
      senderId: senderId,
      content: content,
      createdAt: createdAt ?? DateTime.utc(2026, 5, 6, 12),
    );

class _FakeChatRepository implements ChatRepository {
  final List<({String channelId, String senderId, String content})> sent = [];

  @override
  Future<Set<String>> openedMatchChannelIds(List<String> matchIds) async =>
      const <String>{};

  @override
  Future<ChatChannel> ensureMatchChannel(String matchId) async {
    return ChatChannel(id: _channelId, type: 'match', matchId: matchId);
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String channelId, {int limit = 200}) =>
      Stream<List<ChatMessage>>.value(const []);

  @override
  Future<void> sendMessage({
    required String channelId,
    required String senderId,
    required String content,
  }) async {
    sent.add((channelId: channelId, senderId: senderId, content: content));
  }

  @override
  Future<void> sendMediaMessage({
    required String channelId,
    required String senderId,
    required File file,
    required String mediaType,
    String content = '',
  }) async {}

  @override
  Future<String> signedMediaUrl(
    String path, {
    Duration expiresIn = const Duration(hours: 1),
  }) async => 'https://example.test/$path';

  @override
  Future<void> softDeleteMessage(String messageId) async {}

  @override
  Future<void> hideChannelForMe(String channelId) async {}

  @override
  Future<void> unhideChannelForMe(String channelId) async {}

  @override
  Future<DateTime?> myChatClearedAt(String channelId) async => null;

  @override
  Future<void> markChannelAsRead(String channelId) async {}

  @override
  Future<Map<String, int>> getUnreadCounts(List<String> channelIds) async =>
      const {};

  @override
  Future<Map<String, String>> matchChannelIdsFor(
    List<String> matchIds,
  ) async =>
      const {};

  @override
  Future<ChatChannel> ensureFriendChannel(String friendshipId) async {
    return ChatChannel(
      id: _channelId,
      type: 'friend',
      friendshipId: friendshipId,
    );
  }

  @override
  Future<List<({String channelId, String friendshipId, String peerId})>>
      listMyFriendChannels(String me) async => const [];
}

Widget _scoped({
  List<ChatMessage> messages = const [],
  _FakeChatRepository? repo,
}) {
  return ProviderScope(
    overrides: [
      currentSessionProvider.overrideWith((ref) => _fakeSession(_selfId)),
      matchChannelProvider.overrideWith(
        (ref, matchId) async =>
            ChatChannel(id: _channelId, type: 'match', matchId: matchId),
      ),
      channelMessagesProvider.overrideWith(
        (ref, _) => Stream<List<ChatMessage>>.value(messages),
      ),
      if (repo != null) chatRepositoryProvider.overrideWithValue(repo),
    ],
    child: const MaterialApp(
      home: ChatPage(matchId: _matchId),
    ),
  );
}

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  Future<void> bumpViewport(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets('shows the empty state when the channel has no message',
      (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped());
    await tester.pumpAndSettle();

    expect(find.text('Pas encore de message'), findsOneWidget);
    expect(find.text('Sois le premier à écrire ici.'), findsOneWidget);
  });

  testWidgets('renders self bubbles aligned right and other bubbles left',
      (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(
      _scoped(
        messages: [
          _msg(id: 'm1', senderId: _opponentId, content: 'hello'),
          _msg(id: 'm2', senderId: _selfId, content: 'hi back'),
        ],
      ),
    );
    await tester.pumpAndSettle();

    final helloAlign = tester.widget<Align>(
      find.ancestor(
        of: find.text('hello'),
        matching: find.byType(Align),
      ),
    );
    final hiBackAlign = tester.widget<Align>(
      find.ancestor(
        of: find.text('hi back'),
        matching: find.byType(Align),
      ),
    );

    expect(helloAlign.alignment, Alignment.centerLeft);
    expect(hiBackAlign.alignment, Alignment.centerRight);
  });

  testWidgets('tapping send forwards the trimmed text to sendMessage',
      (tester) async {
    await bumpViewport(tester);
    final repo = _FakeChatRepository();
    await tester.pumpWidget(_scoped(repo: repo));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '  hello world  ');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(repo.sent, hasLength(1));
    expect(repo.sent.first.channelId, _channelId);
    expect(repo.sent.first.senderId, _selfId);
    expect(repo.sent.first.content, 'hello world');
  });

  testWidgets('tapping send with an empty input does nothing',
      (tester) async {
    await bumpViewport(tester);
    final repo = _FakeChatRepository();
    await tester.pumpWidget(_scoped(repo: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(repo.sent, isEmpty);
  });
}
