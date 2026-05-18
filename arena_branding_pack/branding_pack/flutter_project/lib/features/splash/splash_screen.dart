// ════════════════════════════════════════════════════════════════════
// ARENA — Splash Screen Cinématique (Splash D)
// ════════════════════════════════════════════════════════════════════
// Animation 4 phases sur 3.5 secondes :
//   Phase 1 (0.0s → 1.0s)  → Spark central (point lumineux qui grandit)
//   Phase 2 (1.0s → 2.0s)  → Logo emerge avec rebond élastique
//   Phase 3 (2.0s → 2.8s)  → Tagline fade-in
//   Phase 4 (2.8s → 3.5s)  → 3 jeux supportés (cascade)
//   Phase 5 (3.5s → ...)   → Fade out vers la HomePage / LoginPage
//
// À placer dans : lib/features/splash/splash_screen.dart
// ════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Adapte selon ton import :
// import 'package:arena/core/theme/arena_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.onComplete,
    this.isAdmin = false,
  });

  /// Callback déclenché à la fin de l'animation.
  /// Utilise-le pour naviguer vers LoginPage ou HomePage.
  final VoidCallback onComplete;

  /// Si true, affiche la version ADMIN (rouge au lieu de bleu).
  final bool isAdmin;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Controllers pour chaque phase de l'animation
  late final AnimationController _sparkController;
  late final AnimationController _logoController;
  late final AnimationController _textController;
  late final AnimationController _gamesController;
  late final AnimationController _exitController;

  // Animations dérivées
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
    // ─── Phase 1 : Spark (0 → 1s) ──────────────────────────────────
    _sparkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _sparkScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.5).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.5, end: 4.0).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 4.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
    ]).animate(_sparkController);

    _sparkOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.6), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.6, end: 0.0), weight: 30),
    ]).animate(_sparkController);

    // ─── Phase 2 : Logo (1s → 2.2s) ────────────────────────────────
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.elasticOut, // effet rebond signature
      ),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    // ─── Phase 3 : Texte ARENA + tagline (2.2s → 3.0s) ─────────────
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );
    _textOffset = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );

    // ─── Phase 4 : Jeux supportés (3.0s → 3.5s) ────────────────────
    _gamesController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _gamesOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _gamesController, curve: Curves.easeOut),
    );
    _gamesOffset = Tween<Offset>(
      begin: const Offset(0, 0.8),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _gamesController, curve: Curves.easeOutCubic),
    );

    // ─── Phase 5 : Exit fade-out ──────────────────────────────────
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );
  }

  Future<void> _runSequence() async {
    // T=0s : Phase 1 spark démarre
    _sparkController.forward();

    // T=1.0s : Phase 2 logo démarre (chevauche un peu le spark pour fluidité)
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    _logoController.forward();

    // T=2.0s : Phase 3 texte démarre
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    _textController.forward();

    // T=2.8s : Phase 4 jeux démarrent
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    _gamesController.forward();

    // T=4.0s : Tout est affiché, on attend 500ms pour laisser admirer
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    // T=4.7s : Fade out
    await _exitController.forward();

    // T=5.3s : Navigation
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

  // ─── Couleurs selon le rôle ──────────────────────────────────────
  Color get _accentColor =>
      widget.isAdmin ? const Color(0xFFFF2D55) : const Color(0xFF4C7AFF);
  Color get _midColor =>
      widget.isAdmin ? const Color(0xFF5C1A2D) : const Color(0xFF1A2D5C);
  Color get _chevronAccent =>
      widget.isAdmin ? const Color(0xFF4C7AFF) : const Color(0xFFFF2D55);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _exitController,
      builder: (context, child) {
        return Opacity(
          opacity: _exitOpacity.value,
          child: Scaffold(
            body: Container(
              width: double.infinity,
              height: double.infinity,
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
                alignment: Alignment.center,
                children: [
                  // ─── Particules de fond (étoiles subtiles) ────────
                  _buildBackgroundStars(),

                  // ─── Contenu central ──────────────────────────────
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Spark + Logo (superposés)
                      SizedBox(
                        width: 200,
                        height: 200,
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Spark phase 1 ─────────────────────────────────────────────────
  Widget _buildSpark() {
    return AnimatedBuilder(
      animation: _sparkController,
      builder: (context, child) {
        return Opacity(
          opacity: _sparkOpacity.value,
          child: Transform.scale(
            scale: _sparkScale.value,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white,
                    blurRadius: 40,
                    spreadRadius: 8,
                  ),
                  BoxShadow(
                    color: _accentColor,
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

  // ─── Logo phase 2 ──────────────────────────────────────────────────
  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, child) {
        return Opacity(
          opacity: _logoOpacity.value,
          child: Transform.scale(
            scale: _logoScale.value,
            child: SizedBox(
              width: 180,
              height: 180,
              child: CustomPaint(
                painter: _ChevronLogoPainter(
                  chevronAccent: _chevronAccent,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Texte phase 3 ─────────────────────────────────────────────────
  Widget _buildTextSection() {
    return AnimatedBuilder(
      animation: _textController,
      builder: (context, child) {
        return SlideTransition(
          position: _textOffset,
          child: Opacity(
            opacity: _textOpacity.value,
            child: Column(
              children: [
                Text(
                  widget.isAdmin ? 'ADMIN' : 'ARENA',
                  style: GoogleFonts.bebasNeue(
                    fontSize: 44,
                    color: Colors.white,
                    letterSpacing: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "SEUL LE TALENT EST RÉCOMPENSÉ...",
                  style: GoogleFonts.instrumentSerif(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
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

  // ─── 3 jeux phase 4 ────────────────────────────────────────────────
  Widget _buildGamesRow() {
    return AnimatedBuilder(
      animation: _gamesController,
      builder: (context, child) {
        return SlideTransition(
          position: _gamesOffset,
          child: Opacity(
            opacity: _gamesOpacity.value,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                _GameBadge(label: 'EFB', color: Color(0xFF00B4D8)),
                SizedBox(width: 16),
                _GameBadge(label: 'FIFA', color: Color(0xFF06D6A0)),
                SizedBox(width: 16),
                _GameBadge(label: 'FC', color: Color(0xFFF77F00)),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Particules étoilées ───────────────────────────────────────────
  Widget _buildBackgroundStars() {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _logoController,
        builder: (context, child) {
          return Opacity(
            opacity: 0.3 + (_logoController.value * 0.4),
            child: CustomPaint(
              size: Size.infinite,
              painter: _StarsPainter(),
            ),
          );
        },
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// CHEVRONS LOGO PAINTER
// ════════════════════════════════════════════════════════════════════
class _ChevronLogoPainter extends CustomPainter {
  _ChevronLogoPainter({required this.chevronAccent});

  final Color chevronAccent;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 1024.0;

    // ─── Speed dots ────────────────────────────────────────────
    final dotsPaint = Paint()..color = Colors.white.withValues(alpha: 0.4);
    final dots = [
      (120, 340, 9),
      (95, 410, 11),
      (70, 480, 13),
      (95, 550, 11),
      (120, 620, 9),
    ];
    for (final dot in dots) {
      canvas.drawCircle(
        Offset(dot.$1 * scale, dot.$2 * scale),
        dot.$3 * scale,
        dotsPaint,
      );
    }

    // ─── Chevron 1 (blanc plein) ────────────────────────────────
    final whitePaint = Paint()..color = Colors.white;
    final chev1 = _chevronPath(scale, 180, 340, 260, 580, 420);
    canvas.drawPath(chev1, whitePaint);

    // ─── Chevron 2 (accent rouge ou bleu selon rôle) ───────────
    final accentPaint = Paint()..color = chevronAccent;
    final chev2 = _chevronPath(scale, 340, 480, 260, 580, 420);
    canvas.drawPath(chev2, accentPaint);

    // ─── Chevron 3 (blanc translucide) ──────────────────────────
    final whiteFainted = Paint()..color = Colors.white.withValues(alpha: 0.55);
    final chev3 = _chevronPath(scale, 480, 620, 260, 580, 420);
    canvas.drawPath(chev3, whiteFainted);
  }

  Path _chevronPath(double scale, int x1, int x2, int yTop, int yBottom, int yMid) {
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

// ════════════════════════════════════════════════════════════════════
// STARS PAINTER (particules de fond)
// ════════════════════════════════════════════════════════════════════
class _StarsPainter extends CustomPainter {
  // Positions fixes pour cohérence visuelle (pas de random à chaque rebuild)
  static const _positions = [
    (0.2, 0.3), (0.8, 0.6), (0.4, 0.8),
    (0.7, 0.2), (0.1, 0.6), (0.9, 0.9),
    (0.3, 0.5), (0.6, 0.4), (0.5, 0.15),
    (0.85, 0.45), (0.15, 0.85), (0.55, 0.7),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    for (final pos in _positions) {
      canvas.drawCircle(
        Offset(pos.$1 * size.width, pos.$2 * size.height),
        1.0,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ════════════════════════════════════════════════════════════════════
// GAME BADGE (mini icône jeu)
// ════════════════════════════════════════════════════════════════════
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
          style: GoogleFonts.bebasNeue(
            fontSize: 12,
            color: Colors.white,
            letterSpacing: 1,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
