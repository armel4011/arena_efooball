import 'package:arena/core/router/admin_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
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
      body: ArenaScreenBackground(
        accent: ArenaColors.neonRed,
        child: SafeArea(
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
                      color: ArenaColors.neonRed.withValues(alpha: 0.12),
                      boxShadow: [
                        BoxShadow(
                          color: ArenaColors.neonRed.withValues(alpha: 0.35),
                          blurRadius: 32,
                          spreadRadius: -4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.shield,
                      size: 64,
                      color: ArenaColors.neonRed,
                    ),
                  ),
                ),
                const SizedBox(height: ArenaSpacing.lg),
                const Center(child: ArenaLogo(fontSize: 46, letterSpacing: 6)),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    'admin console',
                    style: ArenaText.serifAccent
                        .copyWith(color: ArenaColors.neonRed),
                  ),
                ),
                const Spacer(flex: 3),
                ArenaButton(
                  label: 'SE CONNECTER',
                  variant: ArenaButtonVariant.danger,
                  fullWidth: true,
                  size: ArenaButtonSize.large,
                  onPressed: () => context.go(AdminRoutes.login),
                ),
                const SizedBox(height: ArenaSpacing.sm),
                ArenaButton(
                  label: "🎟 J'AI UN CODE D'INVITATION",
                  fullWidth: true,
                  size: ArenaButtonSize.large,
                  variant: ArenaButtonVariant.secondary,
                  onPressed: () => context.go(AdminRoutes.invitation),
                ),
                const SizedBox(height: ArenaSpacing.md),
                Center(
                  child: Text(
                    'v1.0.0 · build 4287',
                    style: ArenaText.monoSmall,
                  ),
                ),
                const SizedBox(height: ArenaSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
