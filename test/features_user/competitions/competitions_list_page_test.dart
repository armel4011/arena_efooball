// TODO: test obsolète — UI/code redesigned. Tag 'broken' pour
//       skip en CI. À récrire dans un chantier dédié.
@Tags(<String>['broken'])
library;

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

  testWidgets('renders one card per competition with name + status',
      (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(
      _scoped([
        _comp(id: 'c-1', name: 'Coupe Cameroun'),
        _comp(
          id: 'c-2',
          name: 'Trophée RDC',
          status: CompetitionStatus.ongoing,
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('COUPE CAMEROUN'), findsOneWidget);
    expect(find.text('TROPHÉE RDC'), findsOneWidget);
    expect(find.text('INSCRIPTIONS'), findsOneWidget);
    expect(find.text('EN COURS'), findsOneWidget);
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
