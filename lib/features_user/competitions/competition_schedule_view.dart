import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/repositories/match_repository.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:arena/features_shared/widgets/arena_competition_schedule.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/features_shared/widgets/empty_state.dart';
import 'package:arena/features_shared/widgets/error_state.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Onglet CALENDRIER d'une compétition — le planning COMPLET, tous joueurs
/// confondus.
///
/// Complète « Prochain match », qui ne montre que les matchs du joueur courant :
/// on ne pouvait pas savoir quand jouent les autres, ni lire le déroulé du
/// tournoi. Contrairement au bracket, marche pour TOUS les formats (poules,
/// round-robin) — pas seulement l'élimination directe.
///
/// Réutilise [competitionMatchesProvider] (stream realtime + cache offline) :
/// un décalage de date poussé par l'admin se reflète tout seul.
class CompetitionScheduleView extends ConsumerWidget {
  const CompetitionScheduleView({required this.competitionId, super.key});

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
              icon: Icons.calendar_month_outlined,
              title: l10n.compScheduleEmptyTitle,
              description: l10n.compScheduleEmptyDescription,
            );
          }

          // Même résolution de pseudos que le bracket : clé = ids triés joints.
          // Tant que le futur n'est pas résolu, fallback `P-XXXX`.
          final players = <String>{
            for (final m in matches) ...[
              if (m.player1Id != null) m.player1Id!,
              if (m.player2Id != null) m.player2Id!,
            ],
          };
          final joinedIds = (players.toList()..sort()).join(',');
          final usernames =
              ref.watch(profilesByIdsProvider(joinedIds)).maybeWhen(
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
            child: ArenaCompetitionSchedule(
              matches: matches,
              usernamesByPlayerId: usernames,
              unscheduledLabel: l10n.compScheduleUnscheduled,
              onTapMatch: (m) => context.push(UserRoutes.matchPath(m.id)),
              padding: const EdgeInsets.all(ArenaSpacing.md),
            ),
          );
        },
      ),
    );
  }
}
