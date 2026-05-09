import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_avatar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// PHASE 11 · A6 — admin home / KPI dashboard.
///
/// Three sections: KPI grid (active comps / matches / disputes / pending
/// payouts), alert cards (urgent disputes + payouts > 24h) and quick
/// actions + recent activity feed. Backend wires to the
/// `admin_kpis` view in PHASE 11.
///
/// Maps to screen A6 of `arena_v2.html`.
class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ArenaAppBar(
        title: 'Dashboard',
        showBack: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(ArenaSpacing.lg),
          children: [
            Text('KPIs LIVE', style: ArenaText.inputLabel),
            const SizedBox(height: ArenaSpacing.sm),
            const _KpiGrid().animate().fadeIn(
                  duration: ArenaDurations.medium,
                ),
            const SizedBox(height: ArenaSpacing.md),
            const _PayoutsKpi().animate(delay: 100.ms).fadeIn(
                  duration: ArenaDurations.medium,
                ),
            const SizedBox(height: ArenaSpacing.lg),
            Text('🚨 Alertes', style: ArenaText.h3),
            const SizedBox(height: ArenaSpacing.sm),
            _AlertCard(
              decoration: arenaDangerCardDecoration(),
              icon: '⚠',
              title: '3 disputes urgentes (>10 min)',
              subtitle: 'M-4287, M-4289, M-4291',
              accent: ArenaColors.neonRed,
            ).animate(delay: 200.ms).fadeIn(duration: ArenaDurations.medium),
            const SizedBox(height: ArenaSpacing.sm),
            _AlertCard(
              decoration: arenaWarningCardDecoration(),
              icon: '⏱',
              title: 'Payouts en attente > 24h',
              subtitle: '5 joueurs concernés',
              accent: ArenaColors.statusWarn,
            ).animate(delay: 250.ms).fadeIn(duration: ArenaDurations.medium),
            const SizedBox(height: ArenaSpacing.lg),
            Text('⚡ Quick actions', style: ArenaText.h3),
            const SizedBox(height: ArenaSpacing.sm),
            ArenaButton(
              label: '+ NOUVELLE COMPÉTITION',
              fullWidth: true,
              onPressed: () {},
            ),
            const SizedBox(height: ArenaSpacing.xs),
            ArenaButton(
              label: '⚖ VOIR LES DISPUTES',
              fullWidth: true,
              variant: ArenaButtonVariant.secondary,
              onPressed: () {},
            ),
            const SizedBox(height: ArenaSpacing.xs),
            ArenaButton(
              label: '💰 VALIDER PAYOUTS',
              fullWidth: true,
              variant: ArenaButtonVariant.secondary,
              onPressed: () {},
            ),
            const SizedBox(height: ArenaSpacing.lg),
            Text('📜 Activité récente', style: ArenaText.h3),
            const SizedBox(height: ArenaSpacing.sm),
            const _ActivityRow(
              initials: 'M1',
              color: ArenaAvatarColor.cyan,
              title: 'Modérateur1 a validé un payout',
              meta: 'il y a 5 min · 25 000 XAF',
            ),
            const SizedBox(height: ArenaSpacing.xs),
            const _ActivityRow(
              initials: 'AP',
              color: ArenaAvatarColor.orange,
              title: 'Admin a tranché dispute M-4282',
              meta: 'il y a 12 min · score 3-1 validé',
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _KpiTile(
            value: '42',
            label: 'Compét. actives',
            border: ArenaColors.signalBlue,
          ),
        ),
        const SizedBox(width: ArenaSpacing.sm),
        Expanded(
          child: _KpiTile(
            value: '187',
            label: 'Matchs en cours',
            border: ArenaColors.statusWarn,
            valueColor: ArenaColors.statusWarn,
          ),
        ),
        const SizedBox(width: ArenaSpacing.sm),
        Expanded(
          child: _KpiTile(
            value: '7',
            label: 'Disputes',
            border: ArenaColors.neonRed,
            valueColor: ArenaColors.neonRed,
          ),
        ),
      ],
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.value,
    required this.label,
    required this.border,
    this.valueColor,
  });

  final String value;
  final String label;
  final Color border;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ArenaSpacing.sm,
        vertical: ArenaSpacing.md,
      ),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: ArenaText.bigNumber.copyWith(
              color: valueColor ?? ArenaColors.bone,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: ArenaText.bodyMuted,
          ),
        ],
      ),
    );
  }
}

class _PayoutsKpi extends StatelessWidget {
  const _PayoutsKpi();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.lg),
      decoration: BoxDecoration(
        color: ArenaColors.neonRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(color: ArenaColors.neonRed),
      ),
      child: Row(
        children: [
          Text(
            '12',
            style: ArenaText.bigNumber.copyWith(
              color: ArenaColors.neonRed,
              fontSize: 24,
            ),
          ),
          const SizedBox(width: ArenaSpacing.md),
          Expanded(
            child: Text(
              'Payouts en attente · 145 000 XAF',
              style: ArenaText.body,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.decoration,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  final BoxDecoration decoration;
  final String icon;
  final String title;
  final String subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: decoration,
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: ArenaSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: ArenaText.body.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: ArenaText.bodyMuted),
              ],
            ),
          ),
          Text('›', style: ArenaText.h2.copyWith(color: accent)),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.initials,
    required this.color,
    required this.title,
    required this.meta,
  });

  final String initials;
  final ArenaAvatarColor color;
  final String title;
  final String meta;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.sm),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(color: ArenaColors.border),
      ),
      child: Row(
        children: [
          ArenaAvatar(
            initials: initials,
            color: color,
            size: ArenaAvatarSize.sm,
          ),
          const SizedBox(width: ArenaSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: ArenaText.body),
                const SizedBox(height: 2),
                Text(meta, style: ArenaText.bodyMuted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
