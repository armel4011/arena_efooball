import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
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
import 'package:arena/features_user/competitions/widgets/referral_progress_card.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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

/// Banner premium — reproduit `.m-banner` 100 px de la maquette : un
/// gradient game-themed (eFoot bleu / FIFA vert / FC orange), caption
/// mono `{JEU} · {dates}` semi-transparent en haut, titre Bebas Neue 28
/// px sur l'image en bas. Le titre est uppercase, peut wrap sur 2
/// lignes (`maxLines: 2`).
class _PremiumBanner extends StatelessWidget {
  const _PremiumBanner({required this.competition});

  final Competition competition;

  @override
  Widget build(BuildContext context) {
    final c = competition;
    final dates = _formatDateRange(c.startDate, c.endDate);
    final caption = '${c.game.label.toUpperCase()} · $dates';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        ArenaSpacing.lg,
        ArenaSpacing.md,
        ArenaSpacing.lg,
        ArenaSpacing.md,
      ),
      decoration: BoxDecoration(gradient: _gradientFor(c.game)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            caption,
            style: ArenaText.monoSmall.copyWith(
              color: ArenaColors.bone.withValues(alpha: 0.75),
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            c.name.toUpperCase(),
            style: ArenaText.h1.copyWith(
              color: ArenaColors.bone,
              fontSize: 28,
              letterSpacing: 1.5,
              height: 1,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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

  static String _formatDateRange(DateTime start, DateTime? end) {
    final s = DateFormat('d MMM y', 'fr').format(start.toLocal());
    if (end == null) return s;
    final e = DateFormat('d MMM y', 'fr').format(end.toLocal());
    return '$s — $e';
  }
}

/// Ligne de 2 badges sous le banner : statut (OUVERT/EN COURS/COMPLET…)
/// et capacité (`12/16`). Reproduit `.m-row gap:6px` de la maquette,
/// rendu hors banner pour rester lisible sur fond ArenaScreenBackground.
class _BannerBadges extends StatelessWidget {
  const _BannerBadges({required this.competition});

  final Competition competition;

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusColor) = _statusFor(competition.status);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ArenaSpacing.lg,
        ArenaSpacing.md,
        ArenaSpacing.lg,
        0,
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          _Pill(label: statusLabel, accent: statusColor),
          _Pill(
            label: '${competition.currentPlayers}/${competition.maxPlayers}',
            accent: ArenaColors.signalBlue,
          ),
        ],
      ),
    );
  }

  static (String, Color) _statusFor(CompetitionStatus s) => switch (s) {
        CompetitionStatus.draft => ('BROUILLON', ArenaColors.silver),
        CompetitionStatus.registrationOpen => ('OUVERT', ArenaColors.statusOk),
        CompetitionStatus.registrationClosed => (
            'COMPLET',
            ArenaColors.statusWarn,
          ),
        CompetitionStatus.ongoing => ('EN COURS', ArenaColors.signalBlue),
        CompetitionStatus.completed => ('TERMINÉ', ArenaColors.silver),
        CompetitionStatus.cancelled => ('ANNULÉ', ArenaColors.neonRed),
      };
}

