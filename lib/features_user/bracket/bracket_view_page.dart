import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/repositories/match_repository.dart';
import 'package:arena/features_shared/widgets/arena_bracket_tree.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/features_shared/widgets/empty_state.dart';
import 'package:arena/features_shared/widgets/error_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// PHASE 4.D — onglet BRACKET du détail compétition.
///
/// Reconstruit à partir de la maquette #20 de `arena_premium_reference.html` :
/// arbre KO arborescent horizontal (colonnes par round, lignes
/// connectrices, finale en gradient or avec glow), wrappé dans un
/// `InteractiveViewer` (pinch-to-zoom 0.5→3.0×).
///
/// Délègue le rendu à [ArenaBracketTree] et conserve les comportements
/// existants :
/// * Source des matches : `competitionMatchesProvider`.
/// * Pull-to-refresh.
/// * Tap sur un match → `/match/:id` (room du match).
/// * Empty state si l'admin n'a pas encore généré le bracket.
class BracketView extends ConsumerWidget {
  const BracketView({required this.competitionId, super.key});

  final String competitionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(competitionMatchesProvider(competitionId));

    return ArenaScreenBackground(
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          description: e.toString(),
          onRetry: () =>
              ref.invalidate(competitionMatchesProvider(competitionId)),
        ),
        data: (matches) {
          if (matches.isEmpty) {
            return const EmptyState(
              icon: Icons.account_tree_outlined,
              title: 'Bracket pas encore généré',
              description: "Le bracket s'affichera ici dès que l'admin aura"
                  ' clôturé les inscriptions et lancé le tirage.',
            );
          }

          // Compte les joueurs distincts pour la caption haut. On
          // utilise un Set pour dédupliquer (un même joueur n'apparaît
          // qu'une seule fois en R1 par construction d'un bracket).
          final players = <String>{
            for (final m in matches) ...[
              if (m.player1Id != null) m.player1Id!,
              if (m.player2Id != null) m.player2Id!,
            ],
          };

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(competitionMatchesProvider(competitionId));
              await ref.read(competitionMatchesProvider(competitionId).future);
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: ArenaSpacing.md,
                vertical: ArenaSpacing.md,
              ),
              children: [
                _BracketCaption(playerCount: players.length),
                const SizedBox(height: ArenaSpacing.sm),
                SizedBox(
                  height: _treeHeightFor(matches.length),
                  child: ArenaBracketTree(
                    matches: matches,
                    onTapMatch: (m) => context.push(UserRoutes.matchPath(m.id)),
                  ),
                ),
                const SizedBox(height: ArenaSpacing.sm),
                Text(
                  '↔ pince pour zoomer · glisse pour naviguer',
                  textAlign: TextAlign.center,
                  style: ArenaText.small.copyWith(color: ArenaColors.silver),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Hauteur réservée pour l'arbre — proportionnelle au nombre de
  /// matches du R1 (max 8 pour un bracket 16). On garde une borne haute
  /// pour que `InteractiveViewer` ait toujours suffisamment de place
  /// sans forcer le ListView à scroller jusqu'à la caption finale.
  static double _treeHeightFor(int matchCount) {
    if (matchCount >= 15) return 460; // bracket 16
    if (matchCount >= 7) return 320; // bracket 8
    if (matchCount >= 3) return 220; // bracket 4
    return 160; // bracket 2 (finale seule)
  }
}

/// Caption "SINGLE ELIM · N JOUEURS" au-dessus de l'arbre. Reproduit
/// `.m-text-caption text-align: center` de la maquette #20.
class _BracketCaption extends StatelessWidget {
  const _BracketCaption({required this.playerCount});

  final int playerCount;

  @override
  Widget build(BuildContext context) {
    return Text(
      'ÉLIMINATION DIRECTE · $playerCount JOUEURS',
      textAlign: TextAlign.center,
      style: ArenaText.monoSmall.copyWith(
        color: ArenaColors.silver,
        letterSpacing: 1.5,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
