// Tests UI — MatchRoomPage (salle de match).
//
// ConsumerWidget : `matchByIdProvider(matchId)` (+ session). Le corps complet
// (_MatchRoomBody) tire énormément de providers ; on couvre ici les branches
// légères et déterministes : chargement (spinner) et match introuvable (null →
// EmptyState), sans monter tout le flux de score.

import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/repositories/match_repository.dart';
import 'package:arena/features_user/match_room/match_room_page.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _scoped(Stream<ArenaMatch?> matchStream) => ProviderScope(
      overrides: [
        matchByIdProvider.overrideWith((ref, matchId) => matchStream),
      ],
      child: const MaterialApp(
        locale: Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MatchRoomPage(matchId: 'm-1'),
      ),
    );

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  Future<void> bumpViewport(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets('flux en chargement → spinner', (tester) async {
    await bumpViewport(tester);
    // Stream qui n'émet jamais → l'AsyncValue reste en loading.
    await tester.pumpWidget(_scoped(const Stream<ArenaMatch?>.empty()));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('match null → titre par défaut + état introuvable',
      (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped(Stream<ArenaMatch?>.value(null)));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('MATCH'), findsOneWidget);
    expect(find.text('Match introuvable'), findsOneWidget);
  });
}
