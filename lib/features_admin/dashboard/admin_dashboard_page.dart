import 'package:arena/core/router/admin_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/admin_audit_log.dart';
import 'package:arena/data/repositories/admin/admin_audit_log_repository.dart';
import 'package:arena/data/repositories/admin/admin_kpis_repository.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_avatar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// PHASE 11 · A6 — admin home / KPI dashboard.
///
/// KPIs come from [adminKpisProvider] (live counts of competitions /
/// matches / disputes / pending payouts). The activity feed reads the
/// last 5 admin actions from `admin_audit_log`. Quick actions route
/// to the relevant section. The two alert cards stay heuristic for
/// now — a proper "stale dispute" / "old payout" gating belongs in
/// a future ranking query.
///
/// Maps to screen A6 of `arena_v2.html`.
class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpis = ref.watch(adminKpisProvider);
    final recent = ref.watch(
      adminAuditLogProvider(const AdminAuditLogFilter(periodDays: 7)),
    );
    final isSuperAdmin = ref.watch(currentProfileProvider).maybeWhen(
          data: (p) => p?.isSuperAdmin ?? false,
          orElse: () => false,
        );

    return Scaffold(
      appBar: ArenaAppBar(
        title: '🛡 CONTROL',
        showBack: false,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.account_circle_outlined,
              color: ArenaColors.bone,
              size: 22,
            ),
            tooltip: 'Mon profil',
            onPressed: () => context.push(AdminRoutes.profile),
          ),
          IconButton(
            icon: const Icon(
              Icons.logout,
              color: ArenaColors.bone,
              size: 20,
            ),
            tooltip: 'Déconnexion',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: ArenaColors.carbon,
                  title: Text(
                    'Se déconnecter ?',
                    style: ArenaText.h3,
                  ),
                  content: Text(
                    "Tu reviendras à l'écran de login admin.",
                    style: ArenaText.body,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Annuler'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(
                        'Déconnexion',
                        style: ArenaText.button.copyWith(
                          color: ArenaColors.neonRed,
                        ),
                      ),
                    ),
                  ],
                ),
              );
              if (confirmed ?? false) {
                await ref.read(signOutProvider)();
              }
            },
          ),
        ],
      ),
      body: ArenaScreenBackground(
        accent: ArenaColors.neonRed,
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              ref
                ..invalidate(adminKpisProvider)
                ..invalidate(adminAuditLogProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(ArenaSpacing.lg),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Text(
                  '⚡ KPIs LIVE',
                  style: ArenaText.monoSmall.copyWith(
                    color: ArenaColors.neonRed,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: ArenaSpacing.sm),
                _KpiGrid(kpis: kpis).animate().fadeIn(
                      duration: ArenaDurations.medium,
                    ),
                const SizedBox(height: ArenaSpacing.md),
                _PayoutsKpi(kpis: kpis).animate(delay: 100.ms).fadeIn(
                      duration: ArenaDurations.medium,
                    ),
                const SizedBox(height: ArenaSpacing.lg),
                Text(
                  '🚨 ALERTES',
                  style: ArenaText.monoSmall.copyWith(
                    color: ArenaColors.neonRed,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: ArenaSpacing.sm),
                _AlertCards(kpis: kpis)
                    .animate(delay: 200.ms)
                    .fadeIn(duration: ArenaDurations.medium),
                const SizedBox(height: ArenaSpacing.lg),
                Text(
                  '⚡ ACTIONS RAPIDES',
                  style: ArenaText.monoSmall.copyWith(
                    color: ArenaColors.silver,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: ArenaSpacing.sm),
                ArenaButton(
                  label: '+ NOUVELLE COMPÉTITION',
                  fullWidth: true,
                  onPressed: () => context.push(AdminRoutes.competitionsCreate),
                ),
                const SizedBox(height: ArenaSpacing.xs),
                ArenaButton(
                  label: '🏆 VOIR LES COMPÉTITIONS',
                  fullWidth: true,
                  variant: ArenaButtonVariant.secondary,
                  onPressed: () => context.push(AdminRoutes.competitions),
                ),
                const SizedBox(height: ArenaSpacing.xs),
                ArenaButton(
                  label: '⚔ VOIR LES MATCHS',
                  fullWidth: true,
                  variant: ArenaButtonVariant.secondary,
                  onPressed: () => context.push(AdminRoutes.matches),
                ),
                const SizedBox(height: ArenaSpacing.xs),
                ArenaButton(
                  label: '💰 VALIDER PAYOUTS',
                  fullWidth: true,
                  variant: ArenaButtonVariant.secondary,
                  onPressed: () => context.push(AdminRoutes.payouts),
                ),
                const SizedBox(height: ArenaSpacing.xs),
                ArenaButton(
                  label: '📺 MODÉRATION STREAMS',
                  fullWidth: true,
                  variant: ArenaButtonVariant.secondary,
                  onPressed: () => context.push(AdminRoutes.streams),
                ),
                const SizedBox(height: ArenaSpacing.xs),
                ArenaButton(
                  label: "📜 JOURNAL D'AUDIT",
                  fullWidth: true,
                  variant: ArenaButtonVariant.secondary,
                  onPressed: () => context.push(AdminRoutes.auditLog),
                ),
                if (isSuperAdmin) ...[
                  const SizedBox(height: ArenaSpacing.lg),
                  Text(
                    '👑 SUPER-ADMIN',
                    style: ArenaText.monoSmall.copyWith(
                      color: ArenaColors.tierGoldWarm,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: ArenaSpacing.sm),
                  ArenaButton(
                    label: 'DASHBOARD SUPER-ADMIN',
                    fullWidth: true,
                    variant: ArenaButtonVariant.secondary,
                    onPressed: () => context.push(AdminRoutes.superDashboard),
                  ),
                  const SizedBox(height: ArenaSpacing.xs),
                  ArenaButton(
                    label: 'GESTION UTILISATEURS',
                    fullWidth: true,
                    variant: ArenaButtonVariant.secondary,
                    onPressed: () => context.push(AdminRoutes.superUsers),
                  ),
                  const SizedBox(height: ArenaSpacing.xs),
                  ArenaButton(
                    label: 'INVITATIONS ADMIN',
                    fullWidth: true,
                    variant: ArenaButtonVariant.secondary,
                    onPressed: () => context.push(AdminRoutes.superInvitations),
                  ),
                  const SizedBox(height: ArenaSpacing.xs),
                  ArenaButton(
                    label: '💸 VALIDER PAIEMENTS',
                    fullWidth: true,
                    variant: ArenaButtonVariant.primary,
                    onPressed: () =>
                        context.push(AdminRoutes.superPaymentsValidation),
                  ),
                  const SizedBox(height: ArenaSpacing.xs),
                  ArenaButton(
                    label: 'REVENUE PLATEFORME',
                    fullWidth: true,
                    variant: ArenaButtonVariant.secondary,
                    onPressed: () => context.push(AdminRoutes.superRevenue),
                  ),
                ],
                const SizedBox(height: ArenaSpacing.lg),
                Text(
                  '📜 ACTIVITÉ RÉCENTE',
                  style: ArenaText.monoSmall.copyWith(
                    color: ArenaColors.silver,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: ArenaSpacing.sm),
                _RecentActivity(entries: recent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.kpis});
  final AsyncValue<AdminKpis> kpis;

  @override
  Widget build(BuildContext context) {
    final activeComps = kpis.maybeWhen(
      data: (k) => k.activeCompetitions.toString(),
      orElse: () => '—',
    );
    final liveMatches = kpis.maybeWhen(
      data: (k) => k.liveMatches.toString(),
      orElse: () => '—',
    );
    final disputes = kpis.maybeWhen(
      data: (k) => k.openDisputes.toString(),
      orElse: () => '—',
    );

    return Row(
      children: [
        Expanded(
          child: _KpiTile(
            value: activeComps,
            label: 'Compét. actives',
            border: ArenaColors.signalBlue,
          ),
        ),
        const SizedBox(width: ArenaSpacing.sm),
        Expanded(
          child: _KpiTile(
            value: liveMatches,
            label: 'Matchs en cours',
            border: ArenaColors.statusWarn,
            valueColor: ArenaColors.statusWarn,
          ),
        ),
        const SizedBox(width: ArenaSpacing.sm),
        Expanded(
          child: _KpiTile(
            value: disputes,
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
  const _PayoutsKpi({required this.kpis});
  final AsyncValue<AdminKpis> kpis;

  @override
  Widget build(BuildContext context) {
    final count = kpis.maybeWhen(
      data: (k) => k.pendingPayouts.toString(),
      orElse: () => '—',
    );
    final amount = kpis.maybeWhen(
      data: (k) => NumberFormat('#,###', 'fr_FR')
          .format(k.pendingPayoutsAmountLocal.round())
          .replaceAll(',', ' '),
      orElse: () => '—',
    );

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
            count,
            style: ArenaText.bigNumber.copyWith(
              color: ArenaColors.neonRed,
              fontSize: 24,
            ),
          ),
          const SizedBox(width: ArenaSpacing.md),
          Expanded(
            child: Text(
              'Payouts en attente · $amount XAF',
              style: ArenaText.body,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertCards extends StatelessWidget {
  const _AlertCards({required this.kpis});
  final AsyncValue<AdminKpis> kpis;

  @override
  Widget build(BuildContext context) {
    final disputes = kpis.maybeWhen(
      data: (k) => k.openDisputes,
      orElse: () => 0,
    );
    final pendingPayouts = kpis.maybeWhen(
      data: (k) => k.pendingPayouts,
      orElse: () => 0,
    );

    if (disputes == 0 && pendingPayouts == 0) {
      return Container(
        padding: const EdgeInsets.all(ArenaSpacing.md),
        decoration: BoxDecoration(
          color: ArenaColors.carbon,
          borderRadius: BorderRadius.circular(ArenaRadius.lg),
          border: Border.all(color: ArenaColors.border),
        ),
        child: Text(
          '✅ Aucune alerte — bonne journée.',
          style: ArenaText.bodyMuted,
        ),
      );
    }

    return Column(
      children: [
        if (disputes > 0)
          _AlertCard(
            decoration: arenaDangerCardDecoration(),
            icon: '⚠',
            title:
                '$disputes ${disputes == 1 ? 'dispute ouverte' : 'disputes ouvertes'}',
            subtitle: "À traiter dans l'onglet Matchs",
            accent: ArenaColors.neonRed,
          ),
        if (disputes > 0 && pendingPayouts > 0)
          const SizedBox(height: ArenaSpacing.sm),
        if (pendingPayouts > 0)
          _AlertCard(
            decoration: arenaWarningCardDecoration(),
            icon: '⏱',
            title: 'Payouts en attente de validation',
            subtitle:
                '$pendingPayouts ${pendingPayouts == 1 ? 'joueur concerné' : 'joueurs concernés'}',
            accent: ArenaColors.statusWarn,
          ),
      ],
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

class _RecentActivity extends StatelessWidget {
  const _RecentActivity({required this.entries});
  final AsyncValue<List<AdminAuditLog>> entries;

  @override
  Widget build(BuildContext context) {
    return entries.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(ArenaSpacing.md),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(ArenaSpacing.md),
        child: Text('Erreur de chargement : $e', style: ArenaText.bodyMuted),
      ),
      data: (list) {
        final recent = list.take(5).toList(growable: false);
        if (recent.isEmpty) {
          return Text(
            'Aucune action récente.',
            style: ArenaText.bodyMuted,
          );
        }
        return Column(
          children: [
            for (var i = 0; i < recent.length; i++) ...[
              _ActivityRow(entry: recent[i]),
              if (i != recent.length - 1)
                const SizedBox(height: ArenaSpacing.xs),
            ],
          ],
        );
      },
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.entry});
  final AdminAuditLog entry;

  @override
  Widget build(BuildContext context) {
    final visual = _visualFor(entry.action);
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
            initials: visual.emoji,
            color: visual.color,
            size: ArenaAvatarSize.sm,
          ),
          const SizedBox(width: ArenaSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(visual.label, style: ArenaText.body),
                const SizedBox(height: 2),
                Text(
                  _formatTimestamp(entry.createdAt),
                  style: ArenaText.bodyMuted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityVisual {
  const _ActivityVisual({
    required this.emoji,
    required this.color,
    required this.label,
  });
  final String emoji;
  final ArenaAvatarColor color;
  final String label;
}

_ActivityVisual _visualFor(String action) {
  switch (action) {
    case 'payout_validated':
      return const _ActivityVisual(
        emoji: '💰',
        color: ArenaAvatarColor.green,
        label: 'Payout validé',
      );
    case 'payout_refused':
      return const _ActivityVisual(
        emoji: '🚫',
        color: ArenaAvatarColor.red,
        label: 'Payout refusé',
      );
    case 'dispute_resolved':
      return const _ActivityVisual(
        emoji: '⚖',
        color: ArenaAvatarColor.orange,
        label: 'Dispute tranchée',
      );
    case 'user_banned':
      return const _ActivityVisual(
        emoji: '🚫',
        color: ArenaAvatarColor.red,
        label: 'Utilisateur banni',
      );
    case 'user_unbanned':
      return const _ActivityVisual(
        emoji: '✅',
        color: ArenaAvatarColor.green,
        label: 'Utilisateur réactivé',
      );
    case 'match_verdict':
      return const _ActivityVisual(
        emoji: '⚽',
        color: ArenaAvatarColor.blue,
        label: 'Score validé',
      );
    case 'bracket_generated':
      return const _ActivityVisual(
        emoji: '🏆',
        color: ArenaAvatarColor.orange,
        label: 'Bracket généré',
      );
    case 'competition_created':
      return const _ActivityVisual(
        emoji: '➕',
        color: ArenaAvatarColor.cyan,
        label: 'Compétition créée',
      );
    case 'competition_cancelled':
      return const _ActivityVisual(
        emoji: '🚫',
        color: ArenaAvatarColor.red,
        label: 'Compétition annulée',
      );
    default:
      return _ActivityVisual(
        emoji: '•',
        color: ArenaAvatarColor.blue,
        label: action.replaceAll('_', ' '),
      );
  }
}

String _formatTimestamp(DateTime? at) {
  if (at == null) return '';
  final diff = DateTime.now().difference(at);
  if (diff.inMinutes < 1) return "À l'instant";
  if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
  if (diff.inDays == 1) return 'Hier';
  if (diff.inDays < 7) return '${diff.inDays}j';
  return DateFormat('dd/MM HH:mm').format(at);
}
