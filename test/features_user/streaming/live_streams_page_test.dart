// Tests UI — LiveStreamsPage (liste des diffusions live publiques).
//
// ConsumerWidget : flux `activePublicStreamsProvider`. On l'override avec une
// liste vide et on vérifie le titre + l'EmptyState (les cards et leur provider
// de viewers ne sont rendus que s'il y a des streams).

import 'package:arena/data/models/match_stream.dart';
import 'package:arena/data/repositories/match_stream_repository.dart';
import 'package:arena/features_user/streaming/live_streams_page.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _scoped() => ProviderScope(
      overrides: [
        activePublicStreamsProvider
            .overrideWith((ref) => Stream<List<MatchStream>>.value(const [])),
      ],
      child: const MaterialApp(
        locale: Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: LiveStreamsPage(),
      ),
    );

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  Future<void> bumpViewport(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets('flux vide → titre + état vide', (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('LIVE NOW'), findsOneWidget);
    expect(find.text('Aucun match en direct'), findsOneWidget);
  });
}
