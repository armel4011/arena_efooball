import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/repositories/payment_repository.dart';
import 'package:arena/features_user/payments/payment_method.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Banner d'alerte affiché en haut de la home quand le joueur a au
/// moins un paiement en `awaiting_admin`. Tap → ré-ouvre P3 sur la
/// transaction la plus récente.
class PendingPaymentBanner extends ConsumerWidget {
  const PendingPaymentBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final payments = ref.watch(myPaymentsProvider).valueOrNull ?? const [];
    final pending = payments
        .where((p) => p.status == 'awaiting_admin')
        .toList(growable: false);
    if (pending.isEmpty) return const SizedBox.shrink();
    final p = pending.first;
    final method = PaymentMethod.fromCode(p.payerMethod ?? 'MTN_MOMO');
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ArenaSpacing.lg,
        ArenaSpacing.sm,
        ArenaSpacing.lg,
        0,
      ),
      child: InkWell(
        onTap: () => context.push(
          UserRoutes.paymentProcessing,
          extra: PaymentProcessingArgs(
            paymentId: p.id,
            method: method,
            amountXaf: p.amountLocal.round(),
            competitionName: l10n.pendingPaymentCompetitionFallback,
            maskedPhone: p.payerPhone ?? '+••• •• •• ••',
          ),
        ),
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(ArenaSpacing.md),
          decoration: BoxDecoration(
            color: ArenaColors.signalBlue.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(ArenaRadius.lg),
            border: Border.all(
              color: ArenaColors.signalBlue.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ArenaColors.signalBlue.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Text('⏱', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: ArenaSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pending.length == 1
                          ? l10n.pendingPaymentSingleTitle
                          : '${pending.length} paiements en attente',
                      style: ArenaText.body
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.pendingPaymentTapToCheck,
                      style: ArenaText.small,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: ArenaColors.signalBlue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
