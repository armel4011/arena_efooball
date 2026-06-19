part of 'competition_detail_page.dart';

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
                _ParticipantsTab(competition: competition),
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
          value: _formatLabel(c.format, l10n),
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

/// Onglet PARTICIPANTS — liste des joueurs inscrits, joints à leur profil
/// public (confirmés en tête). Tap → profil public du joueur. Lecture
/// seule, invalidation au pull-to-refresh (même posture que le classement).
class _ParticipantsTab extends ConsumerWidget {
  const _ParticipantsTab({required this.competition});

  final Competition competition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(competitionParticipantsProvider(competition.id));

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorState(
        description: e.toString(),
        onRetry: () =>
            ref.invalidate(competitionParticipantsProvider(competition.id)),
      ),
      data: (participants) {
        if (participants.isEmpty) {
          return EmptyState(
            icon: Icons.people_outline,
            title: l10n.compDetailParticipantsTitle,
            description: l10n.compDetailParticipantsDesc,
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(competitionParticipantsProvider(competition.id));
            await ref
                .read(competitionParticipantsProvider(competition.id).future);
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(ArenaSpacing.lg),
            itemCount: participants.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: ArenaSpacing.xs),
            itemBuilder: (_, i) =>
                _ParticipantRow(participant: participants[i]),
          ),
        );
      },
    );
  }
}

class _ParticipantRow extends StatelessWidget {
  const _ParticipantRow({required this.participant});

  final CompetitionParticipant participant;

  @override
  Widget build(BuildContext context) {
    final name = participant.username;
    final hasProfile = name.isNotEmpty && name != '—';
    final initials = hasProfile ? name.substring(0, 1).toUpperCase() : '?';

    return InkWell(
      // Phase 13 — tap → profil public du joueur.
      onTap: hasProfile
          ? () => context.push(UserRoutes.publicProfilePath(name))
          : null,
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
            ArenaAvatar(
              initials: initials,
              color: _avatarColorForSeed(name),
              size: ArenaAvatarSize.sm,
              imageUrl: participant.avatarUrl,
            ),
            const SizedBox(width: ArenaSpacing.sm),
            Expanded(
              child: Text(
                name,
                style: ArenaText.body,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Inscription non encore confirmée (paiement/validation en attente).
            if (!participant.isConfirmed)
              const Icon(
                Icons.schedule,
                size: 16,
                color: ArenaColors.silver,
              ),
          ],
        ),
      ),
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
        // Top 3 → podium ; le reste (rangs 4+ et non classés) → liste.
        final ranked =
            entries.where((e) => e.finalRank != null).toList(growable: false);
        final podium = ranked.take(3).toList(growable: false);
        final rest = [
          ...ranked.skip(3),
          ...entries.where((e) => e.finalRank == null),
        ];
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(competitionRankingProvider(competition.id));
            await ref.read(competitionRankingProvider(competition.id).future);
          },
          child: ListView(
            padding: const EdgeInsets.all(ArenaSpacing.lg),
            children: [
              _RankingPodium(places: podium, competition: competition),
              if (rest.isNotEmpty) const SizedBox(height: ArenaSpacing.lg),
              for (final e in rest) ...[
                _RankingEntryRow(entry: e, competition: competition),
                const SizedBox(height: ArenaSpacing.xs),
              ],
            ],
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
              imageUrl: entry.avatarUrl,
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

/// Podium top-3 du classement final : 2ᵉ à gauche, 1ᵉʳ surélevé au centre,
/// 3ᵉ à droite. En tête de l'onglet Classement d'une compétition terminée.
class _RankingPodium extends StatelessWidget {
  const _RankingPodium({required this.places, required this.competition});

  /// Triés par `finalRank` croissant (1, 2, 3), au plus 3 entrées.
  final List<CompetitionRankingEntry> places;
  final Competition competition;

  @override
  Widget build(BuildContext context) {
    final first = places.isNotEmpty ? places[0] : null;
    final second = places.length > 1 ? places[1] : null;
    final third = places.length > 2 ? places[2] : null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: second == null
              ? const SizedBox.shrink()
              : _PodiumPlace(
                  entry: second,
                  blockHeight: 54,
                  competition: competition,
                ),
        ),
        const SizedBox(width: ArenaSpacing.xs),
        Expanded(
          child: first == null
              ? const SizedBox.shrink()
              : _PodiumPlace(
                  entry: first,
                  blockHeight: 84,
                  competition: competition,
                ),
        ),
        const SizedBox(width: ArenaSpacing.xs),
        Expanded(
          child: third == null
              ? const SizedBox.shrink()
              : _PodiumPlace(
                  entry: third,
                  blockHeight: 38,
                  competition: competition,
                ),
        ),
      ],
    );
  }
}

class _PodiumPlace extends StatelessWidget {
  const _PodiumPlace({
    required this.entry,
    required this.blockHeight,
    required this.competition,
  });

  final CompetitionRankingEntry entry;
  final double blockHeight;
  final Competition competition;

  @override
  Widget build(BuildContext context) {
    final rank = entry.finalRank ?? 0;
    final dist = competition.prizeDistribution;
    final hasPrize =
        rank >= 1 && rank <= dist.length && dist[rank - 1] > 0;
    final prize = hasPrize ? dist[rank - 1] : null;
    final currency =
        competition.prizePoolCurrency ?? competition.registrationCurrency;
    final medal = switch (rank) {
      1 => ArenaColors.gold,
      2 => ArenaColors.silver,
      _ => ArenaColors.tierBronze,
    };
    final initials = entry.username.isNotEmpty
        ? entry.username.substring(0, 1).toUpperCase()
        : '?';

    return InkWell(
      onTap: entry.username.isEmpty
          ? null
          : () => context.push(UserRoutes.publicProfilePath(entry.username)),
      borderRadius: BorderRadius.circular(ArenaRadius.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            prizeRankEmoji(rank - 1),
            style: const TextStyle(fontSize: 26),
          ),
          const SizedBox(height: 4),
          ArenaAvatar(
            initials: initials,
            color: _avatarColorForSeed(entry.username),
            size: rank == 1 ? ArenaAvatarSize.lg : ArenaAvatarSize.md,
            imageUrl: entry.avatarUrl,
          ),
          const SizedBox(height: ArenaSpacing.xs),
          Text(
            entry.username,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: ArenaText.bodyMuted,
          ),
          if (prize != null)
            Text(
              '${_formatMoney(prize)} $currency',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ArenaText.monoSmall.copyWith(color: ArenaColors.statusOk),
            ),
          const SizedBox(height: ArenaSpacing.xs),
          Container(
            height: blockHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              color: medal.withValues(alpha: 0.18),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(ArenaRadius.sm)),
              border: Border.all(color: medal.withValues(alpha: 0.5)),
            ),
            alignment: Alignment.center,
            child: Text('$rank', style: ArenaText.h2.copyWith(color: medal)),
          ),
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

String _gameEmoji(GameType g) => switch (g) {
      GameType.efootball => '⚽',
      GameType.draughts => '🔴',
      GameType.eaSportsFc => '🎮',
    };

String _formatLabel(TournamentFormat f, AppLocalizations l10n) => switch (f) {
      TournamentFormat.singleElimination => l10n.compDetailFormatSingleElim,
      TournamentFormat.groupsThenKnockout => l10n.compDetailFormatGroupsKnockout,
      TournamentFormat.roundRobin => l10n.compDetailFormatRoundRobin,
    };
