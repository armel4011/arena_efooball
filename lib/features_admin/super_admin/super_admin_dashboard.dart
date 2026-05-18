import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/repositories/admin/super_admin_dashboard_repository.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// PHASE 11 · SA1 — super-admin global dashboard.
///
/// Lot B : branché sur les vraies données via 3 providers
/// (`superAdminKpisProvider`, `superAdminTopPlayersProvider`,
/// `superAdminCountryBreakdownProvider`). Les line / bar charts
/// d'évolution restent des placeholders en attendant `fl_chart`.
class SuperAdminDashboard extends ConsumerWidget {
  const SuperAdminDashboard({super.key});

  static const _gold = ArenaColors.tierGold;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpisAsync = ref.watch(superAdminKpisProvider);
    final topPlayersAsync = ref.watch(superAdminTopPlayersProvider);
    final countriesAsync = ref.watch(superAdminCountryBreakdownProvider);
    final monthLabel =
        DateFormat('LLLL yyyy', 'fr_FR').format(DateTime.now()).toUpperCase();

    return Scaffold(
      appBar: const ArenaAppBar(title: 'Super-admin', showBack: false),
      body: SafeArea(
        child: RefreshIndicator(
          color: ArenaColors.signalBlue,
          onRefresh: () async {
            ref
              ..invalidate(superAdminKpisProvider)
              ..invalidate(superAdminTopPlayersProvider)
              ..invalidate(superAdminCountryBreakdownProvider);
            await ref.read(superAdminKpisProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.all(ArenaSpacing.lg),
            children: [
              Text(
                'KPIs GLOBAUX · $monthLabel',
                style: ArenaText.inputLabel.copyWith(color: _gold),
              ),
              const SizedBox(height: ArenaSpacing.sm),
              _KpiRow(kpisAsync: kpisAsync),
              const SizedBox(height: ArenaSpacing.sm),
              _MarginCard(kpisAsync: kpisAsync),
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
              _TopPlayers(async: topPlayersAsync),
              const SizedBox(height: ArenaSpacing.lg),
              Text('🌍 Répartition pays', style: ArenaText.h3),
              const SizedBox(height: ArenaSpacing.sm),
              _CountryBreakdown(async: countriesAsync),
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
                      'Sentry events surveillés via le dashboard externe '
                      '(`sentry.io/arena`). Aucune intégration in-app V1.',
                      style: ArenaText.bodyMuted,
                    ),
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

class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.kpisAsync});
  final AsyncValue<SuperAdminKpis> kpisAsync;

  @override
  Widget build(BuildContext context) {
    return kpisAsync.when(
      data: (k) => Row(
        children: [
          Expanded(
            child: _Tile(
              value: _intLabel(k.active30d),
              label: 'MAU',
              border: SuperAdminDashboard._gold,
              valueColor: SuperAdminDashboard._gold,
            ),
          ),
          const SizedBox(width: ArenaSpacing.sm),
          Expanded(child: _Tile(value: _intLabel(k.active24h), label: 'DAU')),
          const SizedBox(width: ArenaSpacing.sm),
          Expanded(
            child: _Tile(
              value: '${k.dauMauRatio.toStringAsFixed(1)}%',
              label: 'DAU/MAU',
              valueColor: ArenaColors.statusOk,
            ),
          ),
        ],
      ),
      loading: () => const Row(
        children: [
          Expanded(child: _Tile(value: '…', label: 'MAU')),
          SizedBox(width: ArenaSpacing.sm),
          Expanded(child: _Tile(value: '…', label: 'DAU')),
          SizedBox(width: ArenaSpacing.sm),
          Expanded(child: _Tile(value: '…', label: 'DAU/MAU')),
        ],
      ),
      error: (e, _) => Text(
        'KPIs indisponibles : $e',
        style: ArenaText.body.copyWith(color: ArenaColors.neonRed),
      ),
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
  const _MarginCard({required this.kpisAsync});
  final AsyncValue<SuperAdminKpis> kpisAsync;

  @override
  Widget build(BuildContext context) {
    final value = kpisAsync.maybeWhen(
      data: (k) => _moneyShort(k.margin30dXaf),
      orElse: () => '—',
    );
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
            '$value XAF',
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
  const _TopPlayers({required this.async});
  final AsyncValue<List<TopPlayerEntry>> async;

  static const _avatarColors = <String, ArenaAvatarColor>{
    '#4C7AFF': ArenaAvatarColor.blue,
    '#FF2D55': ArenaAvatarColor.red,
    '#00C896': ArenaAvatarColor.green,
    '#F77F00': ArenaAvatarColor.orange,
    '#00B4D8': ArenaAvatarColor.cyan,
    '#9D4EDD': ArenaAvatarColor.purple,
    '#FF6B9D': ArenaAvatarColor.pink,
    '#FFD700': ArenaAvatarColor.yellow,
  };

  static ArenaAvatarColor _colorFromHex(String hex) =>
      _avatarColors[hex.toUpperCase()] ?? ArenaAvatarColor.blue;

  @override
  Widget build(BuildContext context) {
    return async.when(
      data: (players) {
        if (players.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(ArenaSpacing.md),
            decoration: BoxDecoration(
              color: ArenaColors.carbon,
              borderRadius: BorderRadius.circular(ArenaRadius.lg),
              border: Border.all(color: ArenaColors.border),
            ),
            child: Text(
              "Aucun joueur classé pour l'instant.",
              style: ArenaText.bodyMuted,
            ),
          );
        }
        return Container(
          decoration: BoxDecoration(
            color: ArenaColors.carbon,
            borderRadius: BorderRadius.circular(ArenaRadius.lg),
            border: Border.all(color: ArenaColors.border),
          ),
          child: Column(
            children: [
              for (var i = 0; i < players.length; i++) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ArenaSpacing.md,
                    vertical: ArenaSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Text(
                        _medalFor(i),
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 6),
                      ArenaAvatar(
                        initials: players[i].username[0],
                        color: _colorFromHex(players[i].avatarColor),
                        size: ArenaAvatarSize.sm,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(players[i].username, style: ArenaText.body),
                      ),
                      Text(
                        '${players[i].wins} V',
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
                if (i < players.length - 1)
                  const Divider(
                    height: 1,
                    color: ArenaColors.border,
                  ),
              ],
            ],
          ),
        );
      },
      loading: () => const _LoadingTile(label: 'Chargement top joueurs…'),
      error: (e, _) => _ErrorTile(message: 'Top joueurs : $e'),
    );
  }

  static String _medalFor(int index) {
    switch (index) {
      case 0:
        return '🥇';
      case 1:
        return '🥈';
      case 2:
        return '🥉';
      default:
        return '${index + 1}.';
    }
  }
}

class _CountryBreakdown extends StatelessWidget {
  const _CountryBreakdown({required this.async});
  final AsyncValue<List<CountryShare>> async;

  static String _flagFor(String code) {
    if (code.length != 2) return '🌍';
    const base = 0x1F1E6;
    return String.fromCharCodes([
      base + code.codeUnitAt(0) - 65,
      base + code.codeUnitAt(1) - 65,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return async.when(
      data: (rows) {
        if (rows.isEmpty) {
          return const _ErrorTile(
            message: 'Aucune répartition pays disponible.',
            isError: false,
          );
        }
        final colors = <Color>[
          ArenaColors.gameEfoot,
          ArenaColors.gameFifa,
          ArenaColors.gameFc,
          ArenaColors.silver,
          ArenaColors.signalBlue,
        ];
        return Container(
          padding: const EdgeInsets.all(ArenaSpacing.md),
          decoration: BoxDecoration(
            color: ArenaColors.carbon,
            borderRadius: BorderRadius.circular(ArenaRadius.lg),
            border: Border.all(color: ArenaColors.border),
          ),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: ArenaSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${_flagFor(rows[i].countryCode)} '
                              '${rows[i].countryCode}',
                              style: ArenaText.bodyMuted,
                            ),
                          ),
                          Text(
                            '${(rows[i].ratio * 100).round()}%',
                            style: ArenaText.mono,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: rows[i].ratio.clamp(0, 1).toDouble(),
                          minHeight: 4,
                          backgroundColor: ArenaColors.carbon2,
                          valueColor: AlwaysStoppedAnimation(
                            colors[i % colors.length],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const _LoadingTile(label: 'Chargement pays…'),
      error: (e, _) => _ErrorTile(message: 'Pays : $e'),
    );
  }
}

class _LoadingTile extends StatelessWidget {
  const _LoadingTile({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(color: ArenaColors.border),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: ArenaColors.signalBlue,
            ),
          ),
          const SizedBox(width: ArenaSpacing.sm),
          Text(label, style: ArenaText.bodyMuted),
        ],
      ),
    );
  }
}

class _ErrorTile extends StatelessWidget {
  const _ErrorTile({required this.message, this.isError = true});
  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(
          color: isError ? ArenaColors.neonRed : ArenaColors.border,
        ),
      ),
      child: Text(
        message,
        style: ArenaText.body.copyWith(
          color: isError ? ArenaColors.neonRed : ArenaColors.silver,
        ),
      ),
    );
  }
}

/// Helpers de formatage.
String _intLabel(int n) {
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}

String _moneyShort(double xaf) {
  if (xaf.abs() >= 1000000) {
    return '${(xaf / 1000000).toStringAsFixed(1)}M';
  }
  if (xaf.abs() >= 1000) {
    return '${(xaf / 1000).toStringAsFixed(1)}K';
  }
  return xaf.round().toString();
}
