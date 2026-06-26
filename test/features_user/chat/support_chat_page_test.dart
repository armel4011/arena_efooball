import 'dart:io';

import 'package:arena/data/models/chat_message.dart';
import 'package:arena/data/repositories/chat_repository.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:arena/features_user/chat/support_chat_page.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

const _selfId = 'self-id';
const _adminId = 'admin-id';
const _channelId = 'support-channel-1';

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
      'created_at': '2026-06-26T00:00:00.000Z',
    },
  })!;
}

ChatMessage _msg({
  required String id,
  required String senderId,
  required String content,
}) =>
    ChatMessage(
      id: id,
      channelId: _channelId,
      senderId: senderId,
      content: content,
      createdAt: DateTime.utc(2026, 6, 26, 12),
    );

class _FakeChatRepository implements ChatRepository {
  final List<({String channelId, String senderId, String content})> sent = [];

  @override
  Future<String> ensureSupportChannel() async => _channelId;

  @override
  Future<void> sendMessage({
    required String channelId,
    required String senderId,
    required String content,
  }) async {
    sent.add((channelId: channelId, senderId: senderId, content: content));
  }

  @override
  Future<void> unhideChannelForMe(String channelId) async {}

  @override
  Future<void> markChannelAsRead(String channelId) async {}

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
  }) async =>
      'https://example.test/$path';

  // --- Reste de l'interface : non sollicité par SupportChatPage ---
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

Widget _scoped({
  List<ChatMessage> messages = const [],
  _FakeChatRepository? repo,
}) {
  return ProviderScope(
    overrides: [
      currentSessionProvider.overrideWith((ref) => _fakeSession(_selfId)),
      supportChannelProvider.overrideWith((ref) async => _channelId),
      channelMessagesProvider.overrideWith(
        (ref, _) => Stream<List<ChatMessage>>.value(messages),
      ),
      if (repo != null) chatRepositoryProvider.overrideWithValue(repo),
    ],
    child: const MaterialApp(
      locale: Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: SupportChatPage(),
    ),
  );
}

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  Future<void> bumpViewport(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets("affiche le titre et l'état vide quand il n'y a aucun message",
      (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped(repo: _FakeChatRepository()));
    await tester.pumpAndSettle();

    expect(find.text('Contact / Aide'), findsOneWidget);
    expect(find.text('Une question ? Écrivez-nous'), findsOneWidget);
  });

  testWidgets("aligne mes bulles à droite et celles de l'admin à gauche",
      (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(
      _scoped(
        repo: _FakeChatRepository(),
        messages: [
          _msg(id: 'm1', senderId: _adminId, content: 'bonjour'),
          _msg(id: 'm2', senderId: _selfId, content: 'merci'),
        ],
      ),
    );
    await tester.pumpAndSettle();

    final adminAlign = tester.widget<Align>(
      find.ancestor(of: find.text('bonjour'), matching: find.byType(Align)),
    );
    final selfAlign = tester.widget<Align>(
      find.ancestor(of: find.text('merci'), matching: find.byType(Align)),
    );
    expect(adminAlign.alignment, Alignment.centerLeft);
    expect(selfAlign.alignment, Alignment.centerRight);
  });

  testWidgets('le bouton envoyer transmet le texte nettoyé à sendMessage',
      (tester) async {
    await bumpViewport(tester);
    final repo = _FakeChatRepository();
    await tester.pumpWidget(_scoped(repo: repo));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), "  besoin d'aide  ");
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(repo.sent, hasLength(1));
    expect(repo.sent.first.channelId, _channelId);
    expect(repo.sent.first.senderId, _selfId);
    expect(repo.sent.first.content, "besoin d'aide");
  });

  testWidgets('envoyer avec un champ vide ne fait rien', (tester) async {
    await bumpViewport(tester);
    final repo = _FakeChatRepository();
    await tester.pumpWidget(_scoped(repo: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(repo.sent, isEmpty);
  });
}

// Pour que `_FakeChatRepository` puisse étendre noSuchMethod sans warning,
// on ignore le besoin d'overrides exhaustifs : SupportChatPage n'appelle que
// les méthodes explicitement implémentées ci-dessus.
