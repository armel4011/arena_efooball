import 'package:arena/core/router/admin_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/models/competition.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/data/models/user_role.dart';
import 'package:arena/data/repositories/admin/admin_competitions_repository.dart';
import 'package:arena/data/repositories/competition_repository.dart';
import 'package:arena/data/repositories/match_repository.dart';
import 'package:arena/features_shared/prize_ranks.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_avatar.dart';
import 'package:arena/features_shared/widgets/arena_badge.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// PHASE 11 · A9 — admin competition detail with 6 tabs.
///
/// Reads the competition via the existing user-facing
/// [competitionByIdProvider] (it's already realtime and public) and
/// the matches via [competitionMatchesProvider]. Admin actions on the
/// Bracket tab : navigate to bracket management, force start, cancel.
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
        appBar: const ArenaAppBar(title: 'Compétition'),
        body: SafeArea(
          child: compAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
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
                  _Header(competition: comp),
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
                        _InfosTab(competition: comp),
                        _RegistrantsTab(competitionId: comp.id),
                        _MatchesTab(competitionId: comp.id),
                        _RankingTab(competitionId: comp.id),
                        _ActionsTab(competition: comp),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.competition});
  final Competition competition;

  @override
  Widget build(BuildContext context) {
    final gradient = _gradientFor(competition.game);
    final fmt = NumberFormat('#,###', 'fr_FR');
    final pool = fmt
        .format(competition.prizePoolLocal.round())
        .replaceAll(',', ' ');

    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(gradient: gradient),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ArenaBadge(
                label: _statusLabel(competition.status),
                variant: _statusBadgeVariant(competition.status),
              ),
              const Spacer(),
              Text(
                '#${competition.id.substring(0, 8).toUpperCase()}',
                style: ArenaText.monoSmall
                    .copyWith(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: ArenaSpacing.xs),
          Text(
            competition.name.toUpperCase(),
            style: ArenaText.h2.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 2),
          Text(
            '${competition.currentPlayers}/${competition.maxPlayers} inscrits'
            '${competition.prizePoolLocal > 0 ? " · Cagnotte $pool ${competition.prizePoolCurrency ?? competition.registrationCurrency}" : ""}',
            style: ArenaText.bodyMuted.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  static String _statusLabel(CompetitionStatus s) {
    switch (s) {
      case CompetitionStatus.ongoing:
        return 'LIVE';
      case CompetitionStatus.registrationOpen:
        return 'INSCRIPTIONS';
      case CompetitionStatus.registrationClosed:
        return 'COMPLET';
      case CompetitionStatus.draft:
        return 'DRAFT';
      case CompetitionStatus.completed:
        return 'TERMINÉ';
      case CompetitionStatus.cancelled:
        return 'ANNULÉ';
    }
  }

  static ArenaBadgeVariant _statusBadgeVariant(CompetitionStatus s) {
    switch (s) {
      case CompetitionStatus.ongoing:
        return ArenaBadgeVariant.live;
      case CompetitionStatus.registrationOpen:
        return ArenaBadgeVariant.info;
      case CompetitionStatus.completed:
        return ArenaBadgeVariant.success;
      case CompetitionStatus.cancelled:
        return ArenaBadgeVariant.danger;
      case CompetitionStatus.draft:
      case CompetitionStatus.registrationClosed:
        return ArenaBadgeVariant.warn;
    }
  }

  static LinearGradient _gradientFor(GameType g) {
    switch (g) {
      case GameType.fifaMobile:
        return ArenaColors.bannerFifa;
      case GameType.eaSportsFc:
        return ArenaColors.bannerFc;
      case GameType.efootball:
        return ArenaColors.bannerEfoot;
    }
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
        _InfoRow(label: 'Jeu', value: competition.game.label),
        _InfoRow(label: 'Format', value: _formatLabel(competition.format)),
        _InfoRow(
          label: 'Joueurs',
          value: '${competition.currentPlayers}/${competition.maxPlayers}',
        ),
        _InfoRow(
          label: 'Début',
          value: DateFormat('dd/MM/yyyy HH:mm').format(competition.startDate),
        ),
        if (competition.registrationFee > 0)
          _InfoRow(
            label: 'Inscription',
            value: '${competition.registrationFee} '
                '${competition.registrationCurrency}',
          ),
        _InfoRow(
          label: 'Commission',
          value: '${competition.commissionPct.round()}%',
        ),
        if (competition.description != null) ...[
          const SizedBox(height: ArenaSpacing.md),
          Text('Description', style: ArenaText.inputLabel),
          const SizedBox(height: ArenaSpacing.xs),
          Text(competition.description!, style: ArenaText.body),
        ],
      ],
    );
  }

  static String _formatLabel(TournamentFormat f) {
    switch (f) {
      case TournamentFormat.singleElimination:
        return 'Élimination directe';
      case TournamentFormat.groupsThenKnockout:
        return 'Poules + KO';
      case TournamentFormat.roundRobin:
        return 'Round robin';
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: ArenaText.bodyMuted)),
          Text(value, style: ArenaText.body),
        ],
      ),
    );
  }
}

