import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_badge.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// PHASE 11 · A7 — admin competitions list.
///
/// Two filter chip rows (status + game) above status-coloured cards
/// listing compétitions with admin CTAs (voir / modifier / annuler).
///
/// Maps to screen A7 of `arena_v2.html`.
class AdminCompetitionsListPage extends StatefulWidget {
  const AdminCompetitionsListPage({super.key});

  @override
  State<AdminCompetitionsListPage> createState() =>
      _AdminCompetitionsListPageState();
}

class _AdminCompetitionsListPageState
    extends State<AdminCompetitionsListPage> {
  String _statusFilter = 'Toutes (47)';
  String _gameFilter = 'Tous';

  static const _statuses = [
    'Toutes (47)',
    'Live (12)',
    'À venir (8)',
    'Draft (3)',
  ];
  static const _games = ['Tous', 'eFoot', 'FIFA', 'FC Mobile'];

  @override
  Widget build(BuildContext context) {
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
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(ArenaSpacing.lg),
          children: [
            Text('FILTRES', style: ArenaText.inputLabel),
            const SizedBox(height: ArenaSpacing.sm),
            _ChipsRow(
              labels: _statuses,
              current: _statusFilter,
              onTap: (l) => setState(() => _statusFilter = l),
            ),
            const SizedBox(height: ArenaSpacing.xs),
            _ChipsRow(
              labels: _games,
              current: _gameFilter,
              onTap: (l) => setState(() => _gameFilter = l),
            ),
            const SizedBox(height: ArenaSpacing.md),
            const _CompCard(
              borderColor: ArenaColors.neonRed,
              badgeLabel: 'LIVE',
              badgeVariant: ArenaBadgeVariant.live,
              compRef: '#C-2284',
              title: 'FIFA WEEKEND CUP',
              kvs: [
                ('Inscrits', '12/16'),
                ('Récompense', '60 000 XAF'),
                ('Phase', 'Quarts'),
              ],
              showActions: true,
            ),
            SizedBox(height: ArenaSpacing.sm),
            _CompCard(
              borderColor: ArenaColors.signalBlue,
              badgeLabel: 'À VENIR',
              badgeVariant: ArenaBadgeVariant.info,
              compRef: '#C-2285',
              title: 'EA FC NIGHT BATTLE',
              kvs: [
                ('Inscrits', '8/32'),
                ('Démarre', '14/05 20h'),
                ('Créateur', '@admin'),
              ],
            ),
            SizedBox(height: ArenaSpacing.sm),
            _CompCard(
              borderColor: ArenaColors.statusWarn,
              badgeLabel: 'DRAFT',
              badgeVariant: ArenaBadgeVariant.warn,
              compRef: '#C-2286',
              title: 'eFOOT MASTERS RAMADAN',
              kvs: [],
              footerNote: 'Brouillon, pas publié',
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipsRow extends StatelessWidget {
  const _ChipsRow({
    required this.labels,
    required this.current,
    required this.onTap,
  });

  final List<String> labels;
  final String current;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final l in labels)
            Padding(
              padding: const EdgeInsets.only(right: ArenaSpacing.xs),
              child: _Chip(
                label: l,
                active: l == current,
                onTap: () => onTap(l),
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

class _CompCard extends StatelessWidget {
  const _CompCard({
    required this.borderColor,
    required this.badgeLabel,
    required this.badgeVariant,
    required this.compRef,
    required this.title,
    required this.kvs,
    this.showActions = false,
    this.footerNote,
  });

  final Color borderColor;
  final String badgeLabel;
  final ArenaBadgeVariant badgeVariant;
  final String compRef;
  final String title;
  final List<(String, String)> kvs;
  final bool showActions;
  final String? footerNote;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border(
          top: const BorderSide(color: ArenaColors.border),
          right: const BorderSide(color: ArenaColors.border),
          bottom: const BorderSide(color: ArenaColors.border),
          left: BorderSide(color: borderColor, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ArenaBadge(label: badgeLabel, variant: badgeVariant),
              const Spacer(),
              Text(compRef, style: ArenaText.monoSmall),
            ],
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Text(title, style: ArenaText.h3),
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
              child: Text(footerNote!, style: ArenaText.bodyMuted),
            ),
          if (showActions) ...[
            const SizedBox(height: ArenaSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: ArenaButton(
                    label: 'VOIR',
                    variant: ArenaButtonVariant.secondary,
                    fullWidth: true,
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: ArenaButton(
                    label: 'MODIFIER',
                    variant: ArenaButtonVariant.secondary,
                    fullWidth: true,
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: ArenaButton(
                    label: '⏸ ANNULER',
                    variant: ArenaButtonVariant.danger,
                    fullWidth: true,
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: ArenaDurations.medium);
  }
}
