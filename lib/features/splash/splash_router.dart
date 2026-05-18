// ════════════════════════════════════════════════════════════════════
// ARENA — Splash Router Wrapper
// ════════════════════════════════════════════════════════════════════
// Gère la navigation post-splash :
//   - Si premier lancement → SplashScreen cinématique 5.3s
//     (5 phases, matche splash_preview.html)
//   - Sinon → Splash court 2.5s (fade+scale chevrons + 3 game badges)
//
// Détecte le premier lancement via SharedPreferences (clé
// `has_seen_splash_v1`). Utilise GoRouter via `context.go(nextRoute)`.
// ════════════════════════════════════════════════════════════════════

import 'dart:async';

import 'package:arena/features/splash/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ════════════════════════════════════════════════════════════════════
// PROVIDER : a-t-on déjà vu le splash complet ?
// ════════════════════════════════════════════════════════════════════
final firstLaunchProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final hasSeen = prefs.getBool('has_seen_splash_v1') ?? false;
  if (!hasSeen) {
    // Marquer comme vu pour les prochaines fois
    await prefs.setBool('has_seen_splash_v1', true);
    return true; // c'est le premier lancement
  }
  return false;
});

// ════════════════════════════════════════════════════════════════════
// PAGE WRAPPER
// ════════════════════════════════════════════════════════════════════
class SplashPage extends ConsumerWidget {
  const SplashPage({
    super.key,
    this.isAdmin = false,
    this.nextRoute = '/login',
  });

  final bool isAdmin;
  final String nextRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firstLaunchAsync = ref.watch(firstLaunchProvider);

    return firstLaunchAsync.when(
      // Pendant qu'on lit SharedPreferences (instantané sur device réel)
      loading: () => _SplashLoadingState(isAdmin: isAdmin),

      // En cas d'erreur (très rare), on affiche le splash complet par sécurité
      error: (e, st) => SplashScreen(
        isAdmin: isAdmin,
        onComplete: () => _navigate(context),
      ),

      // Cas normal : on sait si c'est le 1er lancement
      data: (isFirstLaunch) {
        if (isFirstLaunch) {
          // Splash D cinématique 5.3s (1er lancement uniquement).
          return SplashScreen(
            isAdmin: isAdmin,
            onComplete: () => _navigate(context),
          );
        } else {
          // Splash court 2.5s — lancements suivants.
          return _ShortSplashScreen(
            isAdmin: isAdmin,
            onComplete: () => _navigate(context),
          );
        }
      },
    );
  }

  void _navigate(BuildContext context) {
    if (!context.mounted) return;
    context.go(nextRoute);
  }
}

// ════════════════════════════════════════════════════════════════════
// SPLASH COURT (2.5 secondes — lancements suivants)
// Fade+scale chevrons + 3 game badges en dessous, animés ensemble.
// ════════════════════════════════════════════════════════════════════
class _ShortSplashScreen extends StatefulWidget {
  const _ShortSplashScreen({
    required this.isAdmin,
    required this.onComplete,
  });

  final bool isAdmin;
  final VoidCallback onComplete;

  @override
  State<_ShortSplashScreen> createState() => _ShortSplashScreenState();
}

class _ShortSplashScreenState extends State<_ShortSplashScreen>
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
    // 2.5s total : 800ms fade-in + 1700ms admire avant transition.
    await Future<void>.delayed(const Duration(milliseconds: 2500));
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 180,
                    height: 180,
                    child: CustomPaint(
                      painter:
                          _ChevronShortPainter(chevronAccent: _chevronAccent),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const GamesRow(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChevronShortPainter extends CustomPainter {
  _ChevronShortPainter({required this.chevronAccent});
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

// ════════════════════════════════════════════════════════════════════
// SPLASH LOADING (transition entre native splash et widget splash)
// ════════════════════════════════════════════════════════════════════
// Affiché pendant les ~50ms où on lit SharedPreferences.
// Identique au fond pour éviter un flash blanc.
class _SplashLoadingState extends StatelessWidget {
  const _SplashLoadingState({required this.isAdmin});
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final accentColor =
        isAdmin ? const Color(0xFFFF2D55) : const Color(0xFF4C7AFF);
    final midColor =
        isAdmin ? const Color(0xFF5C1A2D) : const Color(0xFF1A2D5C);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.55, 1.0],
            colors: [
              accentColor,
              midColor,
              const Color(0xFF0A0A0F),
            ],
          ),
        ),
      ),
    );
  }
}
