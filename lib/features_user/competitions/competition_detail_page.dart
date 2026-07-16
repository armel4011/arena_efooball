import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/utils/date_formatter.dart';
import 'package:arena/data/models/competition.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/data/repositories/competition_repository.dart';
import 'package:arena/features_shared/prize_ranks.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_avatar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/features_shared/widgets/empty_state.dart';
import 'package:arena/features_shared/widgets/error_state.dart';
import 'package:arena/features_user/bracket/bracket_view_page.dart';
import 'package:arena/features_user/bracket/group_standings_page.dart';
import 'package:arena/features_user/competitions/competition_schedule_view.dart';
import 'package:arena/features_user/competitions/widgets/competition_phase_ui.dart';
import 'package:arena/features_user/competitions/widgets/referral_progress_card.dart';
import 'package:arena/features_user/home/widgets/upcoming_matches_section.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

part 'competition_detail_widgets.dart';
part 'competition_detail_tabs.dart';

/// Page #11 — `CompetitionDetailPage` (`/competitions/:id`).
///
/// Recree from scratch en suivant `arena_premium_reference.html` (écran
/// #11) : banner premium gradient game-themed, double badge sous-banner,
/// onglets `INFOS / PARTICIPANTS / BRACKET-POULES / CLASSEMENT`. La
/// page conserve sa séparation gated/inscrit :
///
/// * `_GatedDetailView` — joueur non inscrit : banner premium + résumé
///   prize + bloc parrainage (si quota) + CTA `S'INSCRIRE` en bas.
/// * `_DetailBody` — joueur inscrit : banner premium + 4 onglets avec
///   contenus dédiés (les onglets Participants / Bracket-Poules /
///   Classement délèguent à leurs vues spécialisées existantes).
///
/// Providers et routes inchangés : `competitionByIdProvider`,
/// `myRegisteredCompetitionIdsProvider`, `competitionRankingProvider`,
/// `BracketView`, `GroupStandingsPage`.
class CompetitionDetailPage extends ConsumerWidget {
  const CompetitionDetailPage({required this.competitionId, super.key});

  final String competitionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(competitionByIdProvider(competitionId));
    final registeredIds =
        ref.watch(myRegisteredCompetitionIdsProvider).valueOrNull ??
            const <String>{};
    final isRegistered = registeredIds.contains(competitionId);

    return Scaffold(
      appBar: ArenaAppBar(title: l10n.compDetailAppBarTitle),
      body: ArenaScreenBackground(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorState(
            description: e.toString(),
            onRetry: () =>
                ref.invalidate(competitionByIdProvider(competitionId)),
          ),
          data: (c) {
            if (c == null) {
              return EmptyState(
                icon: Icons.search_off_outlined,
                title: l10n.compDetailNotFoundTitle,
                description: l10n.compDetailNotFoundDesc,
              );
            }
            // Gate : sans inscription confirmée, on n'expose pas les
            // détails (bracket, matches, etc.) — le joueur passe d'abord
            // par la page Confirmer inscription.
            if (!isRegistered) {
              return _GatedDetailView(competition: c);
            }
            return _DetailBody(competition: c);
          },
        ),
      ),
    );
  }
}
