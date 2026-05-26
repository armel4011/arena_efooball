import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/models/match_status.dart';
import 'package:arena/features_shared/widgets/arena_bracket_tree.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:flutter/material.dart';

/// Page de démo `/dev/bracket-showcase` — permet de visualiser le widget
/// `ArenaBracketTree` avec différentes tailles de bracket synthétiques
/// (16 / 64 / 256 / 1024 joueurs) sans avoir à créer une compétition
/// réelle en base.
///
/// Toggle taille en haut : reproduit le test
/// `arena_bracket_tree_test.dart` avec `_synthBracket(N)` mais en
/// runtime, pour valider visuellement le rendu et la fluidité du
/// pinch-to-zoom sur device. Montée uniquement en debug via la route
/// `/dev/bracket-showcase`, accessible depuis `DesignShowcasePage`.
///
/// Les pseudos `Joueur N` sont mappés sur les 8 premiers joueurs pour
/// montrer la résolution `usernamesByPlayerId` (le reste tombe sur le
/// fallback `P-XXXX` de l'arbre).
class BracketShowcasePage extends StatefulWidget {
  const BracketShowcasePage({super.key});

  @override
  State<BracketShowcasePage> createState() => _BracketShowcasePageState();
}

class _BracketShowcasePageState extends State<BracketShowcasePage> {
  int _playerCount = 16;

  @override
  Widget build(BuildContext context) {
    final totalRounds = _log2(_playerCount);
    final matches = _synthBracket(totalRounds);
    // Mappe les 8 premiers joueurs vers des pseudos lisibles — au-delà
    // l'arbre affichera le fallback `P-XXXX` (suffit pour valider le
    // mix résolu/non-résolu sans saturer la légende).
    final usernames = <String, String>{
      for (var i = 0; i < 8; i++) _pid(i): 'Joueur ${i + 1}',
    };

    return Scaffold(
      appBar: AppBar(
        backgroundColor: ArenaColors.carbon,
        title: Text('Bracket showcase', style: ArenaText.appBarTitle),
        iconTheme: const IconThemeData(color: ArenaColors.bone),
      ),
      body: ArenaScreenBackground(
        child: Column(
          children: [
            const SizedBox(height: ArenaSpacing.md),
            _SizeToggle(
              current: _playerCount,
              onSelect: (n) => setState(() => _playerCount = n),
            ),
            const SizedBox(height: ArenaSpacing.sm),
            Text(
              '$_playerCount joueurs · $totalRounds rounds · '
              '${matches.length} matches',
              style: ArenaText.monoSmall.copyWith(color: ArenaColors.silver),
            ),
            const SizedBox(height: ArenaSpacing.sm),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(ArenaSpacing.sm),
                child: ArenaBracketTree(
                  matches: matches,
                  usernamesByPlayerId: usernames,
                  onTapMatch: (m) => _showMatchToast(context, m),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: ArenaSpacing.md),
              child: Text(
                '↔ pince pour zoomer · glisse pour naviguer',
                style: ArenaText.small.copyWith(color: ArenaColors.silver),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMatchToast(BuildContext context, ArenaMatch m) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 1),
        content: Text(
          'Match R${m.round} · ${m.player1Id ?? "—"} vs ${m.player2Id ?? "—"}',
          style: ArenaText.small,
        ),
      ),
    );
  }
}

/// Toggle 16 / 64 / 256 / 1024 joueurs — pills horizontales avec accent
/// `signalBlue` sur la valeur courante.
class _SizeToggle extends StatelessWidget {
  const _SizeToggle({required this.current, required this.onSelect});

  final int current;
  final ValueChanged<int> onSelect;

  static const _sizes = [16, 64, 256, 1024];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        for (final n in _sizes)
          _Pill(
            label: '$n',
            selected: n == current,
            onTap: () => onSelect(n),
          ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ArenaRadius.round),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? ArenaColors.signalBlue.withValues(alpha: 0.18)
              : ArenaColors.carbon,
          borderRadius: BorderRadius.circular(ArenaRadius.round),
          border: Border.all(
            color: selected ? ArenaColors.signalBlue : ArenaColors.border,
          ),
        ),
        child: Text(
          label,
          style: ArenaText.mono.copyWith(
            color: selected ? ArenaColors.signalBlue : ArenaColors.silver,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

/// Génère un bracket single-elim synthétique de `2^totalRounds` joueurs.
/// Mêmes invariants que `_synthBracket` dans le test unitaire :
/// `matchNumber` strictement croissant pour respecter l'alignement des
/// connecteurs entre rounds.
List<ArenaMatch> _synthBracket(int totalRounds) {
  final matches = <ArenaMatch>[];
  var matchNumber = 1;
  for (var round = 1; round <= totalRounds; round++) {
    final count = 1 << (totalRounds - round);
    for (var i = 0; i < count; i++) {
      matches.add(
        ArenaMatch(
          id: 'm-r$round-$i',
          competitionId: 'comp-showcase',
          round: round,
          matchNumber: matchNumber++,
          player1Id: round == 1 ? _pid(i * 2) : null,
          player2Id: round == 1 ? _pid(i * 2 + 1) : null,
          status: MatchStatus.pending,
        ),
      );
    }
  }
  return matches;
}

String _pid(int idx) => 'p-${idx.toString().padLeft(5, '0')}';

int _log2(int n) {
  var r = 0;
  var v = n;
  while (v > 1) {
    v >>= 1;
    r++;
  }
  return r;
}
