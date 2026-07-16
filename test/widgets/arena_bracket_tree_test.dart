import 'package:arena/data/models/arena_match.dart';
import 'package:arena/features_shared/widgets/arena_bracket_tree.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Génère un bracket single-elim synthétique de `2^totalRounds` joueurs.
///
/// * Round 1 contient `2^(totalRounds-1)` matches avec deux joueurs
///   inscrits (`p-XXXX` séquentiel) — c'est le seul round dont les
///   slots sont peuplés ; les rounds suivants ont `player1Id` /
///   `player2Id` à `null` (le vainqueur n'a pas encore cascadé).
/// * `matchNumber` est strictement croissant sur l'ensemble du bracket
///   pour respecter l'invariant utilisé par `_BracketConnectors`
///   (chaque paire de matches `[2i, 2i+1]` du round N alimente le
///   match d'index `i` du round N+1).
///
/// Retourne la liste plate (1023 entries pour `totalRounds == 10`).
List<ArenaMatch> _synthBracket(int totalRounds) {
  final matches = <ArenaMatch>[];
  var matchNumber = 1;
  for (var round = 1; round <= totalRounds; round++) {
    final count = 1 << (totalRounds - round);
    for (var i = 0; i < count; i++) {
      matches.add(
        ArenaMatch(
          id: 'm-r$round-$i',
          competitionId: 'comp-test',
          round: round,
          matchNumber: matchNumber++,
          player1Id: round == 1 ? _pid(i * 2) : null,
          player2Id: round == 1 ? _pid(i * 2 + 1) : null,
        ),
      );
    }
  }
  return matches;
}

String _pid(int idx) => 'p-${idx.toString().padLeft(5, '0')}';

void main() {
  group('ArenaBracketTree', () {
    testWidgets('renders a 1024-player bracket without crashing',
        (tester) async {
      // 1024 joueurs = 10 rounds = 1023 matches au total
      // (512 + 256 + 128 + 64 + 32 + 16 + 8 + 4 + 2 + 1).
      final matches = _synthBracket(10);
      expect(matches.length, 1023);

      // Surface volontairement compacte — l'InteractiveViewer interne
      // doit clipper le contenu géant (≈ 22 000 × 950 px) sans erreur,
      // c'est le coeur de ce que valide le test.
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox.expand(
              child: ArenaBracketTree(matches: matches),
            ),
          ),
        ),
      );
      // Pas de pumpAndSettle : l'arbre ne lance pas d'animations, et un
      // bracket 1023 matches mobilise beaucoup de RenderObjects — on
      // garde le pump rapide pour borner le coût du test.
      await tester.pump();

      expect(find.byType(ArenaBracketTree), findsOneWidget);
      // Au moins un CustomPaint = le painter des connecteurs.
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders a 16-player bracket and resolves usernames',
        (tester) async {
      final matches = _synthBracket(4);
      expect(matches.length, 15);

      // Map 2 joueurs sur 16 vers un username explicite — vérifie que
      // la résolution `id -> username` prend le pas sur le fallback
      // `P-XXXX`.
      final usernames = <String, String>{
        _pid(0): 'Alice',
        _pid(1): 'Bob',
      };

      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox.expand(
              child: ArenaBracketTree(
                matches: matches,
                usernamesByPlayerId: usernames,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Les pseudos résolus apparaissent sur leurs cards de R1.
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      // Les autres joueurs (non résolus) tombent sur le fallback
      // `P-XXXX` — au moins une card non résolue présente.
      expect(find.textContaining('P-'), findsWidgets);
    });

    testWidgets("affiche l'horaire des matchs, « — » si non programmé",
        (tester) async {
      // Bracket 4 joueurs : 2 matchs de R1 + la finale. On date le 1er match
      // aujourd'hui et on laisse les autres sans horaire.
      final now = DateTime.now();
      final slot = DateTime(now.year, now.month, now.day, 14, 30);
      final base = _synthBracket(2);
      final matches = [
        base.first.copyWith(scheduledAt: slot),
        ...base.skip(1),
      ];

      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox.expand(child: ArenaBracketTree(matches: matches)),
          ),
        ),
      );
      await tester.pump();

      // Le match daté aujourd'hui montre l'heure seule.
      expect(find.text('14:30'), findsOneWidget);
      // Les matchs sans horaire gardent une ligne (hauteur des cards
      // constante, sinon les connecteurs se désalignent).
      expect(find.text('—'), findsWidgets);
    });

    testWidgets('does not crash when matches list is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: ArenaBracketTree(matches: [])),
        ),
      );
      await tester.pump();
      // L'arbre vide ne plante pas (SizedBox.shrink en sortie de build).
      expect(find.byType(ArenaBracketTree), findsOneWidget);
    });
  });
}
