// Tests UI du flux MATCH — soumission de score (ScoreFlowView, step 3).
//
// On monte le formulaire (aucune soumission existante → `mine == null`) et on
// vérifie le cœur métier "argent/match" : un score valide appelle bien
// `MatchRepository.submitScore` avec les bons buts (mappés selon le rôle), et
// un formulaire vide est rejeté sans appeler le repository.
//
// ScoreField plafonne la saisie à 2 chiffres (digitsOnly) : le cas invalide
// testable via l'UI est donc "champs vides", pas un score > 99.

import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/repositories/match_repository.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_user/match_room/match_room_page.dart' show MatchRole;
import 'package:arena/features_user/match_room/widgets/score_flow_view.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeUser extends Fake implements User {
  _FakeUser(this.id);
  @override
  final String id;
}

class _FakeSession extends Fake implements Session {
  _FakeSession(this.user);
  @override
  final User user;
}

class _FakeMatchRepo extends Fake implements MatchRepository {
  int submitCalls = 0;
  int? lastP1;
  int? lastP2;
  bool? lastViaPenalties;

  @override
  Future<void> submitScore({
    required String matchId,
    required String byProfileId,
    required int scoreP1,
    required int scoreP2,
    bool decidedByPenalties = false,
    int? penaltyP1,
    int? penaltyP2,
    String? proofPath,
    String? proofMimeType,
  }) async {
    submitCalls++;
    lastP1 = scoreP1;
    lastP2 = scoreP2;
    lastViaPenalties = decidedByPenalties;
  }
}

// Match de groupe (groupId != null) → pas de section pénalités, formulaire
// minimal à 2 champs de score.
ArenaMatch _groupMatch() => const ArenaMatch(
      id: 'm1',
      competitionId: 'c1',
      player1Id: 'p1',
      player2Id: 'p2',
      groupId: 'g1',
    );

Widget _scoped({
  required ArenaMatch match,
  required _FakeMatchRepo repo,
  String selfId = 'p1',
}) {
  return ProviderScope(
    overrides: [
      currentSessionProvider
          .overrideWith((ref) => _FakeSession(_FakeUser(selfId))),
      matchRepositoryProvider.overrideWithValue(repo),
      matchScoreSubmissionsProvider.overrideWith(
        (ref, id) => Stream.value(const <Map<String, dynamic>>[]),
      ),
    ],
    child: MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: ScoreFlowView(match: match, role: MatchRole.player1),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  Future<void> bumpViewport(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  // Le bouton SOUMETTRE est l'ArenaButton porteur de l'icône check_circle
  // (l'autre ArenaButton du formulaire est le lien "ouvrir le chat").
  final submitButton =
      find.widgetWithIcon(ArenaButton, Icons.check_circle_outline);

  testWidgets('un score valide appelle submitScore avec les bons buts',
      (tester) async {
    await bumpViewport(tester);
    final repo = _FakeMatchRepo();
    await tester.pumpWidget(_scoped(match: _groupMatch(), repo: repo));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(2)); // mon score + score adverse

    await tester.enterText(fields.at(0), '2'); // mes buts
    await tester.enterText(fields.at(1), '1'); // buts adverse
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    // role = player1 → scoreP1 = mes buts, scoreP2 = adverse.
    expect(repo.submitCalls, 1);
    expect(repo.lastP1, 2);
    expect(repo.lastP2, 1);
    expect(repo.lastViaPenalties, false);
  });

  testWidgets('un formulaire vide est rejeté sans appeler le repository',
      (tester) async {
    await bumpViewport(tester);
    final repo = _FakeMatchRepo();
    await tester.pumpWidget(_scoped(match: _groupMatch(), repo: repo));
    await tester.pumpAndSettle();

    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(repo.submitCalls, 0);
    // Le formulaire reste affiché (pas de transition vers l'écran d'attente).
    expect(submitButton, findsOneWidget);
  });
}
