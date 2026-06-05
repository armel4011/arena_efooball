import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/repositories/auth_failure.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
import 'package:arena/features_user/auth/reset_password_page.dart'
    show ResetPasswordPage;
import 'package:arena/features_user/auth/widgets/auth_error_banner.dart';
import 'package:arena/features_user/auth/widgets/auth_failure_message.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Étape 2 du flow de réinitialisation : saisie du code OTP à 6 chiffres
/// reçu par email. La validation hydrate une session recovery côté
/// Supabase, puis le routeur envoie vers [ResetPasswordPage] pour fixer
/// le nouveau mot de passe.
class ResetPasswordCodePage extends ConsumerStatefulWidget {
  const ResetPasswordCodePage({required this.email, super.key});

  final String email;

  @override
  ConsumerState<ResetPasswordCodePage> createState() =>
      _ResetPasswordCodePageState();
}

class _ResetPasswordCodePageState extends ConsumerState<ResetPasswordCodePage> {
  final _codeCtrl = TextEditingController();
  bool _resending = false;

  @override
  void initState() {
    super.initState();
    _codeCtrl.addListener(_onCodeChanged);
  }

  @override
  void dispose() {
    _codeCtrl
      ..removeListener(_onCodeChanged)
      ..dispose();
    super.dispose();
  }

  void _onCodeChanged() {
    if (mounted) setState(() {});
  }

  bool get _isCodeValid => _codeCtrl.text.trim().length == 6;

  Future<void> _submit() async {
    if (!_isCodeValid) return;
    FocusScope.of(context).unfocus();
    await ref.read(verifyPasswordResetCodeControllerProvider.notifier).verify(
          email: widget.email,
          code: _codeCtrl.text,
        );
    if (!mounted) return;
    final state = ref.read(verifyPasswordResetCodeControllerProvider);
    if (state.hasValue && (state.value ?? false)) {
      context.go(UserRoutes.resetPassword);
    }
  }

  Future<void> _resend() async {
    if (_resending) return;
    setState(() => _resending = true);
    await ref
        .read(forgotPasswordControllerProvider.notifier)
        .sendResetEmail(widget.email);
    if (!mounted) return;
    setState(() => _resending = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).resetCodeNewCodeSent)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(verifyPasswordResetCodeControllerProvider);
    final isLoading = state.isLoading;
    final errorMessage = state.hasError
        ? authFailureToMessage(_asFailure(state.error), l10n)
        : null;

    return Scaffold(
      appBar: ArenaAppBar(
        title: '',
        onBack: isLoading ? null : () => context.goNamed('user.forgotPassword'),
      ),
      body: ArenaScreenBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(ArenaSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.resetCodeTitle,
                  style: ArenaTypography.displayMedium,
                ),
                const SizedBox(height: ArenaSpacing.sm),
                Text(
                  l10n.resetCodeSubtitle,
                  style: ArenaTypography.bodyMedium.copyWith(
                    color: ArenaColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.email,
                  style: ArenaTypography.labelLarge,
                ),
                const SizedBox(height: ArenaSpacing.xl),
                ArenaTextField(
                  label: l10n.resetCodeFieldLabel,
                  hint: '••••••',
                  controller: _codeCtrl,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  prefixIcon: Icons.lock_clock_outlined,
                  enabled: !isLoading,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: ArenaSpacing.sm),
                  AuthErrorBanner(message: errorMessage),
                ],
                const SizedBox(height: ArenaSpacing.lg),
                ArenaButton(
                  label: l10n.resetCodeVerifyButton,
                  fullWidth: true,
                  size: ArenaButtonSize.large,
                  isLoading: isLoading,
                  onPressed: _isCodeValid ? _submit : null,
                ),
                const SizedBox(height: ArenaSpacing.lg),
                Center(
                  child: TextButton(
                    onPressed: isLoading || _resending ? null : _resend,
                    child: Text(
                      _resending
                          ? l10n.resetCodeResending
                          : l10n.resetCodeResendButton,
                    ),
                  ),
                ),
              ],
            ),
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
