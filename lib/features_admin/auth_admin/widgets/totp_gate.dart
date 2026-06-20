import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/repositories/auth_failure.dart';
import 'package:arena/features_admin/auth_admin/admin_auth_providers.dart';
import 'package:arena/features_shared/auth_common/auth_failure_message.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_error_banner.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Step-up TOTP gate for sensitive admin actions.
///
/// Call [TotpGate.confirm] before any destructive operation (payout
/// validation, dispute resolution, user ban, KYC override). Returns
/// `true` when the admin successfully re-verifies their TOTP code,
/// `false` when they cancel or fail.
///
/// In debug builds, a dev-only bypass button appears once the
/// `admin-stepup-totp` Edge Function reports unavailable — keeps the
/// dev workflow alive until PHASE 12.5 deploys the backend. In release
/// builds the bypass is hidden, so a missing EF blocks the action.
class TotpGate {
  const TotpGate._();

  static Future<bool> confirm(
    BuildContext context,
    WidgetRef ref, {
    required String reason,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ArenaColors.carbon,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _TotpGateSheet(reason: reason),
    );
    ref.read(adminTotpStepUpControllerProvider.notifier).reset();
    return result ?? false;
  }
}

class _TotpGateSheet extends ConsumerStatefulWidget {
  const _TotpGateSheet({required this.reason});

  final String reason;

  @override
  ConsumerState<_TotpGateSheet> createState() => _TotpGateSheetState();
}

class _TotpGateSheetState extends ConsumerState<_TotpGateSheet> {
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
        .read(adminTotpStepUpControllerProvider.notifier)
        .verify(_codeCtrl.text);
    if (!mounted) return;
    final state = ref.read(adminTotpStepUpControllerProvider);
    if (state.value ?? false) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminTotpStepUpControllerProvider);
    final isLoading = state.isLoading;
    final failure = state.hasError ? _asFailure(state.error) : null;
    final backendDown = failure is BackendUnavailableFailure;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(ArenaSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ArenaColors.textMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: ArenaSpacing.md),
              Text('VÉRIFICATION 2FA', style: ArenaText.h2),
              const SizedBox(height: ArenaSpacing.xs),
              Text(
                widget.reason,
                style: ArenaText.bodyMuted,
              ),
              const SizedBox(height: ArenaSpacing.lg),
              ArenaTextField(
                label: 'CODE TOTP',
                hint: '123 456',
                controller: _codeCtrl,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                prefixIcon: Icons.lock_clock,
                enabled: !isLoading,
                autofocus: true,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
              ),
              if (failure != null) ...[
                const SizedBox(height: ArenaSpacing.sm),
                ArenaErrorBanner(
                  message: authFailureToMessage(failure),
                  dense: true,
                ),
              ],
              const SizedBox(height: ArenaSpacing.md),
              ArenaButton(
                label: 'CONFIRMER',
                fullWidth: true,
                size: ArenaButtonSize.large,
                isLoading: isLoading,
                onPressed: _submit,
              ),
              const SizedBox(height: ArenaSpacing.xs),
              if (backendDown && kDebugMode)
                ArenaButton(
                  label: '⚠ Continuer (DEV — backend phase 12.5)',
                  variant: ArenaButtonVariant.secondary,
                  fullWidth: true,
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ArenaButton(
                label: 'ANNULER',
                variant: ArenaButtonVariant.ghost,
                fullWidth: true,
                onPressed: () => Navigator.of(context).pop(false),
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

// _ErrorBanner factorisé → ArenaErrorBanner (features_shared/widgets).
