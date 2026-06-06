import 'package:arena/core/theme/arena_theme.dart';
import 'package:flutter/material.dart';

/// Fond atmosphérique premium des écrans Arena.
///
/// Pose un `RadialGradient` subtil (accent à 10 % au centre haut → `void_`
/// à 70 %) sur toute la zone disponible, donnant la teinte « magazine
/// sportif » du mockup premium. Utilisé sur les écrans auth, hero, et
/// toute page qui veut un appel visuel sans surcharger le contenu.
///
/// L'accent par défaut est `signalBlue` (cohérent avec splash + onboarding) ;
/// passer un autre accent (`neonRed` pour les pages admin, `gameEfoot` /
/// `gameDraughts` / `gameFc` pour les détails compétition, etc.) sans toucher
/// au reste du layout.
class ArenaScreenBackground extends StatelessWidget {
  const ArenaScreenBackground({
    required this.child,
    this.accent = ArenaColors.signalBlue,
    this.intensity = 0.10,
    this.center = const Alignment(0, -0.4),
    this.radius = 0.9,
    super.key,
  });

  final Widget child;
  final Color accent;
  final double intensity;
  final Alignment center;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: center,
          radius: radius,
          colors: [
            accent.withValues(alpha: intensity),
            ArenaColors.void_,
          ],
          stops: const [0, 0.7],
        ),
      ),
      child: child,
    );
  }
}
