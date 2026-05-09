import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shown when a social sign-in (Google / Apple) collides with an existing
/// email-password account on the same address.
///
/// V1.0 ships **without** social SSO (the `google_sign_in` /
/// `sign_in_with_apple` deps are deferred in `pubspec.yaml`), so this
/// screen is wired but unreachable until **PHASE 2.3 — Social login**.
/// We keep the scaffold so the route + UX shell are ready.
class LinkExistingAccountPage extends StatelessWidget {
  const LinkExistingAccountPage({
    super.key,
    this.email,
    this.providerLabel = 'Google',
  });

  /// The email returned by the social provider (best-effort hint).
  final String? email;

  /// Human-readable provider name displayed in the body — "Google",
  /// "Apple", etc.
  final String providerLabel;

  @override
  Widget build(BuildContext context) {
    final emailLine = email == null
        ? "L'adresse e-mail de ce compte $providerLabel est déjà"
            " utilisée par un compte ARENA."
        : "$email est déjà utilisé par un compte ARENA"
            ' (mot de passe).';

    return Scaffold(
      appBar: const ArenaAppBar(title: 'Lier les comptes'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(ArenaSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: ArenaSpacing.xl),
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ArenaColors.warning.withValues(alpha: 0.12),
                  ),
                  child: const Icon(
                    Icons.merge_type_outlined,
                    color: ArenaColors.warning,
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: ArenaSpacing.lg),
              Text(
                'COMPTE EXISTANT DÉTECTÉ',
                style: ArenaTypography.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: ArenaSpacing.sm),
              Text(
                emailLine,
                style: ArenaTypography.bodyMedium.copyWith(
                  color: ArenaColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: ArenaSpacing.md),
              Text(
                'Choisis comment continuer :',
                style: ArenaTypography.bodyMedium.copyWith(
                  color: ArenaColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: ArenaSpacing.xl),
              ArenaButton(
                label: 'LIER LES DEUX COMPTES',
                fullWidth: true,
                size: ArenaButtonSize.large,
                // PHASE 2.3 — wire to AuthRepository.linkProviderToCurrentUser
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Disponible en PHASE 2.3 (social login Google/Apple).',
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: ArenaSpacing.md),
              ArenaButton(
                label: 'ME CONNECTER AVEC MOT DE PASSE',
                fullWidth: true,
                size: ArenaButtonSize.large,
                variant: ArenaButtonVariant.secondary,
                onPressed: () => context.go(UserRoutes.login),
              ),
              const SizedBox(height: ArenaSpacing.md),
              TextButton(
                onPressed: () => context.go(UserRoutes.login),
                child: const Text('Annuler'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
