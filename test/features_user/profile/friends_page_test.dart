// Tests UI — FriendsPage (3 onglets : Amis / Demandes / Bloqués).
//
// ConsumerStatefulWidget. On override les 4 providers de la page avec des
// listes vides (ce qui court-circuite leur lecture de `currentSessionProvider`)
// et on vérifie le rendu des onglets + l'état vide de l'onglet Amis.

import 'package:arena/data/models/friendship.dart';
import 'package:arena/data/models/profile.dart';
import 'package:arena/data/repositories/friends_repository.dart';
import 'package:arena/features_user/profile/friends_page.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _Row = (Friendship, Profile);

Widget _scoped() => ProviderScope(
      overrides: [
        acceptedFriendsProvider
            .overrideWith((ref) => Stream<List<_Row>>.value(const [])),
        incomingFriendRequestsProvider
            .overrideWith((ref) => Stream<List<_Row>>.value(const [])),
        outgoingFriendRequestsProvider
            .overrideWith((ref) => Stream<List<_Row>>.value(const [])),
        blockedByMeProvider.overrideWith((ref) async => const <_Row>[]),
      ],
      child: const MaterialApp(
        locale: Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: FriendsPage(),
      ),
    );

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  Future<void> bumpViewport(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets("rend les 3 onglets et l'état vide de l'onglet Amis",
      (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // ArenaAppBar met le titre en majuscules.
    expect(find.text('MES AMIS'), findsOneWidget);
    expect(find.text('Amis'), findsOneWidget);
    expect(find.text('Demandes'), findsOneWidget);
    expect(find.text('Bloqués'), findsOneWidget);
    expect(find.text('Aucun ami pour le moment.'), findsOneWidget);
  });
}
