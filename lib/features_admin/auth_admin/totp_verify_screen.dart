import 'package:arena/core/router/admin_router.dart';
import 'package:arena/core/theme/arena_colors.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/theme/arena_typography.dart';
import 'package:arena/data/repositories/auth_failure.dart';
import 'package:arena/features_admin/auth_admin/admin_auth_providers.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:arena/features_user/auth/widgets/auth_failure_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// PHASE 2bis sub-flow B.4 — TOTP verify at login.
///
/// Reached after [LoginAdminScreen] succeeds with email + password and
/// the admin has `totp_enabled = true` already. Backup-code fallback is
/// still wired but currently routes to a placeholder (PHASE 2bis backend).
class TotpVerifyScreen extends ConsumerStatefulWidget {
  const TotpVerifyScreen({super.key});

  @override
  ConsumerState<TotpVerifyScreen> createState() => _TotpVerifyScreenState();
}

class _TotpVerifyScreenState extends ConsumerState<TotpVerifyScreen> {
  final _codeCtrl = TextEditingController();

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_codeCtrl.text.length != 6) return;
    FocusScope.of(context).unfocus();
    await ref
        .read(adminTotpVerifyControllerProvider.notifier)
        .verify(_codeCtrl.text);
    if (!mounted) return;
    final state = ref.read(adminTotpVerifyControllerProvider);
    if (state.value != null) {
      context.go(AdminRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminTotpVerifyControllerProvider);
    final isLoading = state.isLoading;
    final errorMessage = state.hasError
        ? authFailureToMessage(_asFailure(state.error))
        : null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AdminRoutes.login),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(ArenaSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'VÉRIFICATION TOTP',
                style: ArenaTypography.displayMedium,
              ),
              const SizedBox(height: ArenaSpacing.sm),
              Text(
                "Entre le code à 6 chiffres affiché dans Google"
                ' Authenticator (ou ton app TOTP).',
                style: ArenaTypography.bodyMedium.copyWith(
                  color: ArenaColors.textMuted,
                ),
              ),
              const SizedBox(height: ArenaSpacing.xl),
              ArenaTextField(
                label: 'CODE TOTP',
                hint: '123 456',
                controller: _codeCtrl,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                prefixIcon: Icons.numbers,
                enabled: !isLoading,
                autofocus: true,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: ArenaSpacing.sm),
                _ErrorBanner(message: errorMessage),
              ],
              const SizedBox(height: ArenaSpacing.lg),
              ArenaButton(
                label: 'VÉRIFIER',
                fullWidth: true,
                size: ArenaButtonSize.large,
                isLoading: isLoading,
                onPressed: _submit,
              ),
              const SizedBox(height: ArenaSpacing.md),
              Center(
                child: TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Récupération par code backup : '
                                'PHASE 2bis backend (Edge Function pending).',
                              ),
                            ),
                          );
                        },
                  child: const Text('Utiliser un code de récupération'),
                ),
              ),
            ],
          ),
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
