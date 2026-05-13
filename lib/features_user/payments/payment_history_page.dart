import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/repositories/payment_repository.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_badge.dart';
import 'package:arena/features_user/payments/payment_method.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// PHASE 11bis · P6 — Historique paiements (live).
///
/// Stream `payments` table via [myPaymentsProvider]. L'onglet GAINS reste
/// vide en V1 (les payouts auto sont reportés en V2).
///
/// Maps to screen P6 of `arena_v2.html`.
class PaymentHistoryPage extends ConsumerWidget {
  const PaymentHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(myPaymentsProvider);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: const ArenaAppBar(title: 'Historique'),
        body: SafeArea(
          child: Column(
            children: [
              const _HistoryTabs(),
              Expanded(
                child: TabBarView(
                  children: [
                    paymentsAsync.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (e, _) => Center(
                        child: Text('Erreur : $e', style: ArenaText.bodyMuted),
                      ),
                      data: (list) => _PaymentList(items: list),
                    ),
                    _EmptyGains(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryTabs extends StatelessWidget {
  const _HistoryTabs();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ArenaSpacing.lg),
      child: TabBar(
        labelStyle: ArenaText.button,
        unselectedLabelStyle: ArenaText.button,
        labelColor: ArenaColors.bone,
        unselectedLabelColor: ArenaColors.silver,
        indicatorColor: ArenaColors.signalBlue,
        indicatorWeight: 2,
        tabs: const [
          Tab(text: 'PAIEMENTS'),
          Tab(text: 'GAINS'),
        ],
      ),
    );
  }
}

class _EmptyGains extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ArenaSpacing.xl),
        child: Text(
          'Les gains automatiques arrivent en V2 (payouts CinetPay '
          '+ NowPayments). En V1, le super-admin verse manuellement.',
          textAlign: TextAlign.center,
          style: ArenaText.bodyMuted,
        ),
      ),
    );
  }
}

class _PaymentList extends StatelessWidget {
  const _PaymentList({required this.items});

  final List<PaymentRecord> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(ArenaSpacing.xl),
          child: Text(
            'Aucun paiement pour le moment.',
            textAlign: TextAlign.center,
            style: ArenaText.bodyMuted,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: ArenaSpacing.lg,
        vertical: ArenaSpacing.sm,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => Padding(
        padding: const EdgeInsets.only(bottom: ArenaSpacing.sm),
        child: _TxCard(payment: items[i])
            .animate(delay: (i * 60).ms)
            .fadeIn(duration: ArenaDurations.medium),
      ),
    );
  }
}

class _TxCard extends StatelessWidget {
  const _TxCard({required this.payment});

  final PaymentRecord payment;

  bool get _isResumable => payment.status == 'awaiting_admin';

  @override
  Widget build(BuildContext context) {
    final spec = _spec(payment.status);
    final dateLabel = DateFormat('dd/MM HH:mm').format(
      payment.createdAt.toLocal(),
    );
    final methodLabel = payment.payerMethod == 'ORANGE_MONEY'
        ? 'Orange Money'
        : 'MTN MoMo';
    final amount = NumberFormat('#,##0', 'fr_FR')
        .format(payment.amountLocal)
        .replaceAll(',', ' ');
    final card = Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(
          color: _isResumable
              ? ArenaColors.signalBlue.withValues(alpha: 0.4)
              : ArenaColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: spec.tint,
              borderRadius: BorderRadius.circular(ArenaRadius.sm),
            ),
            child: Text(
              spec.glyph,
              style: ArenaText.h3.copyWith(color: spec.iconColor, fontSize: 14),
            ),
          ),
          const SizedBox(width: ArenaSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inscription compétition',
                  style: ArenaText.body.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text('$methodLabel · $dateLabel', style: ArenaText.bodyMuted),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                spec.isFail ? '— 0' : '- $amount',
                style: ArenaText.mono.copyWith(
                  color: spec.amountColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              ArenaBadge(label: spec.badge, variant: spec.badgeVariant),
            ],
          ),
        ],
      ),
    );

    if (!_isResumable) return card;

    return InkWell(
      onTap: () => _resume(context),
      borderRadius: BorderRadius.circular(ArenaRadius.lg),
      child: card,
    );
  }

  void _resume(BuildContext context) {
    final method = PaymentMethod.fromCode(payment.payerMethod ?? 'MTN_MOMO');
    context.push(
      UserRoutes.paymentProcessing,
      extra: PaymentProcessingArgs(
        paymentId: payment.id,
        method: method,
        amountXaf: payment.amountLocal.round(),
        competitionName: 'Compétition',
        maskedPhone: payment.payerPhone ?? '+••• •• •• ••',
      ),
    );
  }

  static ({
    String glyph,
    Color iconColor,
    Color tint,
    Color amountColor,
    String badge,
    ArenaBadgeVariant badgeVariant,
    bool isFail,
  }) _spec(String status) {
    switch (status) {
      case 'succeeded':
        return (
          glyph: '↑',
          iconColor: Color(0xFFFFA500),
          tint: Color(0x33FFA500),
          amountColor: ArenaColors.neonRed,
          badge: 'PAYÉ',
          badgeVariant: ArenaBadgeVariant.success,
          isFail: false,
        );
      case 'awaiting_admin':
      case 'pending':
      case 'processing':
        return (
          glyph: '⏱',
          iconColor: ArenaColors.signalBlue,
          tint: Color(0x33007BFF),
          amountColor: ArenaColors.silver,
          badge: 'EN ATTENTE',
          badgeVariant: ArenaBadgeVariant.warn,
          isFail: false,
        );
      case 'rejected':
      case 'failed':
      default:
        return (
          glyph: '✗',
          iconColor: ArenaColors.neonRed,
          tint: Color(0x33FF2D55),
          amountColor: ArenaColors.silverDim,
          badge: 'ÉCHEC',
          badgeVariant: ArenaBadgeVariant.danger,
          isFail: true,
        );
    }
  }
}
