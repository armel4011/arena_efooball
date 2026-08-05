import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/utils/arena_error_message.dart';
import 'package:arena/data/repositories/admin/payment_collectors_repository.dart';
import 'package:arena/data/repositories/auth_repository.dart'
    show authRepositoryProvider;
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final _money = NumberFormat.decimalPattern('fr');
final _time = DateFormat('dd/MM HH:mm');

/// Console RÉDUITE du collecteur de paiement : sa jauge de quota, sa file de
/// paiements à valider (uniquement ses numéros / son pays), et le bouton pour
/// déclarer un versement (qui débloque son compte une fois validé par le
/// super-admin).
class CollectorConsolePage extends ConsumerWidget {
  const CollectorConsolePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(myCollectorsProvider);
    final pending = ref.watch(myPendingPaymentsProvider);

    void refresh() {
      ref
        ..invalidate(myCollectorsProvider)
        ..invalidate(myPendingPaymentsProvider);
    }

    return Scaffold(
      appBar: ArenaAppBar(
        title: 'COLLECTE',
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: ArenaColors.silver),
            tooltip: 'Se déconnecter',
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: ArenaScreenBackground(
        accent: ArenaColors.neonRed,
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async => refresh(),
            child: ListView(
              padding: const EdgeInsets.all(ArenaSpacing.lg),
              children: [
                Text('MON QUOTA', style: ArenaText.inputLabel),
                const SizedBox(height: ArenaSpacing.sm),
                accounts.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) =>
                      Text('Erreur : $e', style: ArenaText.bodyMuted),
                  data: (list) => list.isEmpty
                      ? Text(
                          "Aucun compte collecteur ne t'est encore affecté. "
                          'Contacte le super-admin.',
                          style: ArenaText.bodyMuted,
                        )
                      : Column(
                          children: [
                            for (final c in list) ...[
                              _QuotaCard(
                                collector: c,
                                onDeclare: () =>
                                    _declareRemittance(context, ref, c),
                              ),
                              const SizedBox(height: ArenaSpacing.sm),
                            ],
                          ],
                        ),
                ),
                const SizedBox(height: ArenaSpacing.lg),
                Text('PAIEMENTS À VALIDER', style: ArenaText.inputLabel),
                const SizedBox(height: ArenaSpacing.sm),
                pending.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) =>
                      Text('Erreur : $e', style: ArenaText.bodyMuted),
                  data: (list) => list.isEmpty
                      ? Text('Aucun paiement en attente.',
                          style: ArenaText.bodyMuted)
                      : Column(
                          children: [
                            for (final p in list) ...[
                              _PaymentCard(
                                payment: p,
                                onValidate: () => _validate(context, ref, p),
                                onReject: () => _reject(context, ref, p),
                              ),
                              const SizedBox(height: ArenaSpacing.sm),
                            ],
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

  Future<void> _validate(
    BuildContext context,
    WidgetRef ref,
    CollectorPayment p,
  ) async {
    final ok = await _confirm(
      context,
      'Valider le paiement',
      'Confirmes-tu avoir bien REÇU ${_money.format(p.amountLocal)} '
          '${p.currency}${p.payerPhone != null ? ' depuis ${p.payerPhone}' : ''} ?',
    );
    if (!ok) return;
    try {
      await ref.read(paymentCollectorsRepositoryProvider).validatePayment(p.id);
      _refresh(ref);
      if (!context.mounted) return;
      _toast(context, 'Paiement validé — inscription confirmée.');
    } catch (e) {
      if (!context.mounted) return;
      _toast(context, arenaErrorMessage(e));
    }
  }

  Future<void> _reject(
    BuildContext context,
    WidgetRef ref,
    CollectorPayment p,
  ) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ArenaColors.carbon,
        title: Text('Refuser le paiement', style: ArenaText.body),
        content: ArenaTextField(controller: ctrl, hint: 'Motif (ex. non reçu)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Refuser'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(paymentCollectorsRepositoryProvider).rejectPayment(
            paymentId: p.id,
            reason: ctrl.text.trim(),
          );
      _refresh(ref);
      if (!context.mounted) return;
      _toast(context, 'Paiement refusé.');
    } catch (e) {
      if (!context.mounted) return;
      _toast(context, arenaErrorMessage(e));
    }
  }

  Future<void> _declareRemittance(
    BuildContext context,
    WidgetRef ref,
    PaymentCollector c,
  ) async {
    final ok = await _confirm(
      context,
      'Déclarer un versement',
      'Déclarer avoir reversé ${_money.format(c.outstandingLocal)} au '
          'super-admin ? Ton compte sera réactivé une fois le versement '
          'validé par le super-admin.',
    );
    if (!ok) return;
    try {
      await ref
          .read(paymentCollectorsRepositoryProvider)
          .declareRemittance(collectorId: c.id);
      _refresh(ref);
      if (!context.mounted) return;
      _toast(context, 'Versement déclaré — en attente de validation.');
    } catch (e) {
      if (!context.mounted) return;
      _toast(context, arenaErrorMessage(e));
    }
  }

  void _refresh(WidgetRef ref) {
    ref
      ..invalidate(myCollectorsProvider)
      ..invalidate(myPendingPaymentsProvider);
  }

  Future<bool> _confirm(
    BuildContext context,
    String title,
    String body,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ArenaColors.carbon,
        title: Text(title, style: ArenaText.body),
        content: Text(body, style: ArenaText.bodyMuted),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

class _QuotaCard extends StatelessWidget {
  const _QuotaCard({required this.collector, required this.onDeclare});

  final PaymentCollector collector;
  final VoidCallback onDeclare;

  @override
  Widget build(BuildContext context) {
    final c = collector;
    final color = c.isBlocked ? ArenaColors.neonRed : ArenaColors.statusOk;
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (c.isBlocked)
            Text(
              'QUOTA ATTEINT — reverse pour rouvrir les paiements',
              style: ArenaText.small.copyWith(
                  color: ArenaColors.neonRed, fontWeight: FontWeight.w800),
            ),
          if (c.isBlocked) const SizedBox(height: ArenaSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: c.usageRatio,
              minHeight: 10,
              backgroundColor: ArenaColors.void_,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Encaissé ${_money.format(c.outstandingLocal)} / '
            '${_money.format(c.quotaLocal)}  ·  reste '
            '${_money.format(c.remaining)}',
            style: ArenaText.small.copyWith(color: ArenaColors.silver),
          ),
          const SizedBox(height: ArenaSpacing.sm),
          ArenaButton(
            label: 'DÉCLARER UN VERSEMENT',
            fullWidth: true,
            variant: c.isBlocked
                ? ArenaButtonVariant.primary
                : ArenaButtonVariant.secondary,
            onPressed: c.outstandingLocal > 0 ? onDeclare : null,
          ),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.payment,
    required this.onValidate,
    required this.onReject,
  });

  final CollectorPayment payment;
  final VoidCallback onValidate;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final p = payment;
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.md),
        border: Border.all(color: ArenaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_money.format(p.amountLocal)} ${p.currency}',
            style: ArenaText.body.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            [
              if (p.operatorLabel != null) p.operatorLabel!,
              if (p.payerPhone != null) p.payerPhone!,
              _time.format(p.createdAt.toLocal()),
            ].join('  ·  '),
            style: ArenaText.small.copyWith(color: ArenaColors.silver),
          ),
          if (p.competitionName != null) ...[
            const SizedBox(height: 2),
            Text(p.competitionName!,
                style: ArenaText.small.copyWith(color: ArenaColors.silver)),
          ],
          const SizedBox(height: ArenaSpacing.sm),
          Row(
            children: [
              Expanded(
                child: ArenaButton(
                  label: 'VALIDER',
                  variant: ArenaButtonVariant.success,
                  fullWidth: true,
                  onPressed: onValidate,
                ),
              ),
              const SizedBox(width: ArenaSpacing.xs),
              Expanded(
                child: ArenaButton(
                  label: 'REFUSER',
                  variant: ArenaButtonVariant.danger,
                  fullWidth: true,
                  onPressed: onReject,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
