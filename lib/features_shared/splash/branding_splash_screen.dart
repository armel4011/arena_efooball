// Cold-start cinematic splash screen — branding pack 2026-05-18.
//
// 5 phases sur 5.3s :
//   T=0.0 → 1.0s : ⚡ spark central qui grandit + halo coloré
//   T=1.0 → 2.2s : 🎯 logo chevrons emerge (elasticOut)
//   T=2.2 → 3.0s : 📝 texte ARENA/ADMIN + tagline italique fade-in
//   T=3.0 → 3.8s : 🎮 3 jeux supportés (EFB / FIFA / FC) en cascade
//   T=3.8 → 4.7s : 🌫 fade-out global + callback `onComplete`
//
// Adaptations vs. pack original :
//   * tokens ArenaColors (userMid/adminMid) + ArenaText.hero/serifTagline
//   * GameBadge utilise ArenaColors.gameEfoot/gameFifa/gameFc
//   * Callback synchronous (pas de Navigator) — wrapper appelle context.go
//     via GoRouter (cf. branding_splash_page.dart).

import 'dart:async';

import 'package:arena/core/theme/arena_theme.dart';
import 'package:flutter/material.dart';

class BrandingSplashScreen extends StatefulWidget {
  const BrandingSplashScreen({
    required this.onComplete,
    super.key,
    this.isAdmin = false,
  });

  final VoidCallback onComplete;
  final bool isAdmin;

  @override
  State<BrandingSplashScreen> createState() => _BrandingSplashScreenState();
}

