import 'package:arena/data/models/arena_match.dart';
import 'package:arena/features_shared/widgets/arena_competition_schedule.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

ArenaMatch _m(String id, {DateTime? at, int round = 1, int number = 1}) =>
    ArenaMatch(
      id: id,
      competitionId: 'comp-1',
      round: round,
      matchNumber: number,
      scheduledAt: at,
    );

void main() {
  setUpAll(() async => initializeDateFormatting('fr'));

  group('groupByDay', () {
    test('groupe par jour local et trie les journées', () {
      final j1 = DateTime(2026, 7, 20, 18);
      final j2 = DateTime(2026, 7, 21, 10);
      // Volontairement dans le désordre : le tri est le rôle du groupeur.
      final g = ArenaCompetitionSchedule.groupByDay([
        _m('b', at: j2),
        _m('a', at: j1),
      ]);
      expect(g.days.length, 2);
      expect(g.days.first.day, DateTime(2026, 7, 20));
      expect(g.days.last.day, DateTime(2026, 7, 21));
    });

    test("trie par heure à l'intérieur d'une journée", () {
      final tard = DateTime(2026, 7, 20, 20);
      final tot = DateTime(2026, 7, 20, 9);
      final g = ArenaCompetitionSchedule.groupByDay([
        _m('tard', at: tard),
        _m('tot', at: tot),
      ]);
      expect(g.days.length, 1, reason: 'même jour → une seule section');
      expect(g.days.first.matches.map((m) => m.id).toList(), ['tot', 'tard']);
    });

    test('les matchs sans date sortent à part, triés par round', () {
      final g = ArenaCompetitionSchedule.groupByDay([
        _m('r2', round: 2),
        _m('date', at: DateTime(2026, 7, 20, 18)),
        _m('r1', round: 1),
      ]);
      expect(g.days.length, 1);
      expect(g.days.first.matches.single.id, 'date');
      // Un round non programmé n'est PAS masqué : son absence de date est
      // une information.
      expect(g.unscheduled.map((m) => m.id).toList(), ['r1', 'r2']);
    });

    test('liste vide → aucune journée, aucun non-programmé', () {
      final g = ArenaCompetitionSchedule.groupByDay([]);
      expect(g.days, isEmpty);
      expect(g.unscheduled, isEmpty);
    });
  });

  testWidgets('rend les créneaux, les rounds et la section à programmer',
      (tester) async {
    final now = DateTime.now();
    final slot = DateTime(now.year, now.month, now.day, 18, 30);

    await tester.binding.setSurfaceSize(const Size(500, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ArenaCompetitionSchedule(
            matches: [
              _m('joue', at: slot),
              _m('futur', round: 2, number: 2),
            ],
            usernamesByPlayerId: const {},
            unscheduledLabel: 'À programmer',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('18:30'), findsOneWidget);
    expect(find.text('Round 1'), findsOneWidget);
    expect(find.text('Round 2'), findsOneWidget);
    // Le libellé de section est injecté par le caller (l10n côté user).
    expect(find.text('À PROGRAMMER'), findsOneWidget);
    // Un match sans date garde une ligne, avec un créneau explicitement vide.
    expect(find.text('—'), findsOneWidget);
  });
}
