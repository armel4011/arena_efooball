import 'package:arena/core/router/admin_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/competition.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/data/repositories/admin/admin_competitions_repository.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_badge.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// PHASE 11 · A7 — admin competitions list.
///
/// Reads `competitions` via [adminCompetitionsProvider]. Filters are
/// applied client-side (cf. repo doc). Tap a card → detail; the chip
/// counts reflect the filtered subset of the realtime feed.
///
/// Maps to screen A7 of `arena_v2.html`.
class AdminCompetitionsListPage extends ConsumerStatefulWidget {
  const AdminCompetitionsListPage({super.key});

  @override
  ConsumerState<AdminCompetitionsListPage> createState() =>
      _AdminCompetitionsListPageState();
}

class _AdminCompetitionsListPageState
    extends ConsumerState<AdminCompetitionsListPage> {
  CompetitionStatus? _statusFilter;
  GameType? _gameFilter;

  @override
  Widget build(BuildContext context) {
    final filter = AdminCompetitionsFilter(
      status: _statusFilter,
      game: _gameFilter,
    );
    final list = ref.watch(adminCompetitionsProvider(filter));

    return Scaffold(
      appBar: ArenaAppBar(
        title: 'Compétitions',
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add,
              color: ArenaColors.signalBlue,
              size: 22,
            ),
            onPressed: () => context.push(AdminRoutes.competitionsCreate),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(ArenaSpacing.lg),
          children: [
            Text('FILTRES', style: ArenaText.inputLabel),
            const SizedBox(height: ArenaSpacing.sm),
            _StatusChipsRow(
              current: _statusFilter,
              onTap: (s) => setState(() => _statusFilter = s),
            ),
            const SizedBox(height: ArenaSpacing.xs),
            _GameChipsRow(
              current: _gameFilter,
              onTap: (g) => setState(() => _gameFilter = g),
            ),
            const SizedBox(height: ArenaSpacing.md),
            list.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(ArenaSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(ArenaSpacing.md),
                child: Text(
                  'Erreur de chargement : $e',
                  style: ArenaText.bodyMuted,
                ),
              ),
              data: (comps) => comps.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(ArenaSpacing.lg),
                      child: Text(
                        'Aucune compétition pour ce filtre.',
                        style: ArenaText.bodyMuted,
                        textAlign: TextAlign.center,
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final c in comps) ...[
                          _CompCard(competition: c),
                          const SizedBox(height: ArenaSpacing.sm),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChipsRow extends StatelessWidget {
  const _StatusChipsRow({required this.current, required this.onTap});
  final CompetitionStatus? current;
  final ValueChanged<CompetitionStatus?> onTap;

  static const _items = <(CompetitionStatus?, String)>[
    (null, 'Toutes'),
    (CompetitionStatus.ongoing, 'Live'),
    (CompetitionStatus.registrationOpen, 'À venir'),
    (CompetitionStatus.draft, 'Draft'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (status, label) in _items)
            Padding(
              padding: const EdgeInsets.only(right: ArenaSpacing.xs),
              child: _Chip(
                label: label,
                active: status == current,
                onTap: () => onTap(status),
              ),
            ),
        ],
      ),
    );
  }
}

class _GameChipsRow extends StatelessWidget {
  const _GameChipsRow({required this.current, required this.onTap});
  final GameType? current;
  final ValueChanged<GameType?> onTap;

  static const _items = <(GameType?, String)>[
    (null, 'Tous'),
    (GameType.efootball, 'eFoot'),
    (GameType.fifaMobile, 'FIFA'),
    (GameType.eaSportsFc, 'FC Mobile'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (game, label) in _items)
            Padding(
              padding: const EdgeInsets.only(right: ArenaSpacing.xs),
              child: _Chip(
                label: label,
                active: game == current,
                onTap: () => onTap(game),
              ),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ArenaRadius.round),
      child: AnimatedContainer(
        duration: ArenaDurations.short,
        padding: const EdgeInsets.symmetric(
          horizontal: ArenaSpacing.md,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: active
              ? ArenaColors.signalBlue.withValues(alpha: 0.15)
              : ArenaColors.carbon,
          borderRadius: BorderRadius.circular(ArenaRadius.round),
          border: Border.all(
            color: active ? ArenaColors.signalBlue : ArenaColors.border,
          ),
        ),
        child: Text(
          label,
          style: ArenaText.body.copyWith(
            color: active ? ArenaColors.signalBlue : ArenaColors.silver,
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _CompCard extends ConsumerWidget {
  const _CompCard({required this.competition});
  final Competition competition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visual = _visualFor(competition.status);
    final kvs = _kvsFor(competition);
    final showActions = competition.status == CompetitionStatus.ongoing ||
        competition.status == CompetitionStatus.registrationOpen;
    final isSuperAdmin = ref.watch(currentProfileProvider).maybeWhen(
          data: (p) => p?.isSuperAdmin ?? false,
          orElse: () => false,
        );
    final footerNote = competition.status == CompetitionStatus.draft
        ? 'Brouillon, pas publié'
        : null;

    return InkWell(
      onTap: () => context.push(AdminRoutes.competitionDetailPath(competition.id)),
      borderRadius: BorderRadius.circular(ArenaRadius.lg),
      child: Container(
        decoration: BoxDecoration(
          color: ArenaColors.carbon,
          borderRadius: BorderRadius.circular(ArenaRadius.lg),
          border: Border.all(color: ArenaColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Accent strip on the left, tinted by the comp status.
              Container(width: 3, color: visual.color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(ArenaSpacing.md),
                  child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ArenaBadge(label: visual.label, variant: visual.variant),
                const Spacer(),
                Text(
                  '#${competition.id.substring(0, 6).toUpperCase()}',
                  style: ArenaText.monoSmall,
                ),
              ],
            ),
            const SizedBox(height: ArenaSpacing.sm),
            Text(competition.name.toUpperCase(), style: ArenaText.h3),
            if (kvs.isNotEmpty) const SizedBox(height: ArenaSpacing.sm),
            for (final (k, v) in kvs)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(k, style: ArenaText.bodyMuted)),
                    Text(v, style: ArenaText.body),
                  ],
                ),
              ),
            if (footerNote != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(footerNote, style: ArenaText.bodyMuted),
              ),
            if (showActions) ...[
              const SizedBox(height: ArenaSpacing.sm),
              ArenaButton(
                label: 'VOIR',
                variant: ArenaButtonVariant.secondary,
                fullWidth: true,
                onPressed: () => context.push(
                  AdminRoutes.competitionDetailPath(competition.id),
                ),
              ),
              const SizedBox(height: ArenaSpacing.xs),
              ArenaButton(
                label: 'BRACKET',
                variant: ArenaButtonVariant.secondary,
                fullWidth: true,
                onPressed: () => context.push(
                  AdminRoutes.bracketPath(competition.id),
                ),
              ),
              const SizedBox(height: ArenaSpacing.xs),
              ArenaButton(
                label: 'ANNULER',
                variant: ArenaButtonVariant.danger,
                fullWidth: true,
                onPressed: () => _confirmCancel(context, ref),
              ),
            ],
            if (isSuperAdmin) ...[
              const SizedBox(height: ArenaSpacing.xs),
              ArenaButton(
                label: '🗑 SUPPRIMER',
                variant: ArenaButtonVariant.danger,
                fullWidth: true,
                onPressed: () => _confirmDelete(context, ref),
              ),
            ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
        ),
    );
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: ArenaColors.carbon,
        title: Text('Annuler la compétition ?', style: ArenaText.h3),
        content: Text(
          'L\'opération est irréversible côté joueurs : la compétition '
          'passe en cancelled. Les remboursements seront déclenchés en '
          'PHASE 11bis.',
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
            child: const Text('OUI, ANNULER'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref
          .read(adminCompetitionsRepositoryProvider)
          .cancel(competition.id);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec : $e')),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: ArenaColors.carbon,
        title: Text(
          'Supprimer définitivement ?',
          style: ArenaText.h3.copyWith(color: ArenaColors.neonRed),
        ),
        content: Text(
          'Cette compétition et tous ses paiements liés seront effacés '
          'de la DB. Les inscriptions et matches cascadent automatiquement. '
          'Cette action est IRRÉVERSIBLE.',
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
            child: const Text('OUI, SUPPRIMER'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref
          .read(adminCompetitionsRepositoryProvider)
          .delete(competition.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compétition supprimée.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec : $e')),
      );
    }
  }
}

class _StatusVisual {
  const _StatusVisual({
    required this.label,
    required this.color,
    required this.variant,
  });
  final String label;
  final Color color;
  final ArenaBadgeVariant variant;
}

_StatusVisual _visualFor(CompetitionStatus status) {
  switch (status) {
    case CompetitionStatus.ongoing:
      return const _StatusVisual(
        label: 'LIVE',
        color: ArenaColors.neonRed,
        variant: ArenaBadgeVariant.live,
      );
    case CompetitionStatus.registrationOpen:
      return const _StatusVisual(
        label: 'À VENIR',
        color: ArenaColors.signalBlue,
        variant: ArenaBadgeVariant.info,
      );
    case CompetitionStatus.registrationClosed:
      return const _StatusVisual(
        label: 'COMPLET',
        color: ArenaColors.statusWarn,
        variant: ArenaBadgeVariant.warn,
      );
    case CompetitionStatus.draft:
      return const _StatusVisual(
        label: 'DRAFT',
        color: ArenaColors.statusWarn,
        variant: ArenaBadgeVariant.warn,
      );
    case CompetitionStatus.completed:
      return const _StatusVisual(
        label: 'TERMINÉ',
        color: ArenaColors.silver,
        variant: ArenaBadgeVariant.neutral,
      );
    case CompetitionStatus.cancelled:
      return const _StatusVisual(
        label: 'ANNULÉ',
        color: ArenaColors.neonRed,
        variant: ArenaBadgeVariant.danger,
      );
  }
}

List<(String, String)> _kvsFor(Competition c) {
  final fmt = NumberFormat('#,###', 'fr_FR');
  final prize = fmt
      .format(c.prizePoolLocal.round())
      .replaceAll(',', ' ');
  final out = <(String, String)>[
    ('Inscrits', '${c.currentPlayers}/${c.maxPlayers}'),
  ];
  if (c.prizePoolLocal > 0) {
    out.add(('Récompense', '$prize ${c.prizePoolCurrency ?? c.registrationCurrency}'));
  }
  if (c.status == CompetitionStatus.registrationOpen ||
      c.status == CompetitionStatus.draft) {
    out.add(('Démarre', DateFormat('dd/MM HH\'h\'').format(c.startDate)));
  }
  return out;
}
