import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/competition.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/data/repositories/competition_repository.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_card.dart';
import 'package:arena/features_shared/widgets/empty_state.dart';
import 'package:arena/features_shared/widgets/error_state.dart';
import 'package:arena/features_user/competitions/bracket_view_page.dart';
import 'package:arena/features_user/competitions/group_standings_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// PHASE 4 — single competition detail page with 4 tabs.
///
/// The Participants / Bracket / Prizes tabs show light placeholders.
/// They'll be wired against `registrations` / `phases` / `prizes`
/// streams in sub-steps 4.D (Bracket) and 4.E (Standings + Prizes).
class CompetitionDetailPage extends ConsumerWidget {
  const CompetitionDetailPage({required this.competitionId, super.key});

  final String competitionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(competitionByIdProvider(competitionId));

    return Scaffold(
      appBar: const ArenaAppBar(title: 'Compétition'),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          description: e.toString(),
          onRetry: () =>
              ref.invalidate(competitionByIdProvider(competitionId)),
        ),
        data: (c) {
          if (c == null) {
            return const EmptyState(
              icon: Icons.search_off_outlined,
              title: 'Compétition introuvable',
              description: 'Elle a peut-être été supprimée par un admin.',
            );
          }
          return _DetailBody(competition: c);
        },
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.competition});

  final Competition competition;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(competition: competition),
          const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Infos'),
              Tab(text: 'Participants'),
              Tab(text: 'Bracket'),
              Tab(text: 'Prix'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _InfosTab(competition: competition),
                const _DeferredTab(
                  phase: 'PHASE 4.E',
                  icon: Icons.people_outline,
                  title: 'Liste des participants',
                  description: 'La liste des inscrits avec avatars et stats'
                      ' arrivera ici. Source : table `registrations`.',
                ),
                if (competition.format.isBracket)
                  BracketView(competitionId: competition.id)
                else
                  GroupStandingsView(competitionId: competition.id),
                const _DeferredTab(
                  phase: 'PHASE 4.E',
                  icon: Icons.emoji_events_outlined,
                  title: 'Top 4 récompenses',
                  description: 'Les prix (mode pourcentage ou montant fixe)'
                      ' apparaîtront ici. Source : table `prizes`.',
                ),
              ],
            ),
          ),
          _RegistrationCta(competition: competition),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.competition});

  final Competition competition;

  @override
  Widget build(BuildContext context) {
    final accent = _accentForGame(competition.game);
    return Container(
      padding: const EdgeInsets.fromLTRB(
        ArenaSpacing.lg,
        ArenaSpacing.lg,
        ArenaSpacing.lg,
        ArenaSpacing.md,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.18),
            ArenaColors.bg,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: ArenaSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  borderRadius: ArenaRadius.pill,
                ),
                child: Text(
                  competition.game.label.toUpperCase(),
                  style: ArenaTypography.labelLarge.copyWith(
                    color: accent,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: ArenaSpacing.sm),
              _StatusPill(status: competition.status),
            ],
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Text(
            competition.name.toUpperCase(),
            style: ArenaTypography.displayMedium,
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Row(
            children: [
              const Icon(
                Icons.event_outlined,
                size: 16,
                color: ArenaColors.textMuted,
              ),
              const SizedBox(width: ArenaSpacing.xs),
              Text(
                _formatDateRange(competition.startDate, competition.endDate),
                style: ArenaTypography.bodyMedium.copyWith(
                  color: ArenaColors.textMuted,
                ),
              ),
              const SizedBox(width: ArenaSpacing.md),
              const Icon(
                Icons.people_outline,
                size: 16,
                color: ArenaColors.textMuted,
              ),
              const SizedBox(width: ArenaSpacing.xs),
              Text(
                '${competition.currentPlayers} / ${competition.maxPlayers}',
                style: ArenaTypography.bodyMedium.copyWith(
                  color: ArenaColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Color _accentForGame(GameType g) => switch (g) {
        GameType.efootball => ArenaColors.efootball,
        GameType.fifaMobile => ArenaColors.fifa,
        GameType.eaSportsFc => ArenaColors.fcMobile,
      };

  static String _formatDateRange(DateTime start, DateTime? end) {
    final s = DateFormat('d MMM y', 'fr').format(start.toLocal());
    if (end == null) return s;
    final e = DateFormat('d MMM y', 'fr').format(end.toLocal());
    return '$s — $e';
  }
}

class _InfosTab extends StatelessWidget {
  const _InfosTab({required this.competition});

  final Competition competition;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(ArenaSpacing.lg),
      children: [
        if (competition.description != null &&
            competition.description!.isNotEmpty) ...[
          ArenaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DESCRIPTION', style: ArenaTypography.labelLarge),
                const SizedBox(height: ArenaSpacing.sm),
                Text(
                  competition.description!,
                  style: ArenaTypography.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: ArenaSpacing.md),
        ],
        ArenaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('FORMAT', style: ArenaTypography.labelLarge),
              const SizedBox(height: ArenaSpacing.sm),
              _kv('Type', _formatLabel(competition.format)),
              _kv('Capacité', '${competition.maxPlayers} joueurs'),
              _kv(
                "Frais d'inscription",
                competition.registrationFee == 0
                    ? 'Gratuit'
                    : '${_money(competition.registrationFee)}'
                        ' ${competition.registrationCurrency}',
              ),
              _kv('Commission ARENA', '${competition.commissionPct} %'),
              if (competition.prizePoolLocal > 0)
                _kv(
                  'Cagnotte',
                  '${_money(competition.prizePoolLocal)}'
                  ' ${competition.prizePoolCurrency ?? competition.registrationCurrency}',
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              k,
              style: ArenaTypography.bodyMedium.copyWith(
                color: ArenaColors.textMuted,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(v, style: ArenaTypography.bodyMedium),
          ),
        ],
      ),
    );
  }

  static String _formatLabel(TournamentFormat f) => switch (f) {
        TournamentFormat.singleElimination => 'Élimination directe',
        TournamentFormat.groupsThenKnockout => 'Poules + élimination',
        TournamentFormat.roundRobin => 'Round robin',
      };

  static String _money(double v) => NumberFormat.decimalPattern('fr').format(v);
}

class _DeferredTab extends StatelessWidget {
  const _DeferredTab({
    required this.phase,
    required this.icon,
    required this.title,
    required this.description,
  });

  final String phase;
  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: icon,
      title: title,
      description: '$phase — $description',
    );
  }
}

class _RegistrationCta extends StatelessWidget {
  const _RegistrationCta({required this.competition});

  final Competition competition;

  @override
  Widget build(BuildContext context) {
    final (label, enabled) = _ctaState(competition);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(ArenaSpacing.lg),
        child: ArenaButton(
          label: label,
          fullWidth: true,
          size: ArenaButtonSize.large,
          onPressed: enabled
              ? () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Paiement de l'inscription : PHASE 11bis"
                        ' (CinetPay / NowPayments).',
                      ),
                    ),
                  );
                }
              : null,
        ),
      ),
    );
  }

  static (String, bool) _ctaState(Competition c) {
    if (c.status.isCancelled) return ('ANNULÉ', false);
    if (c.status.isCompleted) return ('TERMINÉ', false);
    if (c.status == CompetitionStatus.registrationClosed) {
      return ('INSCRIPTIONS FERMÉES', false);
    }
    if (!c.canRegister) {
      return c.spotsLeft == 0 ? ('COMPLET', false) : ('BIENTÔT OUVERT', false);
    }
    return ("S'INSCRIRE", true);
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final CompetitionStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      CompetitionStatus.draft => ('BROUILLON', ArenaColors.textMuted),
      CompetitionStatus.registrationOpen =>
        ('INSCRIPTIONS', ArenaColors.success),
      CompetitionStatus.registrationClosed =>
        ('COMPLET', ArenaColors.warning),
      CompetitionStatus.ongoing => ('EN COURS', ArenaColors.success),
      CompetitionStatus.completed => ('TERMINÉ', ArenaColors.textMuted),
      CompetitionStatus.cancelled => ('ANNULÉ', ArenaColors.danger),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ArenaSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: ArenaRadius.pill,
      ),
      child: Text(
        label,
        style: ArenaTypography.labelLarge.copyWith(
          color: color,
          fontSize: 11,
        ),
      ),
    );
  }
}
