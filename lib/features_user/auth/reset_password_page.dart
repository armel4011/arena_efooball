import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/repositories/auth_failure.dart';
import 'package:arena/features_shared/auth_common/auth_failure_message.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
import 'package:arena/features_user/auth/reset_password_code_page.dart'
    show ResetPasswordCodePage;
import 'package:arena/features_user/auth/widgets/auth_error_banner.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Étape 3 du flow de réinitialisation par OTP.
///
/// Atteinte après que [ResetPasswordCodePage] ait vérifié le code à 6
/// chiffres et hydraté une session recovery côté Supabase. On collecte
/// le nouveau mot de passe et on l'applique via `updateUser`.
class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String? _validatePassword(String? v) {
    final l10n = AppLocalizations.of(context);
    if (v == null || v.isEmpty) return l10n.resetPwPasswordRequired;
    if (v.length < 8) return l10n.resetPwMinChars;
    return null;
  }

  String? _validateConfirm(String? v) {
    if (v != _passwordCtrl.text) {
      return AppLocalizations.of(context).resetPwPasswordsDontMatch;
    }
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    await ref
        .read(resetPasswordControllerProvider.notifier)
        .updatePassword(_passwordCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(resetPasswordControllerProvider);
    final isLoading = state.isLoading;
    final passwordChanged = state.value ?? false;
    final errorMessage = state.hasError
        ? authFailureToMessage(_asFailure(state.error), l10n)
        : null;

    return Scaffold(
      // Pas de back — l'utilisateur a déjà validé son OTP, le retour
      // arrière ne servirait à rien et l'expose à des soucis de session
      // recovery déjà consommée.
      appBar: const ArenaAppBar(title: '', showBack: false),
      body: ArenaScreenBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(ArenaSpacing.lg),
            child: passwordChanged
                ? const _SuccessView()
                : Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.resetPwTitle,
                          style: ArenaTypography.displayMedium,
                        ),
                        const SizedBox(height: ArenaSpacing.sm),
                        Text(
                          l10n.resetPwSubtitle,
                          style: ArenaTypography.bodyMedium.copyWith(
                            color: ArenaColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: ArenaSpacing.xl),
                        ArenaTextField(
                          label: l10n.resetPwNewPasswordLabel,
                          hint: l10n.resetPwNewPasswordHint,
                          controller: _passwordCtrl,
                          obscureText: _obscure1,
                          textInputAction: TextInputAction.next,
                          prefixIcon: Icons.lock_outline,
                          enabled: !isLoading,
                          validator: _validatePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure1
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: ArenaColors.textMuted,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _obscure1 = !_obscure1),
                          ),
                        ),
                        const SizedBox(height: ArenaSpacing.md),
                        ArenaTextField(
                          label: l10n.resetPwConfirmLabel,
                          hint: l10n.resetPwConfirmHint,
                          controller: _confirmCtrl,
                          obscureText: _obscure2,
                          textInputAction: TextInputAction.done,
                          prefixIcon: Icons.lock_outline,
                          enabled: !isLoading,
                          validator: _validateConfirm,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure2
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: ArenaColors.textMuted,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _obscure2 = !_obscure2),
                          ),
                        ),
                        if (errorMessage != null) ...[
                          const SizedBox(height: ArenaSpacing.sm),
                          AuthErrorBanner(message: errorMessage),
                        ],
                        const SizedBox(height: ArenaSpacing.lg),
                        ArenaButton(
                          label: l10n.resetPwUpdateButton,
                          fullWidth: true,
                          size: ArenaButtonSize.large,
                          isLoading: isLoading,
                          onPressed: _submit,
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: ArenaSpacing.xl),
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ArenaColors.success.withValues(alpha: 0.12),
            ),
            child: const Icon(
              Icons.lock_open_outlined,
              color: ArenaColors.success,
              size: 48,
            ),
          ),
        ),
        const SizedBox(height: ArenaSpacing.lg),
        Text(
          l10n.resetPwSuccessTitle,
          style: ArenaTypography.displayMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: ArenaSpacing.sm),
        Text(
          l10n.resetPwSuccessSubtitle,
          style: ArenaTypography.bodyMedium.copyWith(
            color: ArenaColors.textMuted,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: ArenaSpacing.xl),
        ArenaButton(
          label: l10n.resetPwLoginButton,
          fullWidth: true,
          size: ArenaButtonSize.large,
          onPressed: () => context.go(UserRoutes.login),
        ),
      ],
    );
  }
}

AuthFailure _asFailure(Object? error) {
  if (error is AuthFailure) return error;
  return UnknownAuthFailure(error);
}
