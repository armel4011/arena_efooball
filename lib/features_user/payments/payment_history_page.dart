import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// PHASE 11bis · P6 — payment + earnings history.
///
/// Two tabs (PAIEMENTS / GAINS), a month chip row to filter by period,
/// and a list of transaction cards (icon + label + amount + status
/// badge). Backend stream is wired in PHASE 11bis-2 against the
/// `payments` table; this screen ships with deterministic samples so
/// the layout can ship before the data lands.
///
/// Maps to screen P6 of `arena_v2.html`.
class PaymentHistoryPage extends StatefulWidget {
  const PaymentHistoryPage({super.key});

  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  String _month = 'Mai 2026';

  static const _months = ['Mai 2026', 'Avril', 'Mars'];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: ArenaAppBar(
          title: 'Historique',
          actions: [
            IconButton(
              tooltip: 'Exporter',
              icon: const Icon(
                Icons.download_outlined,
                color: ArenaColors.silver,
                size: 20,
              ),
              onPressed: () {},
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              const _HistoryTabs(),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  ArenaSpacing.lg,
                  ArenaSpacing.sm,
                  ArenaSpacing.lg,
                  ArenaSpacing.sm,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final m in _months)
                        Padding(
                          padding: const EdgeInsets.only(
                            right: ArenaSpacing.xs,
                          ),
                          child: _MonthChip(
                            label: m,
                            active: m == _month,
                            onTap: () => setState(() => _month = m),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _TransactionList(items: _payments),
                    _TransactionList(items: _earnings),
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

enum _TxKind { paymentOk, earningOk, paymentFail }

class _Tx {
  const _Tx({
    required this.title,
    required this.subtitle,
    required this.amountLabel,
    required this.kind,
  });

  final String title;
  final String subtitle;
  final String amountLabel;
  final _TxKind kind;
}

const _payments = <_Tx>[
  _Tx(
    title: 'Inscription FIFA Cup',
    subtitle: 'MTN MoMo · 09/05 14:23',
    amountLabel: '- 2 000',
    kind: _TxKind.paymentOk,
  ),
  _Tx(
    title: 'Inscription eFoot Masters',
    subtitle: 'MTN MoMo · 02/05 09:15',
    amountLabel: '- 5 000',
    kind: _TxKind.paymentOk,
  ),
  _Tx(
    title: 'Inscription EA FC Battle',
    subtitle: 'MTN MoMo · 01/05 11:42',
    amountLabel: '— 0',
    kind: _TxKind.paymentFail,
  ),
];

const _earnings = <_Tx>[
  _Tx(
    title: 'Gain FIFA Cup (1er)',
    subtitle: 'Orange Money · 06/05 18:00',
    amountLabel: '+ 25 000',
    kind: _TxKind.earningOk,
  ),
];

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

class _MonthChip extends StatelessWidget {
  const _MonthChip({
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

class _TransactionList extends StatelessWidget {
  const _TransactionList({required this.items});

  final List<_Tx> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(ArenaSpacing.xl),
          child: Text(
            'Aucune transaction sur cette période.',
            textAlign: TextAlign.center,
            style: ArenaText.bodyMuted,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: ArenaSpacing.lg),
      itemCount: items.length,
      itemBuilder: (context, i) => Padding(
        padding: const EdgeInsets.only(bottom: ArenaSpacing.sm),
        child: _TxCard(tx: items[i])
            .animate(delay: (i * 60).ms)
            .fadeIn(duration: ArenaDurations.medium),
      ),
    );
  }
}

class _TxCard extends StatelessWidget {
  const _TxCard({required this.tx});

  final _Tx tx;

  @override
  Widget build(BuildContext context) {
    final spec = _spec(tx.kind);
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(color: ArenaColors.border),
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
                  tx.title,
                  style: ArenaText.body.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(tx.subtitle, style: ArenaText.bodyMuted),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                tx.amountLabel,
                style: ArenaText.mono
                    .copyWith(color: spec.amountColor, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              ArenaBadge(label: spec.badge, variant: spec.badgeVariant),
            ],
          ),
        ],
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
  }) _spec(_TxKind kind) {
    return switch (kind) {
      _TxKind.paymentOk => (
          glyph: '↑',
          iconColor: Color(0xFFFFA500),
          tint: Color(0x33FFA500),
          amountColor: ArenaColors.neonRed,
          badge: 'OK',
          badgeVariant: ArenaBadgeVariant.success,
        ),
      _TxKind.earningOk => (
          glyph: '↓',
          iconColor: ArenaColors.statusOk,
          tint: Color(0x3300C896),
          amountColor: ArenaColors.statusOk,
          badge: 'VERSÉ',
          badgeVariant: ArenaBadgeVariant.success,
        ),
      _TxKind.paymentFail => (
          glyph: '✗',
          iconColor: ArenaColors.neonRed,
          tint: Color(0x33FF2D55),
          amountColor: ArenaColors.silverDim,
          badge: 'ÉCHEC',
          badgeVariant: ArenaBadgeVariant.danger,
        ),
    };
  }
}
