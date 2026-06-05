import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/repositories/match_repository.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:arena/features_shared/widgets/arena_bracket_tree.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/features_shared/widgets/empty_state.dart';
import 'package:arena/features_shared/widgets/error_state.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
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
            return EmptyState(
              icon: Icons.account_tree_outlined,
              title: l10n.bracketEmptyTitle,
              description: l10n.bracketEmptyDescription,
            );
          }

          // Compte les joueurs distincts pour la caption haut + la
          // résolution des usernames. Set pour dédupliquer (un même
          // joueur n'apparaît qu'une seule fois en R1 par construction
          // d'un bracket).
          final players = <String>{
            for (final m in matches) ...[
              if (m.player1Id != null) m.player1Id!,
              if (m.player2Id != null) m.player2Id!,
            ],
          };
          // Resolution username -> joueur via profilesByIdsProvider (clé
          // = ids triés + joinés). Tant que le futur n'est pas resolu,
          // `profiles` est vide → fallback `P-XXXX` dans la card.
          final joinedIds = (players.toList()..sort()).join(',');
          final profilesAsync = ref.watch(profilesByIdsProvider(joinedIds));
          final usernames = profilesAsync.maybeWhen(
            data: (m) => {
              for (final e in m.entries)
                if (e.value.username.isNotEmpty) e.key: e.value.username,
            },
            orElse: () => const <String, String>{},
          );

          return RefreshIndicator(
            onRefresh: () async {
              ref
                ..invalidate(competitionMatchesProvider(competitionId))
                ..invalidate(profilesByIdsProvider(joinedIds));
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
                    usernamesByPlayerId: usernames,
                    onTapMatch: (m) => context.push(UserRoutes.matchPath(m.id)),
                  ),
                ),
                const SizedBox(height: ArenaSpacing.sm),
                Text(
                  l10n.bracketZoomHint,
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
    final l10n = AppLocalizations.of(context);
    return Text(
      l10n.bracketCaption(playerCount),
      textAlign: TextAlign.center,
      style: ArenaText.monoSmall.copyWith(
        color: ArenaColors.silver,
        letterSpacing: 1.5,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
