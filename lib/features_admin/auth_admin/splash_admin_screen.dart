import 'package:arena/core/router/admin_router.dart';
import 'package:arena/core/theme/arena_colors.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/theme/arena_typography.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// First screen of the Admin app.
///
/// Tinted in the admin secondary color (red) to make it visually
/// distinct from the User app, with two CTAs : sign in or redeem an
/// invitation code.
class SplashAdminScreen extends StatelessWidget {
  const SplashAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(ArenaSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ArenaColors.secondary.withValues(alpha: 0.12),
                  ),
                  child: const Icon(
                    Icons.shield,
                    size: 64,
                    color: ArenaColors.secondary,
                  ),
                ),
              ),
              const SizedBox(height: ArenaSpacing.lg),
              Text(
                'ARENA ADMIN',
                style: ArenaTypography.displayLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: ArenaSpacing.sm),
              Text(
                'Accès administrateur',
                style: ArenaTypography.bodyMedium.copyWith(
                  color: ArenaColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 3),
              ArenaButton(
                label: 'SE CONNECTER',
                fullWidth: true,
                size: ArenaButtonSize.large,
                onPressed: () => context.go(AdminRoutes.login),
              ),
              const SizedBox(height: ArenaSpacing.md),
              ArenaButton(
                label: 'JE SUIS INVITÉ',
                fullWidth: true,
                size: ArenaButtonSize.large,
                variant: ArenaButtonVariant.secondary,
                onPressed: () => context.go(AdminRoutes.invitation),
              ),
              const SizedBox(height: ArenaSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
