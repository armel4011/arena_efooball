import 'package:arena/data/models/standings.dart';
import 'package:arena/data/repositories/standings_repository.dart';
import 'package:arena/features_user/competitions/group_standings_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

CompetitionGroup _group({String id = 'g-1', String name = 'Groupe A'}) =>
    CompetitionGroup(
      id: id,
      competitionId: 'c-1',
      name: name,
      groupNumber: 1,
    );

GroupStandingRow _row({
  required String pid,
  int? position,
  int played = 0,
  int wins = 0,
  int draws = 0,
  int losses = 0,
  int gf = 0,
  int ga = 0,
  int diff = 0,
  int points = 0,
}) =>
    GroupStandingRow(
      id: 'm-$pid',
      groupId: 'g-1',
      profileId: pid,
      position: position,
      played: played,
      wins: wins,
      draws: draws,
      losses: losses,
      goalsFor: gf,
      goalsAgainst: ga,
      goalDiff: diff,
      points: points,
    );

Widget _scoped(List<StandingsBucket> buckets) => ProviderScope(
      overrides: [
        competitionStandingsProvider
            .overrideWith((ref, _) async => buckets),
      ],
      child: const MaterialApp(
        home: Scaffold(body: GroupStandingsView(competitionId: 'c-1')),
      ),
    );

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  Future<void> bumpViewport(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets('shows the empty state when no buckets are returned',
      (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped(const []));
    await tester.pumpAndSettle();

    expect(find.text('Pas encore de classement'), findsOneWidget);
  });

  testWidgets('renders one DataTable per group with sorted rows',
      (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(
      _scoped([
        StandingsBucket(
          group: _group(name: 'Groupe A'),
          rows: [
            _row(
              pid: 'aaaaaa-leader',
              position: 1,
              played: 3,
              wins: 3,
              gf: 9,
              ga: 2,
              diff: 7,
              points: 9,
            ),
            _row(
              pid: 'bbbbbb-second',
              position: 2,
              played: 3,
              wins: 1,
              draws: 1,
              losses: 1,
              gf: 4,
              ga: 4,
              points: 4,
            ),
          ],
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('GROUPE A'), findsOneWidget);
    expect(find.byType(DataTable), findsOneWidget);
    expect(find.textContaining('Joueur aaaaaa'), findsOneWidget);
    expect(find.textContaining('Joueur bbbbbb'), findsOneWidget);
    // Leader gets a trophy icon.
    expect(find.byIcon(Icons.emoji_events), findsOneWidget);
    // Goal-diff '+7' for the leader.
    expect(find.text('+7'), findsOneWidget);
  });
}