/// Pill colorée (status / capacity) — fond `accent @ 15 %`, border
/// `accent @ 50 %`, texte `accent` bold mono.
class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.15),
        border: Border.all(color: accent.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(ArenaRadius.round),
      ),
      child: Text(
        label,
        style: ArenaText.badge.copyWith(
          color: accent,
          letterSpacing: 1,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Vue affichée quand le joueur n'est pas inscrit. Reproduit la maquette
/// #11 jusqu'au CTA bottom : banner premium + badges + récap prize/
/// gratuit + bloc parrainage si quota + bouton `S'INSCRIRE` collé en
/// bas (mode payant : montant + devise ; mode gratuit : "gratuitement").
class _GatedDetailView extends ConsumerWidget {
  const _GatedDetailView({required this.competition});

  final Competition competition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = competition;
    final isFree = c.isFree;
    final accent = isFree ? ArenaColors.statusOk : ArenaColors.tierGoldWarm;
    final canRegister = c.canRegister;
    final ctaLabel = isFree
        ? l10n.compDetailCtaRegisterFree
        : '${l10n.compDetailCtaRegisterPaidPrefix}'
            '${_money(c.registrationFee)} ${c.registrationCurrency}';

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _PremiumBanner(competition: c),
                _BannerBadges(competition: c),
                const SizedBox(height: ArenaSpacing.lg),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ArenaSpacing.lg,
                  ),
                  child: _GatedPrizeCard(competition: c, accent: accent),
                ),
                if (c.referralQuota > 0) ...[
                  const SizedBox(height: ArenaSpacing.md),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: ArenaSpacing.lg,
                    ),
                    child: ReferralProgressCard(
                      competitionId: c.id,
                      referralQuota: c.referralQuota,
                    ),
                  ),
                ],
                const SizedBox(height: ArenaSpacing.lg),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ArenaSpacing.lg,
                  ),
                  child: Text(
                    l10n.compDetailGatedLockNotice,
                    style: ArenaText.small.copyWith(
                      color: ArenaColors.silver,
                    ),
                  ),
                ),
                const SizedBox(height: ArenaSpacing.xl),
              ],
            ),
          ),
          // CTA collé en bas, comme la maquette `m-btn m-btn-primary
          // margin-top: auto`.
          Padding(
            padding: const EdgeInsets.fromLTRB(
              ArenaSpacing.lg,
              ArenaSpacing.sm,
              ArenaSpacing.lg,
              ArenaSpacing.md,
            ),
            child: ArenaButton(
              label: canRegister ? ctaLabel : l10n.compDetailRegistrationsClosed,
              variant: canRegister
                  ? ArenaButtonVariant.primary
                  : ArenaButtonVariant.secondary,
              fullWidth: true,
              onPressed: canRegister
                  ? () => context.push(
                        UserRoutes.registrationConfirmPath(c.id),
                        extra: _confirmArgsFor(c),
                      )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  static RegistrationConfirmArgs _confirmArgsFor(Competition c) {
    final dateLabel =
        DateFormat('d MMM yyyy · HH:mm', 'fr').format(c.startDate.toLocal());
    return RegistrationConfirmArgs(
      competitionName: c.name,
      gameLabel: c.game.label,
      gameEmoji: _gameEmoji(c.game),
      dateLabel: dateLabel,
      formatLabel: _formatLabel(c.format),
      entryFeeXaf: c.registrationFee.round(),
      totalPrizeXaf: c.prizePoolLocal.round(),
      prizeDistribution: c.prizeDistribution,
      androidStoreUrl: c.androidStoreUrl,
      iosStoreUrl: c.iosStoreUrl,
    );
  }

  static String _money(double v) =>
      NumberFormat.decimalPattern('fr').format(v).replaceAll(',', ' ');
}

/// Card "À gagner" / "Inscription libre" affichée dans la vue gated.
/// Mode payant : ShaderMask gold sur le montant en bigNumber. Mode
/// gratuit : "GRATUIT" en vert (statusOk).
class _GatedPrizeCard extends StatelessWidget {
  const _GatedPrizeCard({required this.competition, required this.accent});

  final Competition competition;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = competition;
    final isFree = c.isFree;
    final prize = isFree
        ? l10n.compDetailPrizeFree
        : '${_money(c.prizePoolLocal)} '
            '${c.prizePoolCurrency ?? c.registrationCurrency}';

    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.lg),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            isFree ? l10n.compDetailPrizeFreeLabel : l10n.compDetailPrizeToWinLabel,
            style: ArenaText.monoSmall.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            prize,
            style: ArenaText.bigNumber.copyWith(
              color: accent,
              fontSize: isFree ? 36 : 32,
              letterSpacing: 2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  static String _money(double v) =>
      NumberFormat.decimalPattern('fr').format(v).replaceAll(',', ' ');
}

/// Body principal — joueur inscrit. Banner premium + badges + TabBar 4
/// onglets `INFOS / PARTICIP. / {BRACKET|POULES} / CLASSEMENT`.
class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.competition});

  final Competition competition;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DefaultTabController(
      length: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PremiumBanner(competition: competition),
          _BannerBadges(competition: competition),
          const SizedBox(height: ArenaSpacing.sm),
          TabBar(
            labelStyle: ArenaText.button,
            unselectedLabelStyle: ArenaText.button,
            labelColor: ArenaColors.bone,
            unselectedLabelColor: ArenaColors.silver,
            indicatorColor: ArenaColors.signalBlue,
            indicatorWeight: 2,
            tabs: [
              Tab(text: l10n.compDetailTabInfos),
              Tab(text: l10n.compDetailTabParticipants),
              // L'onglet 2 montre le bracket pour une élimination directe,
              // mais le classement des poules pour groups_then_knockout
              // et round_robin — d'où le label dynamique.
              Tab(
                text:
                    competition.format == TournamentFormat.singleElimination
                        ? l10n.compDetailTabBracket
                        : l10n.compDetailTabGroups,
              ),
              Tab(text: l10n.compDetailTabRanking),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _InfosTab(competition: competition),
                _DeferredTab(
                  phase: 'PHASE 4.E',
                  icon: Icons.people_outline,
                  title: l10n.compDetailParticipantsTitle,
                  description: l10n.compDetailParticipantsDesc,
                ),
                // Fix item 5 (2026-05-19) : `isBracket` est true pour
                // groups_then_knockout aussi → la GroupStandingsPage
                // n'était jamais affichée. On switch maintenant sur le
                // format exact : seul single_elimination → BracketView.
                if (competition.format == TournamentFormat.singleElimination)
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

/// Onglet INFOS — rows clé/valeur premium avec emoji marker. Reproduit
/// la maquette : 💰 Prize pool / 🎮 Format / 📅 Démarrage / 🏟 Capacité,
/// chacun sur une ligne séparée par une fine border 6 %.
class _InfosTab extends StatelessWidget {
  const _InfosTab({required this.competition});

  final Competition competition;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = competition;
    final dateLabel =
        DateFormat('EEEE d MMM y · HH:mm', 'fr').format(c.startDate.toLocal());
    final prizeLabel = c.prizePoolLocal > 0
        ? '${_money(c.prizePoolLocal)} '
            '${c.prizePoolCurrency ?? c.registrationCurrency}'
        : l10n.compDetailInfoPrizeNone;
    final feeLabel = c.registrationFee == 0
        ? l10n.compDetailInfoFeeFree
        : '${_money(c.registrationFee)} ${c.registrationCurrency}';
    final hasDescription =
        c.description != null && c.description!.trim().isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(ArenaSpacing.lg),
      children: [
        _InfoRow(
          emoji: '💰',
          label: l10n.compDetailInfoPrizeLabel,
          value: prizeLabel,
          valueColor: c.prizePoolLocal > 0 ? ArenaColors.tierGoldWarm : null,
          mono: true,
        ),
        _InfoRow(
          emoji: '💸',
          label: l10n.compDetailInfoFeeLabel,
          value: feeLabel,
          valueColor: c.registrationFee == 0 ? ArenaColors.statusOk : null,
          mono: c.registrationFee != 0,
        ),
        _InfoRow(
          emoji: '🎮',
          label: l10n.compDetailInfoFormatLabel,
          value: _formatLabel(c.format),
        ),
        _InfoRow(
          emoji: '📅',
          label: l10n.compDetailInfoStartLabel,
          value: dateLabel,
        ),
        _InfoRow(
          emoji: '🏟',
          label: l10n.compDetailInfoCapacityLabel,
          value: '${c.currentPlayers}/${c.maxPlayers}'
              '${l10n.compDetailInfoCapacitySuffix}',
        ),
        if (hasDescription) ...[
          const SizedBox(height: ArenaSpacing.md),
          Text(
            l10n.compDetailDescriptionHeader,
            style: ArenaText.monoSmall.copyWith(
              color: ArenaColors.silver,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: ArenaSpacing.xs),
          Text(c.description!.trim(), style: ArenaText.body),
        ],
      ],
    );
  }

  static String _money(double v) =>
      NumberFormat.decimalPattern('fr').format(v).replaceAll(',', ' ');
}

/// Une ligne clé/valeur du tab INFOS — emoji marker + label silver +
/// valeur bone (ou colorée si valueColor) bold. Border bottom 6 %
/// translucide pour séparer visuellement les lignes sans trop charger.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.emoji,
    required this.label,
    required this.value,
    this.valueColor,
    this.mono = false,
  });

  final String emoji;
  final String label;
  final String value;
  final Color? valueColor;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: ArenaSpacing.sm),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: ArenaColors.bone.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: ArenaSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: ArenaText.small.copyWith(color: ArenaColors.silver),
            ),
          ),
          const SizedBox(width: ArenaSpacing.sm),
          Text(
            value,
            style: (mono ? ArenaText.mono : ArenaText.body).copyWith(
              color: valueColor ?? ArenaColors.bone,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            textAlign: TextAlign.end,
          ),
        ],
      ),
    );
  }
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
    final l10n = AppLocalizations.of(context);
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
          return EmptyState(
            icon: Icons.emoji_events_outlined,
            title: l10n.compDetailRankingNoParticipantTitle,
            description: l10n.compDetailRankingNoParticipantDesc,
          );
        }
        if (!entries.any((e) => e.finalRank != null)) {
          return EmptyState(
            icon: Icons.emoji_events_outlined,
            title: l10n.compDetailRankingNotPublishedTitle,
            description: l10n.compDetailRankingNotPublishedDesc,
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(competitionRankingProvider(competition.id));
            await ref.read(competitionRankingProvider(competition.id).future);
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
    final l10n = AppLocalizations.of(context);
    final rank = entry.finalRank;
    final dist = competition.prizeDistribution;
    final hasPrize =
        rank != null && rank >= 1 && rank <= dist.length && dist[rank - 1] > 0;
    // prize_distribution stocke directement les montants par rang.
    final prize = hasPrize ? dist[rank - 1] : null;
    final currency =
        competition.prizePoolCurrency ?? competition.registrationCurrency;
    final initials = entry.username.isNotEmpty
        ? entry.username.substring(0, 1).toUpperCase()
        : '?';

    return InkWell(
      // Phase 13 — tap → /profile/u/<username> (profil public du joueur).
      onTap: entry.username.isEmpty
          ? null
          : () => context.push(UserRoutes.publicProfilePath(entry.username)),
      borderRadius: BorderRadius.circular(ArenaRadius.lg),
      child: Container(
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
                        ? l10n.compDetailRankingUnranked
                        : '${prizeRankLabel(rank - 1)}'
                            '${l10n.compDetailRankingPlaceSuffix}',
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

String _gameEmoji(GameType g) => switch (g) {
      GameType.efootball => '⚽',
      GameType.fifaMobile => '🏆',
      GameType.eaSportsFc => '🎮',
    };

String _formatLabel(TournamentFormat f) => switch (f) {
      TournamentFormat.singleElimination => 'Élimination directe',
      TournamentFormat.groupsThenKnockout => 'Poules + élimination',
      TournamentFormat.roundRobin => 'Round robin',
    };
