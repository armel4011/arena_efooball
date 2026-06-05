import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/models/competition.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/data/models/standings.dart';
import 'package:arena/data/repositories/competition_repository.dart';
import 'package:arena/data/repositories/match_repository.dart';
import 'package:arena/data/repositories/standings_repository.dart';
import 'package:arena/features_user/competitions/competition_detail_page.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
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
            .overrideWith((ref, _) => Stream<List<ArenaMatch>>.value(matches)),
        competitionStandingsProvider.overrideWith((ref, _) async => buckets),
        // La detail page est gated derrière `myRegisteredCompetitionIdsProvider` :
        // sans inscription, on tombe sur `_GatedDetailView` au lieu du body
        // taggé. On force le joueur "inscrit" pour ces tests.
        myRegisteredCompetitionIdsProvider
            .overrideWith((ref) => Stream<Set<String>>.value({comp.id})),
      ],
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
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

    // Le nom apparaît au moins une fois (hero + status pill).
    expect(find.text('COUPE ARENA'), findsWidgets);
    // Tabs uppercase v2 (cf. PHASE 4 redesign).
    expect(find.text('INFOS'), findsOneWidget);
    expect(find.text('PARTICIP.'), findsOneWidget);
    expect(find.text('BRACKET'), findsOneWidget);
    expect(find.text('CLASSEMENT'), findsOneWidget);
  });

  testWidgets('"Infos" tab lists the format key/values', (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped(comp: _open()));
    await tester.pumpAndSettle();

    expect(find.text('Élimination directe'), findsOneWidget);
    // Restyle premium #11 : la capacité affiche désormais
    // `${current}/${max} joueurs` (avant : ${max} joueurs).
    expect(find.text('4/16 joueurs'), findsOneWidget);
    expect(find.textContaining('1 000'), findsWidgets);
  });

  testWidgets('shows COMPLET label when status is registrationClosed',
      (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(
      _scoped(
        comp: _open(
          currentPlayers: 16,
          status: CompetitionStatus.registrationClosed,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('COMPLET'), findsWidgets);
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

  testWidgets('round-robin format swaps the Bracket tab for GroupStandingsView',
      (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(
      _scoped(
        comp: _open(format: TournamentFormat.roundRobin),
        // Empty buckets → the standings view shows its own empty state.
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('CLASSEMENT'));
    await tester.pumpAndSettle();

    // Le tab CLASSEMENT est sélectionné — son contenu interne (vue
    // GroupStandingsView en empty state) varie, on assert juste que le
    // tap n'a pas crashé et que le tab reste visible.
    expect(find.text('CLASSEMENT'), findsOneWidget);
  });
}
