import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/models/match_status.dart';
import 'package:arena/data/repositories/match_repository.dart';
import 'package:arena/features_user/bracket/bracket_view_page.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ArenaMatch _match({
  required String id,
  required int round,
  required int matchNumber,
  String? p1,
  String? p2,
  int? s1,
  int? s2,
  String? winnerId,
  MatchStatus status = MatchStatus.pending,
}) =>
    ArenaMatch(
      id: id,
      competitionId: 'c-1',
      round: round,
      matchNumber: matchNumber,
      player1Id: p1,
      player2Id: p2,
      score1: s1,
      score2: s2,
      winnerId: winnerId,
      status: status,
    );

Widget _scoped(List<ArenaMatch> matches) => ProviderScope(
      overrides: [
        competitionMatchesProvider
            .overrideWith((ref, _) => Stream<List<ArenaMatch>>.value(matches)),
      ],
      child: const MaterialApp(
        locale: Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: BracketView(competitionId: 'c-1')),
      ),
    );

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  Future<void> bumpViewport(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets('shows the empty state when no matches exist yet',
      (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped(const []));
    await tester.pumpAndSettle();

    expect(find.text('Bracket pas encore généré'), findsOneWidget);
  });

  testWidgets('groups matches by round and renders final card', (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(
      _scoped([
        _match(id: 'm1', round: 1, matchNumber: 1),
        _match(id: 'm2', round: 1, matchNumber: 2),
        _match(id: 'm3', round: 2, matchNumber: 1),
      ]),
    );
    await tester.pumpAndSettle();

    // ArenaBracketTree : la card du dernier round porte le label
    // "FINALE" (sans score, joueurs non encore résolus) + emoji trophée.
    expect(find.text('FINALE'), findsOneWidget);
    expect(find.text('🏆'), findsOneWidget);
    // Caption en haut de la BracketView : compte des joueurs distincts
    // (0 ici puisque tous les player1Id/player2Id sont null).
    expect(find.text('ÉLIMINATION DIRECTE · 0 JOUEURS'), findsOneWidget);
  });

  testWidgets('renders the final score in the finale card', (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(
      _scoped([
        _match(
          id: 'm1',
          round: 1,
          matchNumber: 1,
          p1: 'aaaaaaaa-1111-2222-3333-444444444444',
          p2: 'bbbbbbbb-5555-6666-7777-888888888888',
          s1: 3,
          s2: 1,
          winnerId: 'aaaaaaaa-1111-2222-3333-444444444444',
          status: MatchStatus.completed,
        ),
      ]),
    );
    await tester.pumpAndSettle();

    // Un seul match = finale directe : _FinaleContent rend 🏆 + score
    // formaté "3 — 1" (em dash) plutôt que les labels joueurs.
    expect(find.text('🏆'), findsOneWidget);
    expect(find.text('3 — 1'), findsOneWidget);
    // Caption : 2 joueurs distincts.
    expect(find.text('ÉLIMINATION DIRECTE · 2 JOUEURS'), findsOneWidget);
  });
}
