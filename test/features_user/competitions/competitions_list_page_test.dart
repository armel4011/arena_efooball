import 'package:arena/data/models/competition.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/data/repositories/competition_repository.dart';
import 'package:arena/features_user/competitions/competitions_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

Competition _comp({
  String id = 'c-1',
  String name = 'Coupe ARENA',
  GameType game = GameType.efootball,
  CompetitionStatus status = CompetitionStatus.registrationOpen,
  int maxPlayers = 16,
  int currentPlayers = 4,
}) =>
    Competition(
      id: id,
      name: name,
      game: game,
      format: TournamentFormat.singleElimination,
      startDate: DateTime(2026, 6, 1),
      status: status,
      maxPlayers: maxPlayers,
      currentPlayers: currentPlayers,
    );

Widget _scoped(List<Competition> items) => ProviderScope(
      overrides: [
        competitionsListProvider
            .overrideWith((ref, _) => Stream<List<Competition>>.value(items)),
      ],
      child: const MaterialApp(home: Scaffold(body: CompetitionsListPage())),
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

  testWidgets('shows the empty state when there are no competitions',
      (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped(const []));
    await tester.pumpAndSettle();

    expect(find.text('Aucune compétition'), findsOneWidget);
    expect(find.text('Tous'), findsOneWidget);
    expect(find.text('eFootball'), findsOneWidget);
    expect(find.text('FIFA Mobile'), findsOneWidget);
    expect(find.text('EA SPORTS FC Mobile'), findsOneWidget);
  });

  testWidgets('renders one card per competition under the default filter',
      (tester) async {
    // Bucket statut "À venir" par défaut → ne montre que les comps en
    // registrationOpen / draft / registrationClosed. On donne 2 comps
    // qui matchent ce bucket pour vérifier qu'elles rendent toutes.
    // (Le nom est affiché tel quel dans le _FreeCompetitionCard, donc
    // pas d'uppercase dans l'assertion.)
    await bumpViewport(tester);
    await tester.pumpWidget(
      _scoped([
        _comp(id: 'c-1', name: 'Coupe Cameroun'),
        _comp(id: 'c-2', name: 'Trophée RDC'),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Coupe Cameroun'), findsOneWidget);
    expect(find.text('Trophée RDC'), findsOneWidget);
    // Deux comps gratuites (fee = 0 par défaut) → 2 badges "GRATUITE".
    expect(find.text('GRATUITE'), findsNWidgets(2));
  });

  testWidgets('filter chip toggles selection visually', (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped(const []));
    await tester.pumpAndSettle();

    await tester.tap(find.text('eFootball'));
    await tester.pumpAndSettle();

    // The filtered empty-state copy switches to mention the selected
    // game.
    expect(
      find.text('Aucune compétition sur eFootball'),
      findsOneWidget,
    );
  });
}
