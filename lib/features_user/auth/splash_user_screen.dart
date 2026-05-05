import 'package:arena/core/theme/arena_colors.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/theme/arena_typography.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Pre-auth landing — single screen with two clear CTAs.
class SplashUserScreen extends StatelessWidget {
  const SplashUserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(ArenaSpacing.lg),
          child: Column(
            children: [
              const Spacer(),
              const _Hero(),
              const SizedBox(height: ArenaSpacing.xxl),
              ArenaButton(
                label: 'SE CONNECTER',
                fullWidth: true,
                size: ArenaButtonSize.large,
                onPressed: () => context.goNamed('user.login'),
              ),
              const SizedBox(height: ArenaSpacing.md),
              ArenaButton(
                label: "S'INSCRIRE",
                fullWidth: true,
                size: ArenaButtonSize.large,
                variant: ArenaButtonVariant.secondary,
                onPressed: () => context.goNamed('user.register'),
              ),
              const SizedBox(height: ArenaSpacing.xl),
              Text(
                'En continuant, tu acceptes les CGU et la Politique de '
                "confidentialité d'ARENA.",
                style: ArenaTypography.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: ArenaSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: ArenaColors.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: ArenaColors.primary.withValues(alpha: 0.4),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: ArenaColors.primary.withValues(alpha: 0.3),
                blurRadius: 32,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Icon(
            Icons.sports_esports,
            size: 56,
            color: ArenaColors.primary,
          ),
        ),
        const SizedBox(height: ArenaSpacing.xl),
        Text(
          'ARENA',
          style: ArenaTypography.displayLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: ArenaSpacing.sm),
        Text(
          'TOURNOIS E-SPORT MOBILE',
          style: ArenaTypography.labelLarge.copyWith(
            color: ArenaColors.textMuted,
            letterSpacing: 3,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
