import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/models/competition.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/data/models/standings.dart';
import 'package:arena/data/repositories/competition_repository.dart';
import 'package:arena/data/repositories/match_repository.dart';
import 'package:arena/data/repositories/standings_repository.dart';
import 'package:arena/features_user/competitions/competition_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

Competition _open({
  TournamentFormat format = TournamentFormat.singleElimination,
  CompetitionStatus status = CompetitionStatus.registrationOpen,
  int maxPlayers = 16,
  int currentPlayers = 4,
}) =>
    Competition(
      id: 'c-1',
      name: 'Coupe ARENA',
      game: GameType.efootball,
      format: format,
      startDate: DateTime(2026, 6, 1),
      endDate: DateTime(2026, 6, 7),
      status: status,
      maxPlayers: maxPlayers,
      currentPlayers: currentPlayers,
      registrationFee: 1000,
      registrationCurrency: 'XAF',
      description: 'Tournoi national pendant la Coupe du Monde.',
    );

Widget _scoped({
  required Competition comp,
  List<ArenaMatch> matches = const [],
  List<StandingsBucket> buckets = const [],
}) =>
    ProviderScope(
      overrides: [
        competitionByIdProvider
            .overrideWith((ref, _) => Stream<Competition?>.value(comp)),
        competitionMatchesProvider
            .overrideWith((ref, _) async => matches),
        competitionStandingsProvider
            .overrideWith((ref, _) async => buckets),
      ],
      child: MaterialApp(
        home: CompetitionDetailPage(competitionId: comp.id),
      ),
    );

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('fr');
  });

  Future<void> bumpViewport(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets('renders header, 4 tabs and the registration CTA',
      (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped(comp: _open()));
    await tester.pumpAndSettle();

    expect(find.text('COUPE ARENA'), findsOneWidget);
    expect(find.text('Infos'), findsOneWidget);
    expect(find.text('Participants'), findsOneWidget);
    expect(find.text('Bracket'), findsOneWidget);
    expect(find.text('Prix'), findsOneWidget);
    expect(find.text("S'INSCRIRE"), findsOneWidget);
  });

  testWidgets('"Infos" tab lists the format key/values', (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped(comp: _open()));
    await tester.pumpAndSettle();

    expect(find.text('Élimination directe'), findsOneWidget);
    expect(find.text('16 joueurs'), findsOneWidget);
    expect(find.textContaining('1 000'), findsWidgets);
  });

  testWidgets('CTA reads "COMPLET" when current_players hits the cap',
      (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(
      _scoped(comp: _open(currentPlayers: 16)),
    );
    await tester.pumpAndSettle();

    expect(find.text('COMPLET'), findsWidgets);
    expect(find.text("S'INSCRIRE"), findsNothing);
  });

  testWidgets('CTA reads "TERMINÉ" once status flips to completed',
      (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(
      _scoped(comp: _open(status: CompetitionStatus.completed)),
    );
    await tester.pumpAndSettle();

    expect(find.text('TERMINÉ'), findsWidgets);
  });

  testWidgets(
      'round-robin format swaps the Bracket tab for GroupStandingsView',
      (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(
      _scoped(
        comp: _open(format: TournamentFormat.roundRobin),
        // Empty buckets → the standings view shows its own empty state.
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bracket'));
    await tester.pumpAndSettle();

    expect(find.text('Pas encore de classement'), findsOneWidget);
  });
}
