// ════════════════════════════════════════════════════════════════════
// ARENA — Splash Screen Cinématique — 5.3s (matche splash_preview.html)
// ════════════════════════════════════════════════════════════════════
// Reproduit fidèlement l'animation HTML du branding pack
// (`arena_branding_pack/branding_pack/previews/splash_preview.html`).
//
// Timeline (% du total 5300ms) :
//   0-10  : Phase 1 — Spark (point lumineux qui grandit + glow)
//   19-32 : Phase 2 — Logo SVG (chevrons + speed dots, scale bounce)
//   38-47 : Phase 3 — Texte ARENA + tagline (slide-up + fade)
//   53-62 : Phase 4 — 3 game badges (slide-up + fade en cascade)
//   85-100: Phase 5 — Fade out de tout (préparation au navigate)
// Background stars : opacity 0→0.3→0.7→0.7→0 sur toute la durée.
// ════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  late final AnimationController _ctrl;
  late final Animation<double> _starsOpacity;
  late final Animation<double> _sparkScale;
  late final Animation<double> _sparkOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _textOpacity;
  late final Animation<double> _textTranslateY;
  late final Animation<double> _gamesOpacity;
  late final Animation<double> _gamesTranslateY;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5300),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          widget.onComplete();
        }
      });

    // ─── Stars background : 0→0.3 (30%) → 0.7 (70%) → 0.7 (90%) → 0 (100%)
    _starsOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: 0.3), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 0.3, end: 0.7), weight: 40),
      TweenSequenceItem(tween: ConstantTween<double>(0.7), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 0.7, end: 0), weight: 10),
    ]).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );

    // ─── Spark : scale 0→0→1.5→4→0, opacity 0→0→1→0.6→0 (0-25%)
    _sparkScale = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0), weight: 5),
      TweenSequenceItem(tween: ConstantTween<double>(0), weight: 5),
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: 1.5), weight: 5),
      TweenSequenceItem(tween: Tween<double>(begin: 1.5, end: 4), weight: 8),
      TweenSequenceItem(tween: Tween<double>(begin: 4, end: 0), weight: 7),
      TweenSequenceItem(tween: ConstantTween<double>(0), weight: 70),
    ]).animate(_ctrl);

    _sparkOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0), weight: 5),
      TweenSequenceItem(tween: ConstantTween<double>(0), weight: 5),
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: 1), weight: 5),
      TweenSequenceItem(tween: Tween<double>(begin: 1, end: 0.6), weight: 8),
      TweenSequenceItem(tween: Tween<double>(begin: 0.6, end: 0), weight: 7),
      TweenSequenceItem(tween: ConstantTween<double>(0), weight: 70),
    ]).animate(_ctrl);

    // ─── Logo : scale 0.5→0.9→1.1→1.0 (bounce, 19-32%), persist, exit 85-100% → 0.95
    _logoScale = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0.5), weight: 19),
      TweenSequenceItem(tween: Tween<double>(begin: 0.5, end: 0.9), weight: 4),
      TweenSequenceItem(tween: Tween<double>(begin: 0.9, end: 1.1), weight: 5),
      TweenSequenceItem(tween: Tween<double>(begin: 1.1, end: 1), weight: 4),
      TweenSequenceItem(tween: ConstantTween<double>(1), weight: 53),
      TweenSequenceItem(tween: Tween<double>(begin: 1, end: 0.95), weight: 15),
    ]).animate(_ctrl);

    // Logo opacity : 0 (0-19%) → 0.5 (23%) → 1 (28%) → settle → 0 (100%)
    _logoOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0), weight: 19),
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: 0.5), weight: 4),
      TweenSequenceItem(tween: Tween<double>(begin: 0.5, end: 1), weight: 5),
      TweenSequenceItem(tween: ConstantTween<double>(1), weight: 57),
      TweenSequenceItem(tween: Tween<double>(begin: 1, end: 0), weight: 15),
    ]).animate(_ctrl);

    // ─── Text section : opacity 0→1 (38-47%), translateY 20→0, exit 85-100%
    _textOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0), weight: 38),
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: 1), weight: 9),
      TweenSequenceItem(tween: ConstantTween<double>(1), weight: 38),
      TweenSequenceItem(tween: Tween<double>(begin: 1, end: 0), weight: 15),
    ]).animate(_ctrl);

    _textTranslateY = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(20), weight: 38),
      TweenSequenceItem(tween: Tween<double>(begin: 20, end: 0), weight: 9),
      TweenSequenceItem(tween: ConstantTween<double>(0), weight: 38),
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: -10), weight: 15),
    ]).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );

    // ─── Games row : opacity 0→1 (53-62%), translateY 20→0, exit 85-100%
    _gamesOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0), weight: 53),
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: 1), weight: 9),
      TweenSequenceItem(tween: ConstantTween<double>(1), weight: 23),
      TweenSequenceItem(tween: Tween<double>(begin: 1, end: 0), weight: 15),
    ]).animate(_ctrl);

    _gamesTranslateY = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(20), weight: 53),
      TweenSequenceItem(tween: Tween<double>(begin: 20, end: 0), weight: 9),
      TweenSequenceItem(tween: ConstantTween<double>(0), weight: 23),
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: -10), weight: 15),
    ]).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ─── Couleurs USER/ADMIN ──────────────────────────────────────────
  Color get _accentColor =>
      widget.isAdmin ? const Color(0xFFFF2D55) : const Color(0xFF4C7AFF);
  Color get _midColor =>
      widget.isAdmin ? const Color(0xFF5C1A2D) : const Color(0xFF1A2D5C);
  Color get _chevronAccent =>
      widget.isAdmin ? const Color(0xFF4C7AFF) : const Color(0xFFFF2D55);

  String get _brand => widget.isAdmin ? 'ADMIN' : 'ARENA';
  String get _tagline => widget.isAdmin
      ? 'CONSOLE DE GESTION ARENA'
      : 'SEUL LE TALENT EST RÉCOMPENSÉ...';

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
        child: Stack(
          children: [
            // ─── Background stars ───────────────────────────────────
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _starsOpacity,
                builder: (context, _) => Opacity(
                  opacity: _starsOpacity.value.clamp(0.0, 1.0),
                  child: const _BackgroundStars(),
                ),
              ),
            ),

            // ─── Centre : logo + texte + games ──────────────────────
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo + spark (superposés via Stack 220x220)
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        _buildSpark(),
                        _buildLogo(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildTextSection(),
                  const SizedBox(height: 32),
                  _buildGamesRow(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Spark phase 1 ───────────────────────────────────────────────
  Widget _buildSpark() {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Opacity(
          opacity: _sparkOpacity.value.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: _sparkScale.value,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  const BoxShadow(color: Colors.white, blurRadius: 40),
                  BoxShadow(color: _accentColor, blurRadius: 80),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Logo phase 2 ────────────────────────────────────────────────
  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Opacity(
          opacity: _logoOpacity.value.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: _logoScale.value,
            child: CustomPaint(
              size: const Size(180, 180),
              painter: _LogoPainter(chevronAccent: _chevronAccent),
            ),
          ),
        );
      },
    );
  }

  // ─── Text phase 3 ────────────────────────────────────────────────
  Widget _buildTextSection() {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Opacity(
          opacity: _textOpacity.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, _textTranslateY.value),
            child: Column(
              children: [
                Text(
                  _brand,
                  style: GoogleFonts.bebasNeue(
                    fontSize: 44,
                    letterSpacing: 8,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _tagline,
                  style: GoogleFonts.instrumentSerif(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 1.5,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Games phase 4 ───────────────────────────────────────────────
  Widget _buildGamesRow() {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Opacity(
          opacity: _gamesOpacity.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, _gamesTranslateY.value),
            child: const GamesRow(),
          ),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// LOGO PAINTER — 5 speed dots à gauche + 3 chevrons (white, accent, faded)
// ════════════════════════════════════════════════════════════════════
// Reproduit fidèlement le SVG du HTML (viewBox 1024 → painter 180x180).
class _LogoPainter extends CustomPainter {
  _LogoPainter({required this.chevronAccent});
  final Color chevronAccent;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 1024.0;

    // Speed dots (5 cercles blancs à gauche, opacity 0.4)
    final dotPaint = Paint()..color = Colors.white.withValues(alpha: 0.4);
    const dots = <List<double>>[
      [120, 340, 9],
      [95, 410, 11],
      [70, 480, 13],
      [95, 550, 11],
      [120, 620, 9],
    ];
    for (final d in dots) {
      canvas.drawCircle(Offset(d[0] * s, d[1] * s), d[2] * s, dotPaint);
    }

    // Chevrons (3 polygons)
    Path polygon(List<List<double>> pts) {
      final p = Path()..moveTo(pts[0][0] * s, pts[0][1] * s);
      for (var i = 1; i < pts.length; i++) {
        p.lineTo(pts[i][0] * s, pts[i][1] * s);
      }
      p.close();
      return p;
    }

    canvas
      ..drawPath(
        polygon(const [
          [180, 260], [340, 260], [540, 420],
          [340, 580], [180, 580], [380, 420],
        ]),
        Paint()..color = Colors.white,
      )
      ..drawPath(
        polygon(const [
          [340, 260], [480, 260], [680, 420],
          [480, 580], [340, 580], [540, 420],
        ]),
        Paint()..color = chevronAccent,
      )
      ..drawPath(
        polygon(const [
          [480, 260], [620, 260], [820, 420],
          [620, 580], [480, 580], [680, 420],
        ]),
        Paint()..color = Colors.white.withValues(alpha: 0.55),
      );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ════════════════════════════════════════════════════════════════════
// GAMES ROW — 3 badges EFB / FIFA / FC, partagé entre cinematic et short
// ════════════════════════════════════════════════════════════════════
class GamesRow extends StatelessWidget {
  const GamesRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GameBadge(label: 'EFB', color: Color(0xFF00B4D8)),
        SizedBox(width: 16),
        GameBadge(label: 'FIFA', color: Color(0xFF06D6A0)),
        SizedBox(width: 16),
        GameBadge(label: 'FC', color: Color(0xFFF77F00)),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// GAME BADGE — 48x48 rounded 12, glow par couleur
// ════════════════════════════════════════════════════════════════════
class GameBadge extends StatelessWidget {
  const GameBadge({required this.label, required this.color, super.key});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
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
          style: GoogleFonts.bebasNeue(
            fontSize: 12,
            color: Colors.white,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// BACKGROUND STARS — 9 cercles 1px aux positions fixes du HTML
// ════════════════════════════════════════════════════════════════════
class _BackgroundStars extends StatelessWidget {
  const _BackgroundStars();

  // Positions normalisées 0..1 (du CSS radial-gradient du HTML).
  static const _positions = <Offset>[
    Offset(0.20, 0.30),
    Offset(0.80, 0.60),
    Offset(0.40, 0.80),
    Offset(0.70, 0.20),
    Offset(0.10, 0.60),
    Offset(0.90, 0.90),
    Offset(0.30, 0.50),
    Offset(0.60, 0.35),
    Offset(0.50, 0.15),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) => Stack(
        children: [
          for (final p in _positions)
            Positioned(
              left: p.dx * c.maxWidth,
              top: p.dy * c.maxHeight,
              child: Container(
                width: 2,
                height: 2,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
