// Tests UI — FriendsSearchPage (recherche d'amis par username).
//
// ConsumerStatefulWidget : aucun provider lu au build (currentSessionProvider
// n'est touché que dans la recherche). État initial = liste vide → invite à
// taper. On vérifie le titre, le champ et l'invite.

import 'package:arena/features_user/profile/friends_search_page.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _scoped() => const ProviderScope(
      child: MaterialApp(
        locale: Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: FriendsSearchPage(),
      ),
    );

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  Future<void> bumpViewport(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets('état initial → titre, champ et invite', (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped());
    await tester.pump();

    expect(tester.takeException(), isNull);
    // ArenaAppBar met le titre en majuscules.
    expect(find.text('RECHERCHER'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(
      find.text('Tape au moins 2 caractères pour chercher.'),
      findsOneWidget,
    );
  });
}
