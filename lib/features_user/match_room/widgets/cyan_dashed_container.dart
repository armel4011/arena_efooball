import 'package:arena/core/theme/arena_theme.dart';
import 'package:flutter/material.dart';

/// Container avec bordure pointillée cyan + fond cyan 5%, utilisé pour
/// encadrer les zones "code room" du match flow. Partagé entre
/// ShareCodeForm, RoomReadyView et CodeSharedInterstitial.
class CyanDashedContainer extends StatelessWidget {
  const CyanDashedContainer({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: ArenaColors.gameEfoot,
        radius: ArenaRadius.lg,
      ),
      child: Container(
        padding: const EdgeInsets.all(ArenaSpacing.lg),
        decoration: BoxDecoration(
          color: ArenaColors.gameEfoot.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(ArenaRadius.lg),
        ),
        child: child,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rect);
    final dashed = _dashPath(path, dashLength: 6, gapLength: 4);
    canvas.drawPath(dashed, paint);
  }

  Path _dashPath(
    Path source, {
    required double dashLength,
    required double gapLength,
  }) {
    final dest = Path();
    for (final metric in source.computeMetrics()) {
      double dist = 0;
      while (dist < metric.length) {
        dest.addPath(
          metric.extractPath(dist, dist + dashLength),
          Offset.zero,
        );
        dist += dashLength + gapLength;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}
