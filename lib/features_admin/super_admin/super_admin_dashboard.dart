import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_avatar.dart';
import 'package:flutter/material.dart';

/// PHASE 11 · SA1 — super-admin global dashboard.
///
/// Reserved for the founder role. Surfaces MAU/DAU + 30-day margin +
/// signup line chart placeholder + revenue bar chart placeholder + top
/// players + country distribution + Sentry alerts. Real charts will
/// land via fl_chart in PHASE 11.6 — for now we ship the layout with
/// SVG-ish placeholders so the visual is correct.
///
/// Maps to screen SA1 of `arena_v2.html`.
class SuperAdminDashboard extends StatelessWidget {
  const SuperAdminDashboard({super.key});

  static const _gold = ArenaColors.tierGold;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ArenaAppBar(title: 'Super-admin', showBack: false),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(ArenaSpacing.lg),
          children: [
            Text(
              'KPIs GLOBAUX · MAI 2026',
              style: ArenaText.inputLabel.copyWith(color: _gold),
            ),
            const SizedBox(height: ArenaSpacing.sm),
            const _KpiRow(),
            const SizedBox(height: ArenaSpacing.sm),
            const _MarginCard(),
            const SizedBox(height: ArenaSpacing.lg),
            Text('📈 Inscriptions / mois', style: ArenaText.h3),
            const SizedBox(height: ArenaSpacing.sm),
            const _LineChartPlaceholder(),
            const SizedBox(height: ArenaSpacing.lg),
            Text('💰 Revenus / mois', style: ArenaText.h3),
            const SizedBox(height: ArenaSpacing.sm),
            const _BarChartPlaceholder(),
            const SizedBox(height: ArenaSpacing.lg),
            Text('🏆 Top 10 joueurs', style: ArenaText.h3),
            const SizedBox(height: ArenaSpacing.sm),
            const _TopPlayers(),
            const SizedBox(height: ArenaSpacing.lg),
            Text('🌍 Répartition pays', style: ArenaText.h3),
            const SizedBox(height: ArenaSpacing.sm),
            const _CountryBreakdown(),
            const SizedBox(height: ArenaSpacing.lg),
            Container(
              padding: const EdgeInsets.all(ArenaSpacing.md),
              decoration: arenaDangerCardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🚨 Alertes système', style: ArenaText.h3),
                  const SizedBox(height: 4),
                  Text(
                    'Edge Function nowpayments_webhook : 3 erreurs (Sentry)',
                    style: ArenaText.bodyMuted,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiRow extends StatelessWidget {
  const _KpiRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _Tile(
            value: '12 048',
            label: 'MAU',
            border: SuperAdminDashboard._gold,
            valueColor: SuperAdminDashboard._gold,
          ),
        ),
        SizedBox(width: ArenaSpacing.sm),
        Expanded(child: _Tile(value: '3 247', label: 'DAU')),
        SizedBox(width: ArenaSpacing.sm),
        Expanded(
          child: _Tile(
            value: '27%',
            label: 'DAU/MAU',
            valueColor: ArenaColors.statusOk,
          ),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.value,
    required this.label,
    this.border,
    this.valueColor,
  });

  final String value;
  final String label;
  final Color? border;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: ArenaSpacing.md,
        horizontal: ArenaSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(color: border ?? ArenaColors.border),
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
          Text(label, style: ArenaText.bodyMuted),
        ],
      ),
    );
  }
}

class _MarginCard extends StatelessWidget {
  const _MarginCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: ArenaSpacing.md,
        horizontal: ArenaSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: ArenaColors.statusOk.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(color: ArenaColors.statusOk),
      ),
      child: Column(
        children: [
          Text(
            '1.2M XAF',
            style: ArenaText.bigNumber.copyWith(
              color: ArenaColors.statusOk,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 2),
          Text('Marge ARENA · 30j', style: ArenaText.bodyMuted),
        ],
      ),
    );
  }
}

class _LineChartPlaceholder extends StatelessWidget {
  const _LineChartPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(ArenaSpacing.sm),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(color: ArenaColors.border),
      ),
      child: CustomPaint(
        painter: _LinePainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height - 14;
    final pts = <Offset>[
      Offset(w * 0.04, h * 0.85),
      Offset(w * 0.18, h * 0.75),
      Offset(w * 0.32, h * 0.6),
      Offset(w * 0.46, h * 0.45),
      Offset(w * 0.6, h * 0.4),
      Offset(w * 0.74, h * 0.3),
      Offset(w * 0.88, h * 0.2),
      Offset(w * 0.95, h * 0.12),
    ];
    final fill = Path()..moveTo(pts.first.dx, h);
    for (final p in pts) {
      fill.lineTo(p.dx, p.dy);
    }
    fill
      ..lineTo(pts.last.dx, h)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ArenaColors.signalBlue.withValues(alpha: 0.4),
            ArenaColors.signalBlue.withValues(alpha: 0),
          ],
        ).createShader(Offset.zero & size),
    );
    final stroke = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      stroke.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      stroke,
      Paint()
        ..color = ArenaColors.signalBlue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BarChartPlaceholder extends StatelessWidget {
  const _BarChartPlaceholder();

  static const _heights = [0.30, 0.42, 0.55, 0.65, 0.78, 0.88, 1.0];

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
                        .withValues(alpha: 0.6 + 0.4 * h),
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

class _TopPlayers extends StatelessWidget {
  const _TopPlayers();

  static const _rows = <(String, String, ArenaAvatarColor, String)>[
    ('🥇', 'KevinM_237', ArenaAvatarColor.blue, '38 500'),
    ('🥈', 'DianaA', ArenaAvatarColor.green, '29 200'),
    ('🥉', 'SamuelK', ArenaAvatarColor.cyan, '21 750'),
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
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ArenaSpacing.md,
                vertical: ArenaSpacing.sm,
              ),
              child: Row(
                children: [
                  Text(
                    _rows[i].$1,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 6),
                  ArenaAvatar(
                    initials: _rows[i].$2[0],
                    color: _rows[i].$3,
                    size: ArenaAvatarSize.sm,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(_rows[i].$2, style: ArenaText.body),
                  ),
                  Text(
                    _rows[i].$4,
                    style: ArenaText.mono.copyWith(
                      color: i == 0
                          ? SuperAdminDashboard._gold
                          : ArenaColors.bone,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (i < _rows.length - 1)
              const Divider(
                height: 1,
                color: ArenaColors.border,
              ),
          ],
        ],
      ),
    );
  }
}

class _CountryBreakdown extends StatelessWidget {
  const _CountryBreakdown();

  static const _rows = <(String, double, Color)>[
    ('🇨🇲 Cameroun', 0.48, ArenaColors.gameEfoot),
    ('🇸🇳 Sénégal', 0.22, ArenaColors.gameFifa),
    ("🇨🇮 Côte d'Ivoire", 0.15, ArenaColors.gameFc),
    ('🇧🇫 Burkina Faso', 0.08, ArenaColors.silver),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(color: ArenaColors.border),
      ),
      child: Column(
        children: [
          for (final (label, ratio, color) in _rows)
            Padding(
              padding: const EdgeInsets.only(bottom: ArenaSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(label, style: ArenaText.bodyMuted)),
                      Text(
                        '${(ratio * 100).round()}%',
                        style: ArenaText.mono,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 4,
                      backgroundColor: ArenaColors.carbon2,
                      valueColor: AlwaysStoppedAnimation(color),
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