class _BrandingSplashScreenState extends State<BrandingSplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _sparkController;
  late final AnimationController _logoController;
  late final AnimationController _textController;
  late final AnimationController _gamesController;
  late final AnimationController _exitController;

  late final Animation<double> _sparkScale;
  late final Animation<double> _sparkOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textOffset;
  late final Animation<double> _gamesOpacity;
  late final Animation<Offset> _gamesOffset;
  late final Animation<double> _exitOpacity;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _runSequence();
  }

  void _initAnimations() {
    _sparkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _sparkScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 1.5)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.5, end: 4)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 4, end: 0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
    ]).animate(_sparkController);

    _sparkOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 1),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1, end: 0.6),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.6, end: 0),
        weight: 30,
      ),
    ]).animate(_sparkController);

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _logoScale = Tween<double>(begin: 0.5, end: 1).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0, 0.4, curve: Curves.easeOut),
      ),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _textOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );
    _textOffset = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );

    _gamesController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _gamesOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _gamesController, curve: Curves.easeOut),
    );
    _gamesOffset = Tween<Offset>(
      begin: const Offset(0, 0.8),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _gamesController, curve: Curves.easeOutCubic),
    );

    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _exitOpacity = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );
  }

  Future<void> _runSequence() async {
    unawaited(_sparkController.forward());

    await Future<void>.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    unawaited(_logoController.forward());

    await Future<void>.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    unawaited(_textController.forward());

    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    unawaited(_gamesController.forward());

    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    await _exitController.forward();
    if (!mounted) return;
    widget.onComplete();
  }

  @override
  void dispose() {
    _sparkController.dispose();
    _logoController.dispose();
    _textController.dispose();
    _gamesController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  Color get _accentColor =>
      widget.isAdmin ? ArenaColors.neonRed : ArenaColors.signalBlue;
  Color get _midColor =>
      widget.isAdmin ? ArenaColors.adminMid : ArenaColors.userMid;
  Color get _chevronAccent =>
      widget.isAdmin ? ArenaColors.signalBlue : ArenaColors.neonRed;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _exitController,
      builder: (context, _) {
        return Opacity(
          opacity: _exitOpacity.value,
          child: Scaffold(
            body: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: const [0, 0.55, 1],
                  colors: [_accentColor, _midColor, ArenaColors.void_],
                ),
              ),
              child: SizedBox.expand(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _BackgroundStars(controller: _logoController),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 200,
                          height: 200,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              _Spark(
                                controller: _sparkController,
                                scale: _sparkScale,
                                opacity: _sparkOpacity,
                                accentColor: _accentColor,
                              ),
                              _Logo(
                                controller: _logoController,
                                scale: _logoScale,
                                opacity: _logoOpacity,
                                chevronAccent: _chevronAccent,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: ArenaSpacing.lg),
                        _TextSection(
                          controller: _textController,
                          opacity: _textOpacity,
                          offset: _textOffset,
                          isAdmin: widget.isAdmin,
                        ),
                        const SizedBox(height: ArenaSpacing.xl),
                        _GamesRow(
                          controller: _gamesController,
                          opacity: _gamesOpacity,
                          offset: _gamesOffset,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Spark extends StatelessWidget {
  const _Spark({
    required this.controller,
    required this.scale,
    required this.opacity,
    required this.accentColor,
  });

  final AnimationController controller;
  final Animation<double> scale;
  final Animation<double> opacity;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Opacity(
          opacity: opacity.value,
          child: Transform.scale(
            scale: scale.value,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  const BoxShadow(
                    color: Colors.white,
                    blurRadius: 40,
                    spreadRadius: 8,
                  ),
                  BoxShadow(
                    color: accentColor,
                    blurRadius: 80,
                    spreadRadius: 16,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({
    required this.controller,
    required this.scale,
    required this.opacity,
    required this.chevronAccent,
  });

  final AnimationController controller;
  final Animation<double> scale;
  final Animation<double> opacity;
  final Color chevronAccent;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Opacity(
          opacity: opacity.value,
          child: Transform.scale(
            scale: scale.value,
            child: SizedBox(
              width: 180,
              height: 180,
              child: CustomPaint(
                painter: _ChevronLogoPainter(chevronAccent: chevronAccent),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TextSection extends StatelessWidget {
  const _TextSection({
    required this.controller,
    required this.opacity,
    required this.offset,
    required this.isAdmin,
  });

  final AnimationController controller;
  final Animation<double> opacity;
  final Animation<Offset> offset;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return SlideTransition(
          position: offset,
          child: Opacity(
            opacity: opacity.value,
            child: Column(
              children: [
                Text(
                  isAdmin ? 'ADMIN' : 'ARENA',
                  style: ArenaText.hero.copyWith(fontSize: 44),
                ),
                const SizedBox(height: ArenaSpacing.xs),
                Text(
                  isAdmin
                      ? 'CONSOLE DE GESTION ARENA'
                      : 'SEUL LE TALENT EST RÉCOMPENSÉ...',
                  style: ArenaText.serifTagline.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GamesRow extends StatelessWidget {
  const _GamesRow({
    required this.controller,
    required this.opacity,
    required this.offset,
  });

  final AnimationController controller;
  final Animation<double> opacity;
  final Animation<Offset> offset;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return SlideTransition(
          position: offset,
          child: Opacity(
            opacity: opacity.value,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _GameBadge(label: 'EFB', color: ArenaColors.gameEfoot),
                SizedBox(width: ArenaSpacing.md),
                _GameBadge(label: 'FIFA', color: ArenaColors.gameFifa),
                SizedBox(width: ArenaSpacing.md),
                _GameBadge(label: 'FC', color: ArenaColors.gameFc),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BackgroundStars extends StatelessWidget {
  const _BackgroundStars({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return Opacity(
            opacity: 0.3 + (controller.value * 0.4),
            child: const CustomPaint(
              size: Size.infinite,
              painter: _StarsPainter(),
            ),
          );
        },
      ),
    );
  }
}

class _GameBadge extends StatelessWidget {
  const _GameBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          label,
          style: ArenaText.hero.copyWith(
            fontSize: 12,
            letterSpacing: 1,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ChevronLogoPainter extends CustomPainter {
  _ChevronLogoPainter({required this.chevronAccent});

  final Color chevronAccent;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 1024.0;

    final dotsPaint = Paint()..color = Colors.white.withValues(alpha: 0.4);
    const dots = [
      (120, 340, 9),
      (95, 410, 11),
      (70, 480, 13),
      (95, 550, 11),
      (120, 620, 9),
    ];
    for (final (x, y, r) in dots) {
      canvas.drawCircle(Offset(x * scale, y * scale), r * scale, dotsPaint);
    }

    final whitePaint = Paint()..color = Colors.white;
    canvas.drawPath(_chevronPath(scale, 180, 340, 260, 580, 420), whitePaint);

    final accentPaint = Paint()..color = chevronAccent;
    canvas.drawPath(
      _chevronPath(scale, 340, 480, 260, 580, 420),
      accentPaint,
    );

    final faintPaint = Paint()..color = Colors.white.withValues(alpha: 0.55);
    canvas.drawPath(_chevronPath(scale, 480, 620, 260, 580, 420), faintPaint);
  }

  Path _chevronPath(
    double scale,
    int x1,
    int x2,
    int yTop,
    int yBottom,
    int yMid,
  ) {
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

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StarsPainter extends CustomPainter {
  const _StarsPainter();

  // Positions fixes pour cohérence visuelle (pas de random à chaque rebuild).
  static const _positions = [
    (0.2, 0.3),
    (0.8, 0.6),
    (0.4, 0.8),
    (0.7, 0.2),
    (0.1, 0.6),
    (0.9, 0.9),
    (0.3, 0.5),
    (0.6, 0.4),
    (0.5, 0.15),
    (0.85, 0.45),
    (0.15, 0.85),
    (0.55, 0.7),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    for (final (x, y) in _positions) {
      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        1,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
