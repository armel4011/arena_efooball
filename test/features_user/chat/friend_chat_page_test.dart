// Tests UI — FriendChatPage (chat 1-1 entre amis).
//
// ConsumerStatefulWidget qui s'appuie sur des providers PRIVÉS
// (`_friendChannelProvider`, `_friendPeerProvider`) non overridables depuis un
// test → on ne peut pas atteindre le corps du chat. Smoke test : la page se
// construit sans planter (l'app bar et le Scaffold s'affichent même quand le
// canal retombe en erreur faute de Supabase).

import 'package:arena/features_user/chat/friend_chat_page.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _scoped() => const ProviderScope(
      child: MaterialApp(
        locale: Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: FriendChatPage(friendshipId: 'f-1'),
      ),
    );

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  Future<void> bumpViewport(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets('se construit sans planter', (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped());
    // Pas de pumpAndSettle : le provider privé échoue sans Supabase et la page
    // bascule sur son ErrorState (géré, non throwé).
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
