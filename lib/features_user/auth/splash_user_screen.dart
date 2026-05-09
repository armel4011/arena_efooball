import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

/// Pre-auth landing — full-bleed ARENA logo (ShaderMask gradient) + 2 CTAs.
///
/// Maps to the splash section of `arena_v2.html`. The hero logo uses
/// [ArenaLogo] (60 px Bebas Neue with the brand blue→red gradient and a soft
/// blue glow). Cascade fade-in: logo → tagline → CTAs.
class SplashUserScreen extends StatelessWidget {
  const SplashUserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(ArenaSpacing.xl),
          child: Column(
            children: [
              const Spacer(flex: 3),
              const ArenaLogo()
                  .animate()
                  .fadeIn(duration: ArenaDurations.long)
                  .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
              const SizedBox(height: ArenaSpacing.lg),
              Text(
                'plays hard. wins harder.',
                style: ArenaText.serifTagline,
                textAlign: TextAlign.center,
              )
                  .animate(delay: 200.ms)
                  .fadeIn(duration: ArenaDurations.long),
              const Spacer(flex: 2),
              ArenaButton(
                label: 'SE CONNECTER',
                fullWidth: true,
                size: ArenaButtonSize.large,
                onPressed: () => context.goNamed('user.login'),
              )
                  .animate(delay: 400.ms)
                  .fadeIn(duration: ArenaDurations.medium)
                  .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
              const SizedBox(height: ArenaSpacing.md),
              ArenaButton(
                label: "S'INSCRIRE",
                fullWidth: true,
                size: ArenaButtonSize.large,
                variant: ArenaButtonVariant.secondary,
                onPressed: () => context.goNamed('user.register'),
              )
                  .animate(delay: 500.ms)
                  .fadeIn(duration: ArenaDurations.medium)
                  .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
              const SizedBox(height: ArenaSpacing.xl),
              Text(
                'En continuant, tu acceptes les CGU et la Politique de '
                "confidentialité d'ARENA.",
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
    );
  }
}
