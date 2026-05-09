import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/repositories/auth_failure.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
import 'package:arena/features_user/auth/widgets/auth_failure_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Forced after first sign-in when `cgu_accepted_at` is null on the
/// profile (legacy accounts, SSO sign-ups that skipped the multi-step
/// register form, etc.).
///
/// Hard-coded CGU version for V1.0 — kept in sync with
/// `register_user_screen.dart` (`_cguVersion = '2026-05-01'`). When
/// admin starts editing CGU from the super-admin app (PHASE 12), swap
/// both for a fetch from `app_config.cgu_version`.
const String _kCguVersion = '2026-05-01';

class CguAcceptancePage extends ConsumerStatefulWidget {
  const CguAcceptancePage({super.key});

  @override
  ConsumerState<CguAcceptancePage> createState() => _CguAcceptancePageState();
}

class _CguAcceptancePageState extends ConsumerState<CguAcceptancePage> {
  bool _cguChecked = false;
  bool _marketingChecked = false;

  Future<void> _submit() async {
    if (!_cguChecked) return;
    await ref.read(acceptCguControllerProvider.notifier).accept(
          cguVersion: _kCguVersion,
          marketingConsent: _marketingChecked,
        );
    if (!mounted) return;
    final state = ref.read(acceptCguControllerProvider);
    if (state.value == true) {
      context.go(UserRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(acceptCguControllerProvider);
    final isLoading = state.isLoading;
    final errorMessage = state.hasError
        ? authFailureToMessage(_asFailure(state.error))
        : null;

    return Scaffold(
      // No back button — acceptance is mandatory once we're here.
      appBar: const ArenaAppBar(title: '', showBack: false),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(ArenaSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('CONDITIONS GÉNÉRALES', style: ArenaTypography.displayMedium),
              const SizedBox(height: ArenaSpacing.sm),
              Text(
                'Avant de jouer, on a besoin de ton accord sur les'
                ' conditions et la politique de confidentialité d\'ARENA.',
                style: ArenaTypography.bodyMedium.copyWith(
                  color: ArenaColors.textMuted,
                ),
              ),
              const SizedBox(height: ArenaSpacing.lg),
              _DocLink(
                label: 'Lire les Conditions Générales d\'Utilisation',
                onTap: () => _showDocPlaceholder(context, 'CGU'),
              ),
              const SizedBox(height: ArenaSpacing.sm),
              _DocLink(
                label: 'Lire la politique de confidentialité',
                onTap: () => _showDocPlaceholder(context, 'Confidentialité'),
              ),
              const SizedBox(height: ArenaSpacing.lg),
              _ConsentTile(
                value: _cguChecked,
                onChanged: isLoading
                    ? null
                    : (v) => setState(() => _cguChecked = v ?? false),
                title: 'J\'accepte les CGU et la politique de confidentialité',
                required: true,
              ),
              const SizedBox(height: ArenaSpacing.sm),
              _ConsentTile(
                value: _marketingChecked,
                onChanged: isLoading
                    ? null
                    : (v) => setState(() => _marketingChecked = v ?? false),
                title:
                    'J\'accepte de recevoir des informations sur les nouveaux'
                    ' tournois (optionnel)',
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: ArenaSpacing.md),
                _ErrorBanner(message: errorMessage),
              ],
              const SizedBox(height: ArenaSpacing.xl),
              ArenaButton(
                label: 'ACCEPTER ET CONTINUER',
                fullWidth: true,
                size: ArenaButtonSize.large,
                isLoading: isLoading,
                onPressed: _cguChecked ? _submit : null,
              ),
              const SizedBox(height: ArenaSpacing.md),
              TextButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        await ref.read(signOutProvider)();
                      },
                child: const Text('Refuser et se déconnecter'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDocPlaceholder(BuildContext context, String docName) {
    // PHASE 9 — replace with WebView pointing to the hosted docs URL
    // (linked from app_config.cgu_url / app_config.privacy_url).
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(docName),
        content: Text(
          'La version complète sera affichée ici (PHASE 9 — '
          'AboutPage + WebView vers les docs hébergés).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _ConsentTile extends StatelessWidget {
  const _ConsentTile({
    required this.value,
    required this.onChanged,
    required this.title,
    this.required = false,
  });

  final bool value;
  final ValueChanged<bool?>? onChanged;
  final String title;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      borderRadius: ArenaRadius.button,
      child: Container(
        padding: const EdgeInsets.all(ArenaSpacing.md),
        decoration: BoxDecoration(
          color: ArenaColors.surface,
          borderRadius: ArenaRadius.button,
          border: Border.all(
            color: value
                ? Theme.of(context).colorScheme.primary
                : ArenaColors.border,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(value: value, onChanged: onChanged),
            const SizedBox(width: ArenaSpacing.sm),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  required ? '$title *' : title,
                  style: ArenaTypography.bodyMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocLink extends StatelessWidget {
  const _DocLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: ArenaSpacing.sm),
        child: Row(
          children: [
            const Icon(
              Icons.description_outlined,
              size: 18,
              color: ArenaColors.textMuted,
            ),
            const SizedBox(width: ArenaSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: ArenaTypography.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const Icon(
              Icons.open_in_new,
              size: 16,
              color: ArenaColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

AuthFailure _asFailure(Object? error) {
  if (error is AuthFailure) return error;
  return UnknownAuthFailure(error);
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.danger.withValues(alpha: 0.12),
        borderRadius: ArenaRadius.button,
        border: Border.all(color: ArenaColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: ArenaColors.danger,
            size: 20,
          ),
          const SizedBox(width: ArenaSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: ArenaTypography.bodySmall.copyWith(
                color: ArenaColors.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