class _MatchesTab extends ConsumerWidget {
  const _MatchesTab({required this.competitionId});
  final String competitionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync =
        ref.watch(competitionMatchesProvider(competitionId));

    return matchesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          Padding(
        padding: const EdgeInsets.all(ArenaSpacing.lg),
        child: Text('Erreur : $e', style: ArenaText.bodyMuted),
      ),
      data: (matches) => matches.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(ArenaSpacing.lg),
              child: Text(
                'Aucun match — génère le bracket.',
                style: ArenaText.bodyMuted,
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(ArenaSpacing.lg),
              itemCount: matches.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: ArenaSpacing.sm),
              itemBuilder: (_, i) => _MatchRow(match: matches[i]),
            ),
    );
  }
}

class _MatchRow extends StatelessWidget {
  const _MatchRow({required this.match});
  final ArenaMatch match;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(color: ArenaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Round ${match.round ?? "—"} · M${match.matchNumber ?? "?"}',
                style: ArenaText.bodyMuted,
              ),
              const Spacer(),
              Text(
                'M-${match.id.substring(0, 6)}',
                style: ArenaText.monoSmall,
              ),
            ],
          ),
          const SizedBox(height: ArenaSpacing.sm),
          _PlayerRow(
            playerId: match.player1Id,
            score: match.score1,
            color: ArenaAvatarColor.blue,
          ),
          const SizedBox(height: 4),
          _PlayerRow(
            playerId: match.player2Id,
            score: match.score2,
            color: ArenaAvatarColor.green,
          ),
        ],
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    required this.playerId,
    required this.score,
    required this.color,
  });
  final String? playerId;
  final int? score;
  final ArenaAvatarColor color;

  @override
  Widget build(BuildContext context) {
    final label =
        playerId == null ? 'TBD' : playerId!.substring(0, 8);
    return Row(
      children: [
        ArenaAvatar(
          initials: label[0],
          color: color,
          size: ArenaAvatarSize.sm,
        ),
        const SizedBox(width: ArenaSpacing.sm),
        Expanded(child: Text(label, style: ArenaText.body)),
        Text(
          score?.toString() ?? '—',
          style: ArenaText.bigNumber.copyWith(fontSize: 18),
        ),
      ],
    );
  }
}

