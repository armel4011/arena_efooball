// Routage de StepBody (nouveau flux eFootball : enregistrement d'abord, code
// ensuite). Vérifie quelle vue est rendue selon statut / rôle / présence du
// code / « a rejoint » (team name).

import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/models/match_status.dart';
import 'package:arena/data/repositories/match_repository.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:arena/features_shared/widgets/empty_state.dart';
import 'package:arena/features_user/match_room/match_room_page.dart'
    show MatchRole;
import 'package:arena/features_user/match_room/widgets/match_step_body.dart';
import 'package:arena/features_user/match_room/widgets/room_ready_view.dart';
import 'package:arena/features_user/match_room/widgets/score_flow_view.dart';
import 'package:arena/features_user/match_room/widgets/start_recording_form.dart';
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

class _FakeMatchRepo extends Fake implements MatchRepository {}

ArenaMatch _m({
  MatchStatus status = MatchStatus.pending,
  String? homePlayerId = 'p1',
  String? roomCode,
  String? p1Team,
  String? p2Team,
}) =>
    ArenaMatch(
      id: 'm1',
      competitionId: 'c1',
      player1Id: 'p1',
      player2Id: 'p2',
      status: status,
      homePlayerId: homePlayerId,
      roomCode: roomCode,
      player1TeamName: p1Team,
      player2TeamName: p2Team,
    );

Future<void> _pump(
  WidgetTester tester, {
  required ArenaMatch match,
  required MatchRole role,
  required String selfId,
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentSessionProvider
            .overrideWith((ref) => _FakeSession(_FakeUser(selfId))),
        matchRepositoryProvider.overrideWithValue(_FakeMatchRepo()),
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
            child: StepBody(match: match, role: role, selfId: selfId),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('pending + HOME → écran de démarrage (StartRecordingForm)',
      (tester) async {
    await _pump(tester, match: _m(), role: MatchRole.player1, selfId: 'p1');
    expect(find.byType(StartRecordingForm), findsOneWidget);
  });

  testWidgets("pending + AWAY → attente « l'hôte prépare »", (tester) async {
    await _pump(tester, match: _m(), role: MatchRole.player2, selfId: 'p2');
    expect(find.byType(StartRecordingForm), findsNothing);
    expect(find.byType(EmptyState), findsOneWidget);
  });

  testWidgets('in_progress + HOME sans code → incitation « crée + envoie »',
      (tester) async {
    await _pump(
      tester,
      match: _m(status: MatchStatus.inProgress, p1Team: 'FC Home'),
      role: MatchRole.player1,
      selfId: 'p1',
    );
    // HOME sans code : placeholder, PAS le flux de score (même s'il a rejoint).
    expect(find.byType(ScoreFlowView), findsNothing);
    expect(find.byType(EmptyState), findsOneWidget);
  });

  testWidgets('in_progress + AWAY sans code → « le code arrive »',
      (tester) async {
    await _pump(
      tester,
      match: _m(status: MatchStatus.inProgress),
      role: MatchRole.player2,
      selfId: 'p2',
    );
    expect(find.byType(RoomReadyView), findsNothing);
    expect(find.byType(EmptyState), findsOneWidget);
  });

  testWidgets('in_progress + AWAY + code + pas rejoint → RoomReadyView',
      (tester) async {
    await _pump(
      tester,
      match: _m(status: MatchStatus.inProgress, roomCode: 'ABC12'),
      role: MatchRole.player2,
      selfId: 'p2',
    );
    expect(find.byType(RoomReadyView), findsOneWidget);
  });

  testWidgets('in_progress + joueur ayant rejoint → ScoreFlowView',
      (tester) async {
    await _pump(
      tester,
      // AWAY a rejoint (team name posé) + code présent.
      match: _m(
        status: MatchStatus.inProgress,
        roomCode: 'ABC12',
        p2Team: 'FC Away',
      ),
      role: MatchRole.player2,
      selfId: 'p2',
    );
    expect(find.byType(ScoreFlowView), findsOneWidget);
  });
}
