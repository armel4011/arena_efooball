import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/competition.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/data/repositories/competition_repository.dart';
import 'package:arena/features_shared/prize_ranks.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_avatar.dart';
import 'package:arena/features_shared/widgets/arena_card.dart';
import 'package:arena/features_shared/widgets/empty_state.dart';
import 'package:arena/features_shared/widgets/error_state.dart';
import 'package:arena/features_user/bracket/bracket_view_page.dart';
import 'package:arena/features_user/bracket/group_standings_page.dart';
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
    final registeredIds =
        ref.watch(myRegisteredCompetitionIdsProvider).valueOrNull ??
            const <String>{};
    final isRegistered = registeredIds.contains(competitionId);

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
          // Gate : sans inscription confirmée, on n'expose pas les
          // détails (bracket, matches, etc.) — le joueur passe d'abord
          // par la page Confirmer inscription.
          if (!isRegistered) {
            return _GatedDetailView(competition: c);
          }
          return _DetailBody(competition: c);
        },
      ),
    );
  }
}

/// Vue affichée quand le joueur n'est pas inscrit à la compétition.
/// Récap minimal de la comp + CTA pour s'inscrire.
class _GatedDetailView extends ConsumerWidget {
  const _GatedDetailView({required this.competition});

  final Competition competition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = competition;
    final isFree = c.isFree;
    final accent = isFree ? ArenaColors.statusOk : ArenaColors.signalBlue;
    final dateLabel = DateFormat('EEEE d MMM yyyy · HH:mm', 'fr')
        .format(c.startDate.toLocal());

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(ArenaSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(ArenaSpacing.lg),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(ArenaRadius.lg),
                border: Border.all(
                  color: accent.withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                children: [
                  Text('🔒', style: ArenaText.h1.copyWith(fontSize: 38)),
                  const SizedBox(height: ArenaSpacing.sm),
                  Text(
                    'Inscris-toi pour accéder au détail',
                    textAlign: TextAlign.center,
                    style: ArenaText.h3,
                  ),
                  const SizedBox(height: ArenaSpacing.xs),
                  Text(
                    'Bracket, matches en direct et chat 1-on-1 sont '
                    'réservés aux joueurs inscrits.',
                    textAlign: TextAlign.center,
                    style: ArenaText.bodyMuted,
                  ),
                ],
              ),
            ),
            const SizedBox(height: ArenaSpacing.lg),
            Container(
              padding: const EdgeInsets.all(ArenaSpacing.lg),
              decoration: BoxDecoration(
                color: ArenaColors.carbon,
                borderRadius: BorderRadius.circular(ArenaRadius.lg),
                border: Border.all(color: ArenaColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.name, style: ArenaText.h2),
                  const SizedBox(height: 4),
                  Text(
                    '${_gameEmoji(c.game)} ${c.game.label} · '
                    '${_formatLabelStatic(c.format)}',
                    style: ArenaText.bodyMuted,
                  ),
                  const SizedBox(height: 4),
                  Text('🗓 $dateLabel', style: ArenaText.bodyMuted),
                  const SizedBox(height: ArenaSpacing.md),
                  Center(
                    child: Column(
                      children: [
                        if (isFree)
                          Text(
                            'GRATUIT',
                            style: ArenaText.bigNumber.copyWith(
                              color: accent,
                              fontSize: 40,
                              letterSpacing: 2,
                            ),
                          )
                        else
                          Text(
                            _prizeFmt(c.prizePoolLocal,
                                c.prizePoolCurrency ?? c.registrationCurrency),
                            style: ArenaText.bigNumber.copyWith(
                              color: accent,
                              fontSize: 32,
                            ),
                          ),
                        const SizedBox(height: 2),
                        Text(
                          isFree ? 'Inscription libre' : 'À gagner',
                          style: ArenaText.bodyMuted,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(ArenaSpacing.md),
              decoration: BoxDecoration(
                color: ArenaColors.carbon,
                borderRadius: BorderRadius.circular(ArenaRadius.md),
                border: Border.all(color: ArenaColors.border),
              ),
              child: Text(
                '↩ Reviens à la liste des compétitions et tape le bouton '
                '"S\'INSCRIRE" sur la carte pour rejoindre cette compétition.',
                style: ArenaText.small,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _prizeFmt(double pool, String currency) {
    final formatted = NumberFormat.decimalPattern('fr')
        .format(pool.round())
        .replaceAll(',', ' ');
    return '$formatted $currency';
  }
}

String _gameEmoji(GameType g) => switch (g) {
      GameType.efootball => '⚽',
      GameType.fifaMobile => '🏆',
      GameType.eaSportsFc => '🎮',
    };

String _formatLabelStatic(TournamentFormat f) => switch (f) {
      TournamentFormat.singleElimination => 'Élimination directe',
      TournamentFormat.groupsThenKnockout => 'Poules + élimination',
      TournamentFormat.roundRobin => 'Round robin',
    };

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
          TabBar(
            labelStyle: ArenaText.button,
            unselectedLabelStyle: ArenaText.button,
            labelColor: ArenaColors.bone,
            unselectedLabelColor: ArenaColors.silver,
            indicatorColor: ArenaColors.signalBlue,
            indicatorWeight: 2,
            tabs: const [
              Tab(text: 'INFOS'),
              Tab(text: 'PARTICIP.'),
              Tab(text: 'BRACKET'),
              Tab(text: 'CLASSEMENT'),
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
                  GroupStandingsPage(competitionId: competition.id),
                _RankingTab(competition: competition),
              ],
            ),
          ),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(
        ArenaSpacing.lg,
        ArenaSpacing.xl - 2,
        ArenaSpacing.lg,
        ArenaSpacing.md,
      ),
      decoration: BoxDecoration(gradient: _gradientFor(competition.game)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: ArenaSpacing.sm,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(ArenaRadius.round),
                ),
                child: Text(
                  _statusLabel(competition.status),
                  style: ArenaText.badge.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(width: ArenaSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: ArenaSpacing.sm,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(ArenaRadius.round),
                ),
                child: Text(
                  competition.game.label.toUpperCase(),
                  style: ArenaText.badge.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: ArenaSpacing.xs + 2),
          Text(
            competition.name.toUpperCase(),
            style: ArenaText.h2.copyWith(
              color: Colors.white,
              fontSize: 22,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _subtitleFor(competition),
            style: ArenaText.bodyMuted.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  static LinearGradient _gradientFor(GameType g) => switch (g) {
        GameType.efootball => ArenaColors.bannerEfoot,
        GameType.fifaMobile => ArenaColors.bannerFifa,
        GameType.eaSportsFc => ArenaColors.bannerFc,
      };

  static String _statusLabel(CompetitionStatus s) => switch (s) {
        CompetitionStatus.draft => 'BROUILLON',
        CompetitionStatus.registrationOpen => 'OPEN',
        CompetitionStatus.registrationClosed => 'COMPLET',
        CompetitionStatus.ongoing => 'EN COURS',
        CompetitionStatus.completed => 'TERMINÉ',
        CompetitionStatus.cancelled => 'ANNULÉ',
      };

  static String _subtitleFor(Competition c) {
    final dateLabel = _formatDateRange(c.startDate, c.endDate);
    if (c.prizePoolLocal > 0) {
      final pool = '${_money(c.prizePoolLocal)} '
          '${c.prizePoolCurrency ?? c.registrationCurrency}';
      return '$dateLabel · Récompense $pool · '
          '${c.currentPlayers}/${c.maxPlayers}';
    }
    return '$dateLabel · ${c.currentPlayers}/${c.maxPlayers}';
  }

  static String _formatDateRange(DateTime start, DateTime? end) {
    final s = DateFormat('d MMM y', 'fr').format(start.toLocal());
    if (end == null) return s;
    final e = DateFormat('d MMM y', 'fr').format(end.toLocal());
    return '$s — $e';
  }

  static String _money(double v) => NumberFormat.decimalPattern('fr').format(v);
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
                  'Récompense',
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

/// Onglet CLASSEMENT — classement général final de la compétition.
/// Lecture seule : l'admin publie les rangs depuis la console, le
/// joueur voit ici le podium et, pour les rangs couverts par
/// `prize_distribution`, le gain associé.
class _RankingTab extends ConsumerWidget {
  const _RankingTab({required this.competition});

  final Competition competition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(competitionRankingProvider(competition.id));

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorState(
        description: e.toString(),
        onRetry: () =>
            ref.invalidate(competitionRankingProvider(competition.id)),
      ),
      data: (entries) {
        if (entries.isEmpty) {
          return const EmptyState(
            icon: Icons.emoji_events_outlined,
            title: 'Aucun participant',
            description: "Personne n'est encore inscrit à cette "
                'compétition.',
          );
        }
        if (!entries.any((e) => e.finalRank != null)) {
          return const EmptyState(
            icon: Icons.emoji_events_outlined,
            title: 'Classement pas encore publié',
            description: 'Les organisateurs publieront le classement '
                'final une fois la compétition terminée.',
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(competitionRankingProvider(competition.id));
            await ref
                .read(competitionRankingProvider(competition.id).future);
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(ArenaSpacing.lg),
            itemCount: entries.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: ArenaSpacing.xs),
            itemBuilder: (_, i) => _RankingEntryRow(
              entry: entries[i],
              competition: competition,
            ),
          ),
        );
      },
    );
  }
}

class _RankingEntryRow extends StatelessWidget {
  const _RankingEntryRow({required this.entry, required this.competition});

  final CompetitionRankingEntry entry;
  final Competition competition;

  @override
  Widget build(BuildContext context) {
    final rank = entry.finalRank;
    final dist = competition.prizeDistribution;
    final hasPrize = rank != null &&
        rank >= 1 &&
        rank <= dist.length &&
        dist[rank - 1] > 0;
    final prize = hasPrize
        ? (competition.prizePoolLocal * dist[rank - 1] / 100).round()
        : null;
    final currency =
        competition.prizePoolCurrency ?? competition.registrationCurrency;
    final initials = entry.username.isNotEmpty
        ? entry.username.substring(0, 1).toUpperCase()
        : '?';

    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(color: ArenaColors.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              rank == null ? '—' : prizeRankEmoji(rank - 1),
              style: ArenaText.body.copyWith(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: ArenaSpacing.xs),
          ArenaAvatar(
            initials: initials,
            color: _avatarColorForSeed(entry.username),
            size: ArenaAvatarSize.sm,
          ),
          const SizedBox(width: ArenaSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.username,
                  style: ArenaText.body,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  rank == null
                      ? 'Non classé'
                      : '${prizeRankLabel(rank - 1)} place',
                  style: ArenaText.bodyMuted,
                ),
              ],
            ),
          ),
          if (prize != null) ...[
            const SizedBox(width: ArenaSpacing.sm),
            Text(
              '${_formatMoney(prize)} $currency',
              style: ArenaText.mono.copyWith(color: ArenaColors.statusOk),
            ),
          ],
        ],
      ),
    );
  }
}

ArenaAvatarColor _avatarColorForSeed(String seed) {
  if (seed.isEmpty) return ArenaAvatarColor.blue;
  return ArenaAvatarColor
      .values[seed.codeUnitAt(0) % ArenaAvatarColor.values.length];
}

String _formatMoney(num v) =>
    NumberFormat.decimalPattern('fr').format(v).replaceAll(',', ' ');