class _ActionsTab extends ConsumerWidget {
  const _ActionsTab({required this.competition});
  final Competition competition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(ArenaSpacing.lg),
      children: [
        Text(
          '⚡ ACTIONS ADMIN',
          style: ArenaText.inputLabel.copyWith(color: ArenaColors.neonRed),
        ),
        const SizedBox(height: ArenaSpacing.sm),
        ArenaButton(
          label: '✏️ MODIFIER LA COMPÉTITION',
          variant: ArenaButtonVariant.secondary,
          fullWidth: true,
          onPressed: () => context.push(
            AdminRoutes.competitionEditPath(competition.id),
            extra: competition,
          ),
        ),
        const SizedBox(height: ArenaSpacing.xs),
        ArenaButton(
          label: '🏆 GÉRER LE BRACKET',
          fullWidth: true,
          onPressed: () => context.push(
            AdminRoutes.bracketPath(competition.id),
          ),
        ),
        const SizedBox(height: ArenaSpacing.xs),
        if (competition.status == CompetitionStatus.draft ||
            competition.status == CompetitionStatus.registrationOpen)
          ArenaButton(
            label: '▶ OUVRIR LES INSCRIPTIONS',
            variant: ArenaButtonVariant.secondary,
            fullWidth: true,
            onPressed: () =>
                _setStatus(context, ref, CompetitionStatus.registrationOpen),
          ),
        if (competition.status == CompetitionStatus.registrationOpen)
          ArenaButton(
            label: '⏸ FERMER LES INSCRIPTIONS',
            variant: ArenaButtonVariant.secondary,
            fullWidth: true,
            onPressed: () => _setStatus(
              context,
              ref,
              CompetitionStatus.registrationClosed,
            ),
          ),
        const SizedBox(height: ArenaSpacing.xs),
        ArenaButton(
          label: '🚫 ANNULER (refund all)',
          variant: ArenaButtonVariant.danger,
          fullWidth: true,
          onPressed: () => _cancel(context, ref),
        ),
      ],
    );
  }

  Future<void> _setStatus(
    BuildContext context,
    WidgetRef ref,
    CompetitionStatus status,
  ) async {
    try {
      await ref.read(adminCompetitionsRepositoryProvider).update(
        competition.id,
        {'status': status.value},
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Statut → ${status.value}.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec : $e')),
      );
    }
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: ArenaColors.carbon,
        title: Text('Annuler la compétition ?', style: ArenaText.h3),
        content: Text(
          'L\'opération est irréversible côté joueurs. Les remboursements '
          'seront déclenchés en PHASE 11bis.',
          style: ArenaText.bodyMuted,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('NON'),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(true),
            style: TextButton.styleFrom(foregroundColor: ArenaColors.neonRed),
            child: const Text('OUI'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref
          .read(adminCompetitionsRepositoryProvider)
          .cancel(competition.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('« ${competition.name} » annulée.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec : $e')),
      );
    }
  }
}

class _RegistrantsTab extends ConsumerWidget {
  const _RegistrantsTab({required this.competitionId});
  final String competitionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminCompetitionRegistrantsProvider(competitionId));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminCompetitionRegistrantsProvider(competitionId));
        await ref.read(
          adminCompetitionRegistrantsProvider(competitionId).future,
        );
      },
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ListView(
          padding: const EdgeInsets.all(ArenaSpacing.lg),
          children: [Text('Erreur : $e', style: ArenaText.bodyMuted)],
        ),
        data: (list) {
          if (list.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(ArenaSpacing.lg),
              children: [
                Text(
                  'Aucun inscrit pour le moment.',
                  style: ArenaText.bodyMuted,
                ),
              ],
            );
          }
          final confirmed =
              list.where((r) => r.status == 'confirmed').length;
          return ListView.separated(
            padding: const EdgeInsets.all(ArenaSpacing.lg),
            itemCount: list.length + 1,
            separatorBuilder: (_, __) =>
                const SizedBox(height: ArenaSpacing.xs),
            itemBuilder: (_, i) {
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: ArenaSpacing.sm),
                  child: Text(
                    '${list.length} inscrit${list.length > 1 ? "s" : ""} · '
                    '$confirmed confirmé${confirmed > 1 ? "s" : ""}',
                    style: ArenaText.inputLabel,
                  ),
                );
              }
              return _RegistrantRow(registrant: list[i - 1]);
            },
          );
        },
      ),
    );
  }
}

