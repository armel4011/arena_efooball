// ════════════════════════════════════════════════════════════════════
// ARENA — Splash Screen (1er lancement) — 6.3s total
// ════════════════════════════════════════════════════════════════════
// Animation identique à `_ShortSplashScreen` (cf. splash_router.dart),
// seule la durée totale change : 6.3s ici, 3.5s pour les lancements
// suivants. Fade-in + scale 800ms, puis on laisse admirer le dégradé +
// chevrons jusqu'à T=6.3s avant d'appeler `onComplete`.
// ════════════════════════════════════════════════════════════════════

import 'dart:async';

import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    required this.onComplete,
    super.key,
    this.isAdmin = false,
  });

  final VoidCallback onComplete;
  final bool isAdmin;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.85, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _runSequence();
  }

  Future<void> _runSequence() async {
    unawaited(_controller.forward());
    // 6.3s total : 800ms fade-in + 5500ms admire avant transition.
    await Future<void>.delayed(const Duration(milliseconds: 6300));
    if (!mounted) return;
    widget.onComplete();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _accentColor =>
      widget.isAdmin ? const Color(0xFFFF2D55) : const Color(0xFF4C7AFF);
  Color get _midColor =>
      widget.isAdmin ? const Color(0xFF5C1A2D) : const Color(0xFF1A2D5C);
  Color get _chevronAccent =>
      widget.isAdmin ? const Color(0xFF4C7AFF) : const Color(0xFFFF2D55);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.55, 1.0],
            colors: [
              _accentColor,
              _midColor,
              const Color(0xFF0A0A0F),
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeIn,
            child: ScaleTransition(
              scale: _scale,
              child: SizedBox(
                width: 180,
                height: 180,
                child: CustomPaint(
                  painter: _ChevronPainter(chevronAccent: _chevronAccent),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChevronPainter extends CustomPainter {
  _ChevronPainter({required this.chevronAccent});
  final Color chevronAccent;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 1024.0;
    final whitePaint = Paint()..color = Colors.white;
    final accentPaint = Paint()..color = chevronAccent;
    final fainted = Paint()..color = Colors.white.withValues(alpha: 0.55);

    Path mkPath(int x1, int x2, int yTop, int yBottom, int yMid) {
      final tipX = x2 + (yMid - yTop);
      final innerTipX = x1 + (yMid - yTop);
      return Path()
        ..moveTo(x1 * scale, yTop * scale)
        ..lineTo(x2 * scale, yTop * scale)
        ..lineTo(tipX * scale, yMid * scale)
        ..lineTo(x2 * scale, yBottom * scale)
        ..lineTo(x1 * scale, yBottom * scale)
        ..lineTo(innerTipX * scale, yMid * scale)
        ..close();
    }

    canvas
      ..drawPath(mkPath(180, 340, 260, 580, 420), whitePaint)
      ..drawPath(mkPath(340, 480, 260, 580, 420), accentPaint)
      ..drawPath(mkPath(480, 620, 260, 580, 420), fainted);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
