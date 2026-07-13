import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/utils/arena_error_message.dart';
import 'package:arena/data/repositories/payout_repository.dart';
import 'package:arena/features_shared/admin/admin_formatters.dart';
import 'package:arena/features_shared/admin/payment_labels.dart';
import 'package:arena/features_shared/admin_sections.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:arena/features_shared/widgets/admin_scope_banner.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_badge.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Au-delà de N jours après réclamation sans versement, on signale un retard.
const _slaOverdueDays = 3;

/// F-1 · SA — Versements de gains (P2P manuel).
///
/// Deux onglets :
///   • À VERSER — payouts `pending_admin_validation` : réclamés (prêts à payer,
///     avec badge ⏱ RETARD au-delà de [_slaOverdueDays] jours) d'abord, puis
///     non réclamés. « MARQUER PAYÉ » → `mark_payout_paid`.
///   • À GÉNÉRER — compétitions `completed` avec gains mais sans payouts
///     générés (rétro / oubli). « GÉNÉRER » → `generate_payouts`.
class SuperAdminPayoutsPage extends ConsumerWidget {
  const SuperAdminPayoutsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: const ArenaAppBar(title: 'Versements'),
        body: ArenaScreenBackground(
          accent: ArenaColors.tierGoldWarm,
          child: SafeArea(
            child: Column(
              children: [
                if (adminHasCountryScope(profile))
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      ArenaSpacing.lg,
                      ArenaSpacing.sm,
                      ArenaSpacing.lg,
                      0,
                    ),
                    child: AdminScopeBanner(profile: profile),
                  ),
                const TabBar(
                  labelColor: ArenaColors.bone,
                  unselectedLabelColor: ArenaColors.silver,
                  indicatorColor: ArenaColors.signalBlue,
                  indicatorWeight: 2,
                  tabs: [
                    Tab(text: 'À VERSER'),
                    Tab(text: 'À GÉNÉRER'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _ToPayList(onPaid: (p) => _markPaid(context, ref, p)),
                      _ToGenerateList(
                        onGenerate: (c) => _generate(context, ref, c),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _markPaid(
    BuildContext context,
    WidgetRef ref,
    PayoutRecord payout,
  ) async {
    final amount = adminMoney(payout.amountLocal);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: ArenaColors.carbon,
        title: const Text('Confirmer le versement ?'),
        content: Text(
          'Confirme avoir versé $amount ${payout.currency} sur le '
          '${paymentMethodLabel(payout.payeeMethod)} ${payout.payeePhone ?? "—"}.',
          style: ArenaText.bodyMuted,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: ArenaColors.statusOk),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('MARQUER PAYÉ'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(payoutRepositoryProvider).markPaid(payout.id);
      ref.invalidate(pendingPayoutsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Versement marqué payé · gagnant notifié.'),
          backgroundColor: ArenaColors.statusOk,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : ${_scopeAwareError(context, e)}')),
      );
    }
  }

  Future<void> _generate(
    BuildContext context,
    WidgetRef ref,
    PendingPayoutCompetition comp,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: ArenaColors.carbon,
        title: const Text('Générer les versements ?'),
        content: Text(
          'Crée une ligne de versement pour chaque gagnant de « ${comp.name} » '
          'selon le classement final. Nécessite que le classement soit publié.',
          style: ArenaText.bodyMuted,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('GÉNÉRER'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final n = await ref.read(payoutRepositoryProvider).generate(comp.id);
      ref
        ..invalidate(competitionsPendingPayoutProvider)
        ..invalidate(pendingPayoutsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$n versement(s) généré(s) — gagnants notifiés.'),
          backgroundColor: ArenaColors.statusOk,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : ${_scopeAwareError(context, e)}')),
      );
    }
  }

  /// Un rejet 42501 des RPC `generate_payouts`/`mark_payout_paid` signifie
  /// que l'action sort du périmètre (pays/section) de l'admin. On le rend
  /// avec un message dédié plutôt que le générique « pas la permission ».
  String _scopeAwareError(BuildContext context, Object e) {
    if (e is PostgrestException && e.code == '42501') {
      return AppLocalizations.of(context).adminScopeOutOfPerimeter;
    }
    return arenaErrorMessage(e);
  }
}

class _ToPayList extends ConsumerWidget {
  const _ToPayList({required this.onPaid});

  final Future<void> Function(PayoutRecord) onPaid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pendingPayoutsProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(ArenaSpacing.lg),
          child: Text('Erreur : $e', style: ArenaText.bodyMuted),
        ),
      ),
      data: (list) {
        if (list.isEmpty) {
          return _empty('💰', 'Aucun versement en attente.');
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(pendingPayoutsProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(ArenaSpacing.lg),
            itemCount: list.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: ArenaSpacing.sm),
            itemBuilder: (_, i) =>
                _PayoutCard(payout: list[i], onPaid: () => onPaid(list[i])),
          ),
        );
      },
    );
  }
}

class _ToGenerateList extends ConsumerWidget {
  const _ToGenerateList({required this.onGenerate});

  final Future<void> Function(PendingPayoutCompetition) onGenerate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(competitionsPendingPayoutProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(ArenaSpacing.lg),
          child: Text('Erreur : $e', style: ArenaText.bodyMuted),
        ),
      ),
      data: (list) {
        if (list.isEmpty) {
          return _empty('✅', 'Toutes les compétitions sont réglées.');
        }
        return RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(competitionsPendingPayoutProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(ArenaSpacing.lg),
            itemCount: list.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: ArenaSpacing.sm),
            itemBuilder: (_, i) => _CompetitionToSettleCard(
              comp: list[i],
              onGenerate: () => onGenerate(list[i]),
            ),
          ),
        );
      },
    );
  }
}

