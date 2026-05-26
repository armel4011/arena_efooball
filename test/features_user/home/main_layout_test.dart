// Smoke tests du `MainLayout` v2 (4 tabs Bottom Nav). Vérifie le
// rendu initial sur Accueil et la rotation des titres d'AppBar quand
// on tape les autres tabs. On ne fait pas `pumpAndSettle` parce que la
// HomePage embarque une LIVE card qui pulse indéfiniment.

import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/models/competition.dart';
import 'package:arena/data/models/player_stats.dart';
import 'package:arena/data/models/profile.dart';
import 'package:arena/data/repositories/competition_repository.dart';
import 'package:arena/data/repositories/match_stats_repository.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
import 'package:arena/features_user/home/main_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Profile _player() => const Profile(
      id: 'p-1',
      username: 'Maradona',
      email: 'm@arena.app',
      countryCode: 'CM',
    );

Widget _scoped() => ProviderScope(
      overrides: [
        currentProfileProvider.overrideWith((ref) async => _player()),
        competitionsListProvider
            .overrideWith((ref, _) => Stream<List<Competition>>.value([])),
        playerStatsProvider
            .overrideWith((ref, _) async => const PlayerStats.empty()),
        playerRecentMatchesProvider
            .overrideWith((ref, _) async => const <ArenaMatch>[]),
      ],
      child: const MaterialApp(home: MainLayout()),
    );

Future<void> _pumpShallow(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  Future<void> bumpViewport(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets('starts on the Accueil tab with the matching AppBar title',
      (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped());
    await _pumpShallow(tester);

    expect(find.text('ACCUEIL'), findsOneWidget);
    // 4 tab labels du BottomNav (Accueil/Compétitions/Chat/Profil).
    expect(find.text('Accueil'), findsOneWidget);
    expect(find.text('Compétitions'), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);
  });

  testWidgets('tapping Compétitions swaps the AppBar title',
      (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped());
    await _pumpShallow(tester);

    await tester.tap(find.text('Compétitions'));
    await _pumpShallow(tester);

    expect(find.text('COMPÉTITIONS'), findsOneWidget);
  });

  testWidgets('tapping Profil swaps the AppBar title and shows Maradona',
      (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped());
    await _pumpShallow(tester);

    await tester.tap(find.text('Profil'));
    await _pumpShallow(tester);

    expect(find.text('PROFIL'), findsOneWidget);
    // PlayerProfilePage v2 affiche le username en Bebas 26px UPPERCASE
    // (cf. player_profile_page.dart:191).
    expect(find.text('MARADONA'), findsWidgets);
  });

  testWidgets('IndexedStack keeps prior tabs in the tree (offstage)',
      (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped());
    await _pumpShallow(tester);

    // Sur l'accueil : on voit le username dans le header HomePage.
    expect(find.text('Maradona'), findsWidgets);

    await tester.tap(find.text('Profil'));
    await _pumpShallow(tester);

    // Maradona toujours dans le tree (HomePage offstage + PlayerProfilePage
    // qui réaffiche aussi le username).
    expect(find.text('Maradona', skipOffstage: false), findsWidgets);
  });
}
