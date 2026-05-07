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
        // Stub the competitions stream so the page mounts without
        // touching Supabase (which isn't initialized in widget tests).
        competitionsListProvider
            .overrideWith((ref, _) => Stream<List<Competition>>.value([])),
        // Stub the profile-tab providers so PlayerProfilePage doesn't
        // try to hit Supabase at mount time.
        playerStatsProvider
            .overrideWith((ref, _) async => const PlayerStats.empty()),
        playerRecentMatchesProvider
            .overrideWith((ref, _) async => const <ArenaMatch>[]),
      ],
      child: const MaterialApp(home: MainLayout()),
    );

void main() {
  testWidgets('starts on the Home tab and shows the username', (tester) async {
    await tester.pumpWidget(_scoped());
    await tester.pumpAndSettle();

    expect(find.text('ACCUEIL'), findsOneWidget);
    expect(find.text('MARADONA'), findsOneWidget);
  });

  testWidgets(
      'switching to the Compétitions tab mounts the list (empty state here)',
      (tester) async {
    await tester.pumpWidget(_scoped());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Compétitions'));
    await tester.pumpAndSettle();

    // AppBar title + the empty-state copy from CompetitionsListPage.
    expect(find.text('COMPÉTITIONS'), findsOneWidget);
    expect(find.text('Aucune compétition'), findsOneWidget);
    // The 4 game filter chips should also be there: "Tous" + 3 games.
    expect(find.text('Tous'), findsOneWidget);
    expect(find.text('eFootball'), findsOneWidget);
  });

  testWidgets('switching to the Chat tab shows the PHASE 6 panel',
      (tester) async {
    await tester.pumpWidget(_scoped());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();

    expect(find.text('PHASE 6'), findsOneWidget);
  });

  testWidgets(
      'switching to the Profil tab reveals the logout button (others hide it)',
      (tester) async {
    await tester.pumpWidget(_scoped());
    await tester.pumpAndSettle();

    // Home tab: no logout icon yet.
    expect(find.byIcon(Icons.logout), findsNothing);

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    // PlayerProfilePage shows the username and the stats label, plus
    // the AppBar exposes the logout button on tab 3.
    expect(find.text('Maradona'), findsOneWidget);
    expect(find.text('STATS'), findsOneWidget);
    expect(find.byIcon(Icons.logout), findsOneWidget);
  });

  testWidgets('IndexedStack keeps Home mounted when switching tabs',
      (tester) async {
    await tester.pumpWidget(_scoped());
    await tester.pumpAndSettle();

    // Home tab shows the uppercase greeting.
    expect(find.text('MARADONA'), findsOneWidget);

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    // The Home page is still in the tree (IndexedStack keeps state),
    // even though it's marked offstage and not painted.
    expect(find.text('MARADONA', skipOffstage: false), findsOneWidget);
  });
}
