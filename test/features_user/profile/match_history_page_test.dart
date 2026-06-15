// Tests UI — MatchHistoryPage (écran #14).
//
// ConsumerStatefulWidget : profil courant + `playerMatchHistoryProvider`
// (FutureProvider family par playerId). On couvre l'état chargement (profil
// null → spinner) et l'état vide (aucun match → EmptyState).

import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/models/profile.dart';
import 'package:arena/data/repositories/match_stats_repository.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
import 'package:arena/features_user/profile/match_history_page.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Profile _profile() => const Profile(
      id: 'p-1',
      username: 'Drogba',
      email: 'd@arena.app',
      countryCode: 'CI',
    );

Widget _scoped({required Profile? profile}) => ProviderScope(
      overrides: [
        currentProfileProvider.overrideWith((ref) => Stream.value(profile)),
        playerMatchHistoryProvider.overrideWith(
          (ref, playerId) async => <ArenaMatch>[],
        ),
      ],
      child: const MaterialApp(
        locale: Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MatchHistoryPage(),
      ),
    );

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  Future<void> bumpViewport(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets('profil null → spinner de chargement', (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped(profile: null));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('aucun match → état vide', (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped(profile: _profile()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('HISTORIQUE'), findsOneWidget);
    expect(find.text('Aucun match'), findsOneWidget);
  });
}
