// StartRecordingForm (flux HOME à DEUX étapes) :
//   Étape 1 « Ton nom d'équipe » → « Continuer » persiste UNIQUEMENT le nom
//     (setTeamName), sans démarrer l'enregistrement.
//   Étape 2 « Active ton enregistrement » (rendue quand le nom est déjà posé)
//     → « DÉMARRER L'ENREGISTREMENT » bascule in_progress (markInProgress).
// La permission de capture ne tombe donc jamais sur l'écran du nom d'équipe.

import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/repositories/match_repository.dart';
import 'package:arena/features_user/match_room/match_room_page.dart'
    show MatchRole;
import 'package:arena/features_user/match_room/widgets/start_recording_form.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeMatchRepo extends Fake implements MatchRepository {
  final calls = <String>[];
  String? teamName;
  bool? isPlayer1;

  @override
  Future<void> setTeamName({
    required String matchId,
    required bool isPlayer1,
    required String teamName,
  }) async {
    calls.add('setTeamName');
    this.isPlayer1 = isPlayer1;
    this.teamName = teamName;
  }

  @override
  Future<void> markInProgress(String matchId) async {
    calls.add('markInProgress');
  }
}

// `player1TeamName` pilote l'étape rendue : null → étape 1 (nom d'équipe),
// non-vide → étape 2 (activation).
ArenaMatch _match({String? teamName}) => ArenaMatch(
      id: 'm1',
      competitionId: 'c1',
      player1Id: 'p1',
      player2Id: 'p2',
      homePlayerId: 'p1',
      player1TeamName: teamName,
    );

Future<void> _pump(
  WidgetTester tester,
  _FakeMatchRepo repo, {
  String? teamName,
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [matchRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: StartRecordingForm(
              match: _match(teamName: teamName),
              role: MatchRole.player1,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('étape 1 : « Continuer » persiste le nom SANS markInProgress',
      (tester) async {
    final repo = _FakeMatchRepo();
    await _pump(tester, repo);

    await tester.enterText(find.byType(TextField), ' FC Home ');
    await tester.pump();
    await tester.tap(find.text('Continuer'));
    await tester.pump();

    // Étape 1 ne déclenche PAS l'enregistrement (pas de markInProgress).
    expect(repo.calls, ['setTeamName']);
    expect(repo.teamName, 'FC Home');
    expect(repo.isPlayer1, isTrue);
  });

  testWidgets('étape 2 (nom déjà posé) : DÉMARRER → markInProgress',
      (tester) async {
    final repo = _FakeMatchRepo();
    await _pump(tester, repo, teamName: 'FC Home');

    // Le nom étant déjà en base, l'étape « Activer » est rendue directement.
    await tester.tap(find.text("DÉMARRER L'ENREGISTREMENT"));
    await tester.pump();

    expect(repo.calls, ['markInProgress']);
  });

  testWidgets('nom vide → bouton « Continuer » désactivé, aucun appel repo',
      (tester) async {
    final repo = _FakeMatchRepo();
    await _pump(tester, repo);

    // Bouton désactivé (onPressed null) → le tap ne déclenche rien.
    await tester.tap(find.text('Continuer'), warnIfMissed: false);
    await tester.pump();

    expect(repo.calls, isEmpty);
  });
}
