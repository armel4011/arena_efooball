import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/repositories/payment_repository.dart';
import 'package:arena/data/repositories/payout_repository.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_badge.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
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
        appBar: const ArenaAppBar(title: 'HISTORIQUE'),
        body: ArenaScreenBackground(
          child: SafeArea(
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
                          child:
                              Text('Erreur : $e', style: ArenaText.bodyMuted),
                        ),
                        data: (list) => _PaymentList(items: list),
                      ),
                      const _GainsTab(),
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

/// Onglet GAINS — liste les `payouts` du joueur. Pour un gain encore non
/// réclamé, le joueur saisit son numéro Mobile Money de retrait ; le
/// super-admin verse ensuite manuellement (F-1).
class _GainsTab extends ConsumerWidget {
  const _GainsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payoutsAsync = ref.watch(myPayoutsProvider);
    return payoutsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          Center(child: Text('Erreur : $e', style: ArenaText.bodyMuted)),
      data: (list) {
        if (list.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(ArenaSpacing.xl),
              child: Text(
                'Aucun gain pour le moment. Remporte une compétition pour '
                'recevoir un versement !',
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
          itemCount: list.length,
          itemBuilder: (context, i) => Padding(
            padding: const EdgeInsets.only(bottom: ArenaSpacing.sm),
            child: _PayoutCard(payout: list[i])
                .animate(delay: (i * 60).ms)
                .fadeIn(duration: ArenaDurations.medium),
          ),
        );
      },
    );
  }
}

class _PayoutCard extends ConsumerWidget {
  const _PayoutCard({required this.payout});

  final PayoutRecord payout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amount = NumberFormat('#,##0', 'fr_FR')
        .format(payout.amountLocal)
        .replaceAll(',', ' ');
    final (badge, variant) = switch (payout) {
      final p when p.isPaid => ('VERSÉ', ArenaBadgeVariant.success),
      final p when p.isClaimed => ('EN ATTENTE', ArenaBadgeVariant.warn),
      _ => ('À RÉCLAMER', ArenaBadgeVariant.danger),
    };
    final canClaim = payout.isPending && !payout.isClaimed;

    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.tierGoldWarm.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(
          color: ArenaColors.tierGoldWarm.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payout.rank != null
                          ? 'Gain · rang ${payout.rank}'
                          : 'Gain de compétition',
                      style:
                          ArenaText.body.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('dd/MM/yyyy').format(
                        payout.createdAt.toLocal(),
                      ),
                      style: ArenaText.bodyMuted,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '+ $amount ${payout.currency}',
                    style: ArenaText.mono.copyWith(
                      color: ArenaColors.tierGoldWarm,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ArenaBadge(label: badge, variant: variant),
                ],
              ),
            ],
          ),
          if (canClaim) ...[
            const SizedBox(height: ArenaSpacing.sm),
            ArenaButton(
              label: 'RÉCLAMER MON GAIN',
              fullWidth: true,
              onPressed: () => _claim(context, ref),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _claim(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<({String phone, String method})>(
      context: context,
      backgroundColor: ArenaColors.carbon,
      isScrollControlled: true,
      builder: (c) => _ClaimSheet(currency: payout.currency),
    );
    if (result == null) return;
    try {
      await ref.read(payoutRepositoryProvider).claim(
            payoutId: payout.id,
            phone: result.phone,
            method: result.method,
          );
      ref.invalidate(myPayoutsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gain réclamé — le staff va procéder au versement.'),
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

/// Feuille de saisie du numéro/méthode Mobile Money de retrait.
class _ClaimSheet extends StatefulWidget {
  const _ClaimSheet({required this.currency});

  final String currency;

  @override
  State<_ClaimSheet> createState() => _ClaimSheetState();
}

class _ClaimSheetState extends State<_ClaimSheet> {
  final _phone = TextEditingController();
  String _method = 'MTN_MOMO';

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: ArenaSpacing.lg,
        right: ArenaSpacing.lg,
        top: ArenaSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + ArenaSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Réclamer mon gain', style: ArenaText.h3),
          const SizedBox(height: ArenaSpacing.xs),
          Text(
            'Indique le numéro Mobile Money sur lequel recevoir ton versement.',
            style: ArenaText.bodyMuted,
          ),
          const SizedBox(height: ArenaSpacing.md),
          Row(
            children: [
              Expanded(
                child: _MethodChip(
                  label: 'MTN MoMo',
                  selected: _method == 'MTN_MOMO',
                  onTap: () => setState(() => _method = 'MTN_MOMO'),
                ),
              ),
              const SizedBox(width: ArenaSpacing.sm),
              Expanded(
                child: _MethodChip(
                  label: 'Orange Money',
                  selected: _method == 'ORANGE_MONEY',
                  onTap: () => setState(() => _method = 'ORANGE_MONEY'),
                ),
              ),
            ],
          ),
          const SizedBox(height: ArenaSpacing.md),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            style: ArenaText.body,
            decoration: const InputDecoration(
              hintText: 'Numéro Mobile Money (ex. +237 6XX XX XX XX)',
            ),
          ),
          const SizedBox(height: ArenaSpacing.lg),
          ArenaButton(
            label: 'CONFIRMER',
            fullWidth: true,
            onPressed: () {
              final phone = _phone.text.trim();
              if (phone.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Numéro requis.')),
                );
                return;
              }
              Navigator.of(context).pop((phone: phone, method: _method));
            },
          ),
        ],
      ),
    );
  }
}

