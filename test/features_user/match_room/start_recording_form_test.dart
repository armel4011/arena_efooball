// StartRecordingForm (nouveau flux HOME) : saisir le nom d'équipe + DÉMARRER
// L'ENREGISTREMENT appelle setTeamName PUIS markInProgress. Un nom vide est
// rejeté (bouton désactivé).

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

ArenaMatch _match() => const ArenaMatch(
      id: 'm1',
      competitionId: 'c1',
      player1Id: 'p1',
      player2Id: 'p2',
      homePlayerId: 'p1',
    );

Future<void> _pump(WidgetTester tester, _FakeMatchRepo repo) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [matchRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: StartRecordingForm(match: _match(), role: MatchRole.player1),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets("nom d'équipe + DÉMARRER → setTeamName puis markInProgress",
      (tester) async {
    final repo = _FakeMatchRepo();
    await _pump(tester, repo);

    await tester.enterText(find.byType(TextField), ' FC Home ');
    await tester.pump();
    await tester.tap(find.text("DÉMARRER L'ENREGISTREMENT"));
    await tester.pump();

    expect(repo.calls, ['setTeamName', 'markInProgress']);
    expect(repo.teamName, 'FC Home');
    expect(repo.isPlayer1, isTrue);
  });

  testWidgets('nom vide → bouton désactivé, aucun appel repo', (tester) async {
    final repo = _FakeMatchRepo();
    await _pump(tester, repo);

    // Bouton désactivé (onPressed null) → le tap ne déclenche rien.
    await tester.tap(
      find.text("DÉMARRER L'ENREGISTREMENT"),
      warnIfMissed: false,
    );
    await tester.pump();

    expect(repo.calls, isEmpty);
  });
}
