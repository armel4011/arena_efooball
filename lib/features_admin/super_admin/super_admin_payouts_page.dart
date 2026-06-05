import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/utils/arena_error_message.dart';
import 'package:arena/data/repositories/payout_repository.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_badge.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// F-1 · SA — File des versements de gains (P2P manuel).
///
/// Le super-admin voit les `payouts` encore `pending_admin_validation` :
/// d'abord ceux **réclamés** (le gagnant a fourni son numéro → prêts à payer),
/// puis ceux en attente de réclamation. Pour un payout réclamé, le super-admin
/// effectue le virement Mobile Money réel puis tape « MARQUER PAYÉ »
/// (`mark_payout_paid` → status `completed` + notif au gagnant).
class SuperAdminPayoutsPage extends ConsumerWidget {
  const SuperAdminPayoutsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pendingPayoutsProvider);
    return Scaffold(
      appBar: const ArenaAppBar(title: 'Versements'),
      body: ArenaScreenBackground(
        accent: ArenaColors.tierGoldWarm,
        child: SafeArea(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(ArenaSpacing.lg),
                child: Text('Erreur : $e', style: ArenaText.bodyMuted),
              ),
            ),
            data: (list) {
              if (list.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(ArenaSpacing.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('💰', style: ArenaText.h1.copyWith(fontSize: 48)),
                        const SizedBox(height: ArenaSpacing.sm),
                        Text(
                          'Aucun versement en attente.',
                          style: ArenaText.body,
                        ),
                      ],
                    ),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(pendingPayoutsProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(ArenaSpacing.lg),
                  itemCount: list.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: ArenaSpacing.sm),
                  itemBuilder: (_, i) => _PayoutCard(
                    payout: list[i],
                    onPaid: () => _markPaid(context, ref, list[i]),
                  ),
                ),
              );
            },
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
    final amount =
        NumberFormat('#,##0', 'fr_FR').format(payout.amountLocal).replaceAll(
              ',',
              ' ',
            );
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: ArenaColors.carbon,
        title: const Text('Confirmer le versement ?'),
        content: Text(
          'Confirme avoir versé $amount ${payout.currency} sur le '
          '${_methodLabel(payout.payeeMethod)} ${payout.payeePhone ?? "—"}.',
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
        SnackBar(content: Text('Erreur : ${arenaErrorMessage(e)}')),
      );
    }
  }
}

class _PayoutCard extends StatelessWidget {
  const _PayoutCard({required this.payout, required this.onPaid});

  final PayoutRecord payout;
  final VoidCallback onPaid;

  @override
  Widget build(BuildContext context) {
    final amount =
        NumberFormat('#,##0', 'fr_FR').format(payout.amountLocal).replaceAll(
              ',',
              ' ',
            );
    final claimed = payout.isClaimed;
    final color = claimed ? ArenaColors.statusOk : ArenaColors.silver;
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.4)),
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
                _kv(
                  'Montant',
                  '$amount ${payout.currency}',
                  emphasize: true,
                ),
                if (payout.rank != null) _kv('Rang', '${payout.rank}'),
                _kv('Méthode', _methodLabel(payout.payeeMethod)),
                _kv('Numéro retrait', payout.payeePhone ?? '—', mono: true),
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
            ArenaButton(
              label: '✓ MARQUER PAYÉ',
              fullWidth: true,
              onPressed: onPaid,
            )
          else
            Text(
              'En attente que le gagnant réclame (saisie de son numéro).',
              style: ArenaText.small.copyWith(color: ArenaColors.silver),
            ),
        ],
      ),
    );
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
}

String _methodLabel(String? code) {
  switch (code) {
    case 'MTN_MOMO':
      return 'MTN MoMo';
    case 'ORANGE_MONEY':
      return 'Orange Money';
    default:
      return '—';
  }
}
