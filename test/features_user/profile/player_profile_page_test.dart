// Tests UI — PlayerProfilePage (profil perso, onglet « Moi »).
//
// ConsumerWidget : `currentProfileProvider` + `playerStatsProvider(id)` +
// `playerRecentMatchesProvider(id)`. On override les trois et on vérifie le
// rendu du profil (chargement → données) ainsi que l'état profil null.

import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/models/player_stats.dart';
import 'package:arena/data/models/profile.dart';
import 'package:arena/data/repositories/match_stats_repository.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
import 'package:arena/features_user/profile/player_profile_page.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _profile = Profile(
  id: 'p-1',
  username: 'Drogba',
  email: 'd@arena.app',
  countryCode: 'CI',
);

Widget _scoped(Profile? profile) => ProviderScope(
      overrides: [
        currentProfileProvider.overrideWith((ref) => Stream.value(profile)),
        playerStatsProvider
            .overrideWith((ref, id) async => const PlayerStats.empty()),
        playerRecentMatchesProvider
            .overrideWith((ref, id) async => <ArenaMatch>[]),
      ],
      child: const MaterialApp(
        locale: Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: PlayerProfilePage()),
      ),
    );

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  Future<void> bumpViewport(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets('profil chargé → username affiché', (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped(_profile));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Le header affiche le username en majuscules.
    expect(find.text('DROGBA'), findsOneWidget);
  });

  testWidgets('profil null → message indisponible', (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped(null));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Profil indisponible. Reconnecte-toi.'), findsOneWidget);
  });
}
