import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/repositories/competition_repository.dart';
import 'package:arena/features_admin/competitions_admin/widgets/admin_competition_actions_tab.dart';
import 'package:arena/features_admin/competitions_admin/widgets/admin_competition_header.dart';
import 'package:arena/features_admin/competitions_admin/widgets/admin_competition_infos_tab.dart';
import 'package:arena/features_admin/competitions_admin/widgets/admin_competition_matches_tab.dart';
import 'package:arena/features_admin/competitions_admin/widgets/admin_competition_ranking_tab.dart';
import 'package:arena/features_admin/competitions_admin/widgets/admin_competition_registrants_tab.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// PHASE 11 · A9 — admin competition detail with 5 tabs.
///
/// Reads the competition via the existing user-facing
/// [competitionByIdProvider] (it's already realtime and public). Les
/// matchs sont chargés par l'onglet dédié (`AdminCompetitionMatchesTab`).
/// Chaque onglet est extrait dans `widgets/` (PR 2026-05-17, refacto P1
/// audit followup) pour garder cette page sous la barre des 100 lignes.
///
/// Maps to screen A9 of `arena_v2.html`.
class AdminCompetitionDetailPage extends ConsumerWidget {
  const AdminCompetitionDetailPage({
    required this.competitionId,
    super.key,
  });

  final String competitionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compAsync = ref.watch(competitionByIdProvider(competitionId));

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: const ArenaAppBar(title: 'TOURNOI'),
        body: ArenaScreenBackground(
          accent: ArenaColors.neonRed,
          child: SafeArea(
            child: compAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(ArenaSpacing.lg),
                child: Text('Erreur : $e', style: ArenaText.bodyMuted),
              ),
              data: (comp) {
                if (comp == null) {
                  return Center(
                    child: Text(
                      'Compétition introuvable.',
                      style: ArenaText.bodyMuted,
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AdminCompetitionHeader(competition: comp),
                    if (comp.lastBracketError != null)
                      _BracketErrorBanner(
                        error: comp.lastBracketError!,
                        at: comp.lastBracketErrorAt,
                      ),
                    TabBar(
                      isScrollable: true,
                      labelStyle: ArenaText.button,
                      unselectedLabelStyle: ArenaText.button,
                      labelColor: ArenaColors.bone,
                      unselectedLabelColor: ArenaColors.silver,
                      indicatorColor: ArenaColors.signalBlue,
                      indicatorWeight: 2,
                      tabs: const [
                        Tab(text: 'INFOS'),
                        Tab(text: 'INSCRITS'),
                        Tab(text: 'MATCHS'),
                        Tab(text: 'CLASSEMENT'),
                        Tab(text: 'ACTIONS'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          AdminCompetitionInfosTab(competition: comp),
                          AdminCompetitionRegistrantsTab(
                            competitionId: comp.id,
                          ),
                          AdminCompetitionMatchesTab(competitionId: comp.id),
                          AdminCompetitionRankingTab(competitionId: comp.id),
                          AdminCompetitionActionsTab(competition: comp),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Bandeau d'alerte affiché quand la génération/scheduling AUTO du bracket a
/// échoué (colonne `competitions.last_bracket_error`, alimentée par les
/// triggers DB). Rend visible un échec autrement avalé en WARNING.
class _BracketErrorBanner extends StatelessWidget {
  const _BracketErrorBanner({required this.error, this.at});

  final String error;
  final DateTime? at;

  @override
  Widget build(BuildContext context) {
    final whenLabel = at == null
        ? null
        : DateFormat('d MMM y · HH:mm', 'fr').format(at!.toLocal());
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        ArenaSpacing.lg,
        ArenaSpacing.sm,
        ArenaSpacing.lg,
        0,
      ),
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.statusWarn.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(ArenaRadius.md),
        border: Border.all(color: ArenaColors.statusWarn),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: ArenaColors.statusWarn,
            size: 20,
          ),
          const SizedBox(width: ArenaSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Échec auto-bracket',
                  style: ArenaText.body.copyWith(
                    color: ArenaColors.statusWarn,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(error, style: ArenaText.bodyMuted),
                if (whenLabel != null) ...[
                  const SizedBox(height: 2),
                  Text(whenLabel, style: ArenaText.monoSmall),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
