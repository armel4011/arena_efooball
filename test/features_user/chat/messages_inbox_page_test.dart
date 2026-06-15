// Tests UI — MessagesInboxPage (boîte de réception : DIRECT / TOURNOIS).
//
// Les providers de l'inbox (`myAllMatchesProvider`, channels, unread…) court-
// circuitent tous quand l'utilisateur n'a pas de session (retour vide sans
// accès Supabase) ; `currentSessionProvider` retombe à null en test. L'onglet
// DIRECT affiche alors son EmptyState — aucun override nécessaire.

import 'package:arena/features_user/chat/messages_inbox_page.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _scoped() => const ProviderScope(
      child: MaterialApp(
        locale: Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MessagesInboxPage(),
      ),
    );

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  Future<void> bumpViewport(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets("rend le titre, les 2 onglets et l'état vide DIRECT",
      (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('MESSAGES'), findsOneWidget);
    expect(find.text('DIRECT'), findsOneWidget);
    expect(find.text('TOURNOIS'), findsOneWidget);
    expect(find.text('Aucune conversation'), findsOneWidget);
  });
}