class _MethodChip extends StatelessWidget {
  const _MethodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ArenaRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: ArenaSpacing.sm),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? ArenaColors.signalBlue.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(ArenaRadius.md),
          border: Border.all(
            color: selected ? ArenaColors.signalBlue : ArenaColors.silverDim,
          ),
        ),
        child: Text(
          label,
          style: ArenaText.button.copyWith(
            color: selected ? ArenaColors.bone : ArenaColors.silver,
          ),
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
    // Net balance = somme des paiements succeeded (en négatif côté
    // joueur). Affiché en footer card glow gold (maquette P6).
    final netSucceeded = items
        .where((p) => p.status == 'succeeded')
        .fold<double>(0, (acc, p) => acc - p.amountLocal);
    final netLabel = NumberFormat('#,##0', 'fr_FR')
        .format(netSucceeded)
        .replaceAll(',', ' ');

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
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
          ),
        ),
        _NetBalanceFooter(label: netLabel),
      ],
    );
  }
}

/// Footer card glow gold "SOLDE NET — {sign}{amount} XAF". Reproduit
/// `.m-card-glow` de la maquette P6 avec montant en mono 22 px gold.
class _NetBalanceFooter extends StatelessWidget {
  const _NetBalanceFooter({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ArenaSpacing.lg,
        ArenaSpacing.sm,
        ArenaSpacing.lg,
        ArenaSpacing.lg,
      ),
      child: Container(
        padding: const EdgeInsets.all(ArenaSpacing.md),
        decoration: BoxDecoration(
          color: ArenaColors.tierGoldWarm.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(ArenaRadius.lg),
          border: Border.all(
            color: ArenaColors.tierGoldWarm.withValues(alpha: 0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: ArenaColors.tierGoldWarm.withValues(alpha: 0.18),
              blurRadius: 18,
              spreadRadius: -4,
            ),
          ],
        ),
        child: Row(
          children: [
            Text(
              'SOLDE NET',
              style: ArenaText.monoSmall.copyWith(
                color: ArenaColors.bone,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              '$label XAF',
              style: ArenaText.mono.copyWith(
                color: ArenaColors.tierGoldWarm,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
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
    final methodLabel =
        payment.payerMethod == 'ORANGE_MONEY' ? 'Orange Money' : 'MTN MoMo';
    final amount = NumberFormat('#,##0', 'fr_FR')
        .format(payment.amountLocal)
        .replaceAll(',', ' ');
    // Card teintée selon le statut (maquette P6 : m-card-danger pour les
    // sorties, m-card-success pour les gains). On garde un border vif si
    // resumable pour signaler que la card est tappable.
    final cardAccent = _isResumable ? ArenaColors.signalBlue : spec.iconColor;
    final card = Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: spec.iconColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(
          color: cardAccent.withValues(alpha: _isResumable ? 0.45 : 0.3),
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
          iconColor: ArenaColors.brandMtnMomo,
          tint: const Color(0x33FFA500), // brandMtnMomo @ 20% alpha
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
          tint: const Color(0x33007BFF),
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
          tint: const Color(0x33FF2D55),
          amountColor: ArenaColors.silverDim,
          badge: 'ÉCHEC',
          badgeVariant: ArenaBadgeVariant.danger,
          isFail: true,
        );
    }
  }
}
