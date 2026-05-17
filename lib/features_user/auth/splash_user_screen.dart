import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

/// Pre-auth landing — full-bleed ARENA logo (ShaderMask gradient) + 3-col
/// stats teaser + 2 CTAs.
///
/// Maps to the splash section of `arena_v2.html`. The hero logo uses
/// [ArenaLogo] (60 px Bebas Neue with the brand blue→red gradient and a soft
/// blue glow). Cascade fade-in: logo → tagline → stats → CTAs.
class SplashUserScreen extends StatelessWidget {
  const SplashUserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArenaColors.void_,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.2),
            radius: 0.9,
            colors: [
              ArenaColors.signalBlue.withValues(alpha: 0.15),
              ArenaColors.void_,
            ],
            stops: const [0, 0.7],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(ArenaSpacing.xl),
            child: Column(
              children: [
                const Spacer(flex: 3),
                const ArenaLogo()
                    .animate()
                    .fadeIn(duration: ArenaDurations.long)
                    .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
                const SizedBox(height: 6),
                Text(
                  'e-sport panafricain',
                  style: ArenaText.serifTagline,
                  textAlign: TextAlign.center,
                )
                    .animate(delay: 200.ms)
                    .fadeIn(duration: ArenaDurations.long),
                const SizedBox(height: ArenaSpacing.lg),
                const _StatGrid()
                    .animate(delay: 350.ms)
                    .fadeIn(duration: ArenaDurations.medium)
                    .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
                const Spacer(flex: 2),
                ArenaButton(
                  label: 'SE CONNECTER',
                  fullWidth: true,
                  size: ArenaButtonSize.large,
                  onPressed: () => context.goNamed('user.login'),
                )
                    .animate(delay: 500.ms)
                    .fadeIn(duration: ArenaDurations.medium)
                    .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
                const SizedBox(height: ArenaSpacing.sm),
                ArenaButton(
                  label: 'CRÉER UN COMPTE',
                  fullWidth: true,
                  size: ArenaButtonSize.large,
                  variant: ArenaButtonVariant.secondary,
                  onPressed: () => context.goNamed('user.register'),
                )
                    .animate(delay: 600.ms)
                    .fadeIn(duration: ArenaDurations.medium)
                    .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
                const SizedBox(height: ArenaSpacing.lg),
                Text(
                  'v1.0 — ARENA Cameroun',
                  style: ArenaText.small,
                  textAlign: TextAlign.center,
                )
                    .animate(delay: 700.ms)
                    .fadeIn(duration: ArenaDurations.medium),
                const SizedBox(height: ArenaSpacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid();

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
        border: Border.all(color: ArenaColors.border),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatCol(
            value: '12 048',
            label: 'joueurs',
            color: ArenaColors.signalBlue,
          ),
          _StatCol(
            value: '342',
            label: 'tournois',
            color: ArenaColors.statusOk,
          ),
          _StatCol(
            value: '1.2M',
            label: 'XAF',
            color: ArenaColors.neonRed,
          ),
        ],
      ),
    );
  }
}

class _StatCol extends StatelessWidget {
  const _StatCol({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: ArenaText.h2.copyWith(color: color, fontSize: 18),
        ),
        const SizedBox(height: 2),
        Text(label, style: ArenaText.small),
      ],
    );
  }
}