Widget _empty(String emoji, String label) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(ArenaSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: ArenaText.h1.copyWith(fontSize: 48)),
          const SizedBox(height: ArenaSpacing.sm),
          Text(label, style: ArenaText.body, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class _PayoutCard extends StatelessWidget {
  const _PayoutCard({required this.payout, required this.onPaid});

  final PayoutRecord payout;
  final VoidCallback onPaid;

  @override
  Widget build(BuildContext context) {
    final amount = adminMoney(payout.amountLocal);
    final claimed = payout.isClaimed;
    final overdue = claimed &&
        payout.claimedAt != null &&
        DateTime.now().difference(payout.claimedAt!).inDays >= _slaOverdueDays;
    final color = claimed ? ArenaColors.statusOk : ArenaColors.silver;
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(
          color: (overdue ? ArenaColors.neonRed : color)
              .withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  payout.competitionName ??
                      'Compétition ${payout.competitionId.substring(0, 8)}',
                  style: ArenaText.body.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (overdue) ...[
                const ArenaBadge(
                  label: '⏱ RETARD',
                  variant: ArenaBadgeVariant.danger,
                ),
                const SizedBox(width: ArenaSpacing.xs),
              ],
              ArenaBadge(
                label: claimed ? 'À PAYER' : 'NON RÉCLAMÉ',
                variant:
                    claimed ? ArenaBadgeVariant.success : ArenaBadgeVariant.warn,
              ),
            ],
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Container(
            padding: const EdgeInsets.all(ArenaSpacing.sm),
            decoration: BoxDecoration(
              color: ArenaColors.surface,
              borderRadius: BorderRadius.circular(ArenaRadius.md),
            ),
            child: Column(
              children: [
                _kv('Montant', '$amount ${payout.currency}', emphasize: true),
                if (payout.rank != null) _kv('Rang', '${payout.rank}'),
                _kv('Méthode', paymentMethodLabel(payout.payeeMethod)),
                _kv('Numéro retrait', payout.payeePhone ?? '—', mono: true),
                if (claimed && payout.claimedAt != null)
                  _kv(
                    'Réclamé le',
                    DateFormat('dd/MM/yyyy').format(payout.claimedAt!.toLocal()),
                  ),
                _kv(
                  'Référence',
                  'PAYOUT-${payout.id.substring(0, 8).toUpperCase()}',
                  mono: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: ArenaSpacing.sm),
          if (claimed)
            ArenaButton(label: '✓ MARQUER PAYÉ', fullWidth: true, onPressed: onPaid)
          else
            Text(
              'En attente que le gagnant réclame (saisie de son numéro).',
              style: ArenaText.small.copyWith(color: ArenaColors.silver),
            ),
        ],
      ),
    );
  }
}

class _CompetitionToSettleCard extends StatelessWidget {
  const _CompetitionToSettleCard({required this.comp, required this.onGenerate});

  final PendingPayoutCompetition comp;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border:
            Border.all(color: ArenaColors.tierGoldWarm.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            comp.name,
            style: ArenaText.body.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Cagnotte : ${adminMoney(comp.prizePoolLocal)} ${comp.currency}',
            style: ArenaText.bodyMuted,
          ),
          const SizedBox(height: ArenaSpacing.sm),
          ArenaButton(
            label: '💰 GÉNÉRER LES VERSEMENTS',
            fullWidth: true,
            onPressed: onGenerate,
          ),
        ],
      ),
    );
  }
}

Widget _kv(
  String key,
  String value, {
  bool mono = false,
  bool emphasize = false,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(key, style: ArenaText.bodyMuted),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: (mono ? ArenaText.mono : ArenaText.body).copyWith(
              color: emphasize ? ArenaColors.tierGoldWarm : null,
              fontWeight: emphasize ? FontWeight.w700 : null,
            ),
          ),
        ),
      ],
    ),
  );
}

// _fmt → adminMoney (features_shared/admin/admin_formatters.dart)

// _methodLabel → paymentMethodLabel (features_shared/admin/payment_labels.dart)
