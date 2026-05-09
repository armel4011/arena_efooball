import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:flutter/material.dart';

/// PHASE 11 · SA4 — super-admin revenue & accounting export.
///
/// Period chips (Mai / Avril / Q2 / Année) + currency toggle (XAF / USD
/// / EUR), the period income hero card, line-by-line breakdown of
/// payouts and processor fees ending on the net margin, a per-tournament
/// table and an evolution bar chart placeholder. CSV export ships in
/// PHASE 11.7.
///
/// Maps to screen SA4 of `arena_v2.html`.
class SuperAdminRevenue extends StatefulWidget {
  const SuperAdminRevenue({super.key});

  @override
  State<SuperAdminRevenue> createState() => _SuperAdminRevenueState();
}

class _SuperAdminRevenueState extends State<SuperAdminRevenue> {
  String _period = 'Mai 2026';
  String _currency = 'XAF';

  static const _periods = ['Mai 2026', 'Avril', 'Q2 2026', 'Année'];
  static const _currencies = ['XAF', 'USD', 'EUR'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ArenaAppBar(
        title: 'Revenus & compta',
        actions: [
          TextButton(
            onPressed: () {},
            child: Text(
              'CSV ↓',
              style: ArenaText.body.copyWith(
                color: ArenaColors.statusOk,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(ArenaSpacing.lg),
          children: [
            _ChipsRow(
              labels: _periods,
              current: _period,
              onTap: (l) => setState(() => _period = l),
            ),
            const SizedBox(height: ArenaSpacing.xs),
            _ChipsRow(
              labels: _currencies,
              current: _currency,
              onTap: (l) => setState(() => _currency = l),
            ),
            const SizedBox(height: ArenaSpacing.md),
            const _RevenueHero(),
            const SizedBox(height: ArenaSpacing.lg),
            Text('DÉCOMPOSITION', style: ArenaText.inputLabel),
            const SizedBox(height: ArenaSpacing.sm),
            const _BreakdownCard(),
            const SizedBox(height: ArenaSpacing.sm),
            Center(
              child: Text(
                'Marge 22.5% · vs 19.8% en avril',
                style: ArenaText.bodyMuted
                    .copyWith(color: ArenaColors.statusOk),
              ),
            ),
            const SizedBox(height: ArenaSpacing.lg),
            Text('PAR COMPÉTITION', style: ArenaText.inputLabel),
            const SizedBox(height: ArenaSpacing.sm),
            const _CompetitionsTable(),
            const SizedBox(height: ArenaSpacing.lg),
            Text('📈 Évolution marge', style: ArenaText.h3),
            const SizedBox(height: ArenaSpacing.sm),
            const _BarChart(),
            const SizedBox(height: ArenaSpacing.lg),
            ArenaButton(
              label: '📥 EXPORT CSV (comptable)',
              fullWidth: true,
              size: ArenaButtonSize.large,
              onPressed: () {},
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
              child: InkWell(
                onTap: () => onTap(l),
                borderRadius: BorderRadius.circular(ArenaRadius.round),
                child: AnimatedContainer(
                  duration: ArenaDurations.short,
                  padding: const EdgeInsets.symmetric(
                    horizontal: ArenaSpacing.md,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: l == current
                        ? ArenaColors.signalBlue.withValues(alpha: 0.15)
                        : ArenaColors.carbon,
                    borderRadius:
                        BorderRadius.circular(ArenaRadius.round),
                    border: Border.all(
                      color: l == current
                          ? ArenaColors.signalBlue
                          : ArenaColors.border,
                    ),
                  ),
                  child: Text(
                    l,
                    style: ArenaText.body.copyWith(
                      color: l == current
                          ? ArenaColors.signalBlue
                          : ArenaColors.silver,
                      fontWeight: l == current
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RevenueHero extends StatelessWidget {
  const _RevenueHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.lg),
      decoration: arenaSuccessCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Revenus période', style: ArenaText.bodyMuted),
          const SizedBox(height: 4),
          Text(
            '2 458 750 XAF',
            style: ArenaText.bigNumber
                .copyWith(color: ArenaColors.statusOk, fontSize: 30),
          ),
          const SizedBox(height: 2),
          Text('≈ 4 030 USD', style: ArenaText.bodyMuted),
        ],
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard();

  static const _rows = <(String, String, _RowKind)>[
    ('Frais inscriptions collectés', '2 458 750', _RowKind.neutral),
    ('— Payouts versés', '-1 850 200', _RowKind.negative),
    ('— Frais CinetPay (1.8%)', '-44 257', _RowKind.negative),
    ('— Frais NowPayments (0.5%)', '-12 293', _RowKind.negative),
    ('= MARGE NETTE', '552 000 XAF', _RowKind.positive),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(color: ArenaColors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < _rows.length; i++) ...[
            _BreakdownRow(
              label: _rows[i].$1,
              value: _rows[i].$2,
              kind: _rows[i].$3,
            ),
            if (i < _rows.length - 1)
              const Divider(
                height: 1,
                thickness: 1,
                color: ArenaColors.border,
              ),
          ],
        ],
      ),
    );
  }
}

enum _RowKind { neutral, negative, positive }

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.value,
    required this.kind,
  });

  final String label;
  final String value;
  final _RowKind kind;

  @override
  Widget build(BuildContext context) {
    final color = switch (kind) {
      _RowKind.neutral => ArenaColors.bone,
      _RowKind.negative => ArenaColors.neonRed,
      _RowKind.positive => ArenaColors.statusOk,
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ArenaSpacing.md,
        vertical: ArenaSpacing.sm,
      ),
      color: kind == _RowKind.positive
          ? ArenaColors.statusOk.withValues(alpha: 0.05)
          : null,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: ArenaText.body.copyWith(
                fontWeight:
                    kind == _RowKind.positive ? FontWeight.w700 : null,
              ),
            ),
          ),
          Text(
            value,
            style: ArenaText.mono.copyWith(
              color: color,
              fontWeight:
                  kind == _RowKind.positive ? FontWeight.w700 : null,
              fontSize: kind == _RowKind.positive ? 14 : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompetitionsTable extends StatelessWidget {
  const _CompetitionsTable();

  static const _rows = <(String, String, String, String)>[
    ('FIFA Cup #45', '16', '80 000', '18 000'),
    ('EA FC Night #12', '32', '320 000', '72 000'),
    ('eFoot Masters #8', '16', '80 000', '18 000'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.sm),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(color: ArenaColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Text('Compét.', style: ArenaText.inputLabel),
              ),
              Expanded(
                child: Text(
                  'Inscrits',
                  textAlign: TextAlign.right,
                  style: ArenaText.inputLabel,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Revenu',
                  textAlign: TextAlign.right,
                  style: ArenaText.inputLabel,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Marge',
                  textAlign: TextAlign.right,
                  style: ArenaText.inputLabel,
                ),
              ),
            ],
          ),
          const Divider(color: ArenaColors.border, height: 14),
          for (final (name, regs, revenue, margin) in _rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      name,
                      style: ArenaText.body
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      regs,
                      textAlign: TextAlign.right,
                      style: ArenaText.body,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      revenue,
                      textAlign: TextAlign.right,
                      style: ArenaText.mono,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      margin,
                      textAlign: TextAlign.right,
                      style: ArenaText.mono
                          .copyWith(color: ArenaColors.statusOk),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  const _BarChart();

  static const _heights = [0.25, 0.35, 0.48, 0.55, 0.70, 0.82, 1.0];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      padding: const EdgeInsets.all(ArenaSpacing.sm),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(color: ArenaColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final h in _heights) ...[
            Expanded(
              child: FractionallySizedBox(
                heightFactor: h,
                child: Container(
                  decoration: BoxDecoration(
                    color: ArenaColors.statusOk
                        .withValues(alpha: 0.5 + 0.5 * h),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
            if (h != _heights.last) const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }
}
