import 'package:arena/core/router/user_router.dart';
import 'package:arena/data/repositories/auth_failure.dart';
import 'package:arena/features_shared/auth_common/auth_failure_message.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
import 'package:arena/features_user/auth/reset_password_page.dart'
    show ResetPasswordPage;
import 'package:arena/features_user/auth/widgets/code_verification_view.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
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
          child: CodeVerificationView(
            icon: Icons.lock_reset,
            title: l10n.resetCodeTitle,
            subtitle: l10n.resetCodeSubtitle,
            email: widget.email,
            controller: _codeCtrl,
            verifyLabel: l10n.resetCodeVerifyButton,
            resendLabel: l10n.resetCodeResendButton,
            resendingLabel: l10n.resetCodeResending,
            onVerify: _submit,
            onResend: _resend,
            isLoading: isLoading,
            resending: _resending,
            errorMessage: errorMessage,
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