class _RegistrantRow extends StatelessWidget {
  const _RegistrantRow({required this.registrant});
  final AdminCompetitionRegistrant registrant;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy HH:mm');
    final initials = registrant.username.isNotEmpty
        ? registrant.username.substring(0, 1).toUpperCase()
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
          ArenaAvatar(
            initials: initials,
            color: _avatarColorFor(registrant.username),
          ),
          const SizedBox(width: ArenaSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        registrant.username,
                        style: ArenaText.body,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (registrant.role == UserRole.admin ||
                        registrant.role == UserRole.superAdmin) ...[
                      const SizedBox(width: 6),
                      ArenaBadge(
                        label: registrant.role == UserRole.superAdmin
                            ? 'SUPER'
                            : 'ADMIN',
                        variant: ArenaBadgeVariant.info,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${registrant.countryCode} · ${fmt.format(registrant.registeredAt.toLocal())}',
                  style: ArenaText.bodyMuted,
                ),
              ],
            ),
          ),
          const SizedBox(width: ArenaSpacing.sm),
          ArenaBadge(
            label: _statusLabel(registrant.status),
            variant: _statusVariant(registrant.status),
          ),
        ],
      ),
    );
  }

  static ArenaAvatarColor _avatarColorFor(String seed) {
    if (seed.isEmpty) return ArenaAvatarColor.blue;
    final i = seed.codeUnitAt(0) % ArenaAvatarColor.values.length;
    return ArenaAvatarColor.values[i];
  }

  static String _statusLabel(String s) {
    switch (s) {
      case 'confirmed':
        return 'PAYÉ';
      case 'pending':
        return 'EN ATTENTE';
      case 'refunded':
        return 'REMBOURSÉ';
      case 'withdrawn':
        return 'RETRAIT';
      default:
        return s.toUpperCase();
    }
  }

  static ArenaBadgeVariant _statusVariant(String s) {
    switch (s) {
      case 'confirmed':
        return ArenaBadgeVariant.success;
      case 'pending':
        return ArenaBadgeVariant.warn;
      case 'refunded':
      case 'withdrawn':
        return ArenaBadgeVariant.danger;
      default:
        return ArenaBadgeVariant.info;
    }
  }
}

