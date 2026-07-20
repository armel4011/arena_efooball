import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/data/models/tutorial_video.dart';
import 'package:arena/data/repositories/tutorial_video_repository.dart';
import 'package:arena/features_user/competitions/app_check_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Dialogue de contrôle affiché avant l'inscription à une compétition sur jeu
/// EXTERNE. On teste le scénario SANS vidéo (le lecteur YouTube repose sur une
/// WebView non instanciable en test) : les deux rappels de vérification, le
/// bouton store selon le jeu, et les retours Annuler/Continuer.
///
/// Le câblage de la vidéo est couvert ailleurs : `ArenaYoutubePlayer.maybe`
/// (arena_youtube_player_test) + `activeContextualVideo` install_check
/// (tutorial_video_repository_test).
void main() {
  /// Monte un bouton qui ouvre le dialogue pour [game]. [video] alimente
  /// `installCheckVideoProvider` (null = pas de vidéo → pas de WebView).
  /// [results] collecte la valeur retournée par le dialogue.
  Widget harness(
    GameType game, {
    TutorialVideo? video,
    List<bool>? results,
  }) {
    return ProviderScope(
      overrides: [
        installCheckVideoProvider.overrideWith(
          (ref, g) => AsyncData<TutorialVideo?>(video),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () async {
                final r = await showAppCheckDialog(ctx, game: game);
                results?.add(r);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> open(WidgetTester tester) async {
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('jeu externe : titre + les 2 vérifications + bouton store',
      (tester) async {
    await tester.pumpWidget(harness(GameType.efootball));
    await open(tester);

    expect(find.text("Avant de t'inscrire"), findsOneWidget);
    expect(find.textContaining('à jour et identique'), findsOneWidget);
    expect(find.textContaining("s'installer"), findsOneWidget);
    expect(find.text('Ouvrir le store'), findsOneWidget);
    // Sans vidéo réglée : pas de bloc "Guide vidéo".
    expect(find.text('Guide vidéo'), findsNothing);
    expect(find.text('Annuler'), findsOneWidget);
    expect(find.text('Continuer'), findsOneWidget);
  });

  testWidgets('Continuer → le dialogue retourne true', (tester) async {
    final results = <bool>[];
    await tester.pumpWidget(
      harness(GameType.dreamLeague, results: results),
    );
    await open(tester);
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();
    expect(results, [true]);
  });

  testWidgets('Annuler → le dialogue retourne false', (tester) async {
    final results = <bool>[];
    await tester.pumpWidget(
      harness(GameType.eaSportsFc, results: results),
    );
    await open(tester);
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(results, [false]);
  });

  testWidgets('jeu in-app (Dames) : aucun bouton store', (tester) async {
    // showAppCheckDialog n'est pas déclenché pour les Dames en pratique, mais
    // le dialogue lui-même doit masquer le store quand gameStoreUrl == null.
    await tester.pumpWidget(harness(GameType.draughts));
    await open(tester);

    expect(find.text("Avant de t'inscrire"), findsOneWidget);
    expect(find.text('Ouvrir le store'), findsNothing);
  });
}