/// Onglet CLASSEMENT — l'admin saisit le rang d'arrivée final de chaque
/// participant. Les rangs alimentent l'écran joueur (podium + gains
/// croisés avec `prize_distribution`). Réutilise le provider des
/// inscrits ; le tri par rang se fait côté client.
class _RankingTab extends ConsumerWidget {
  const _RankingTab({required this.competitionId});
  final String competitionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminCompetitionRegistrantsProvider(competitionId));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminCompetitionRegistrantsProvider(competitionId));
        await ref.read(
          adminCompetitionRegistrantsProvider(competitionId).future,
        );
      },
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ListView(
          padding: const EdgeInsets.all(ArenaSpacing.lg),
          children: [Text('Erreur : $e', style: ArenaText.bodyMuted)],
        ),
        data: (list) {
          if (list.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(ArenaSpacing.lg),
              children: [
                Text(
                  'Aucun inscrit — le classement se remplira une fois '
                  'les inscriptions ouvertes.',
                  style: ArenaText.bodyMuted,
                ),
              ],
            );
          }
          final sorted = [...list]..sort((a, b) {
              final ra = a.finalRank ?? 1 << 30;
              final rb = b.finalRank ?? 1 << 30;
              if (ra != rb) return ra.compareTo(rb);
              return a.username
                  .toLowerCase()
                  .compareTo(b.username.toLowerCase());
            });
          final ranked = list.where((r) => r.finalRank != null).length;
          return ListView.separated(
            padding: const EdgeInsets.all(ArenaSpacing.lg),
            itemCount: sorted.length + 1,
            separatorBuilder: (_, __) =>
                const SizedBox(height: ArenaSpacing.xs),
            itemBuilder: (_, i) {
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: ArenaSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ArenaButton(
                        label: '⚡ CLASSEMENT AUTOMATIQUE',
                        variant: ArenaButtonVariant.secondary,
                        fullWidth: true,
                        onPressed: () => _autoRank(context, ref),
                      ),
                      const SizedBox(height: ArenaSpacing.xs),
                      Text(
                        'Critères : niveau atteint dans la compétition, '
                        'puis buts marqués, puis ordre alphabétique. '
                        'Ajustable manuellement ensuite.',
                        style: ArenaText.small,
                      ),
                      const SizedBox(height: ArenaSpacing.sm),
                      Text(
                        '$ranked/${list.length} '
                        'classé${ranked > 1 ? "s" : ""}',
                        style: ArenaText.inputLabel,
                      ),
                    ],
                  ),
                );
              }
              return _RankingRow(
                competitionId: competitionId,
                registrant: sorted[i - 1],
                participantCount: list.length,
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _autoRank(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: ArenaColors.carbon,
        title: Text('Calculer le classement ?', style: ArenaText.h3),
        content: Text(
          'Les rangs seront recalculés à partir des résultats de matchs '
          '(niveau atteint, buts marqués, ordre alphabétique). Cela '
          'écrase les rangs déjà saisis manuellement.',
          style: ArenaText.bodyMuted,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('ANNULER'),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text('CALCULER'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref
          .read(adminCompetitionsRepositoryProvider)
          .autoRankFromResults(competitionId);
      ref.invalidate(adminCompetitionRegistrantsProvider(competitionId));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Classement calculé automatiquement.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec : $e')),
      );
    }
  }
}

class _RankingRow extends ConsumerWidget {
  const _RankingRow({
    required this.competitionId,
    required this.registrant,
    required this.participantCount,
  });

  final String competitionId;
  final AdminCompetitionRegistrant registrant;
  final int participantCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rank = registrant.finalRank;
    final initials = registrant.username.isNotEmpty
        ? registrant.username.substring(0, 1).toUpperCase()
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
            width: 28,
            child: Text(
              rank == null ? '—' : prizeRankEmoji(rank - 1),
              style: ArenaText.body,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: ArenaSpacing.xs),
          ArenaAvatar(
            initials: initials,
            color: _RegistrantRow._avatarColorFor(registrant.username),
            size: ArenaAvatarSize.sm,
          ),
          const SizedBox(width: ArenaSpacing.sm),
          Expanded(
            child: Text(
              registrant.username,
              style: ArenaText.body,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: ArenaSpacing.sm),
          DropdownButton<int?>(
            value: rank,
            hint: Text('Rang', style: ArenaText.bodyMuted),
            dropdownColor: ArenaColors.carbon,
            underline: const SizedBox.shrink(),
            style: ArenaText.body,
            items: [
              DropdownMenuItem<int?>(
                child: Text('—', style: ArenaText.bodyMuted),
              ),
              for (var n = 1; n <= participantCount; n++)
                DropdownMenuItem<int?>(
                  value: n,
                  child: Text('Rang $n', style: ArenaText.body),
                ),
            ],
            onChanged: (value) => _setRank(context, ref, value),
          ),
        ],
      ),
    );
  }

  Future<void> _setRank(
    BuildContext context,
    WidgetRef ref,
    int? rank,
  ) async {
    try {
      await ref
          .read(adminCompetitionsRepositoryProvider)
          .setFinalRank(competitionId, registrant.playerId, rank);
      ref.invalidate(adminCompetitionRegistrantsProvider(competitionId));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            rank == null
                ? 'Rang effacé pour ${registrant.username}.'
                : '${registrant.username} → rang $rank.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec : $e')),
      );
    }
  }
}
