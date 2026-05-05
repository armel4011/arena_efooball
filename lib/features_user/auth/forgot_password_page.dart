import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_colors.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/theme/arena_typography.dart';
import 'package:arena/data/repositories/auth_failure.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
import 'package:arena/features_user/auth/widgets/auth_failure_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Step 1 of the password-recovery flow.
///
/// User enters their email → we ask Supabase to send a recovery email
/// pointing to `kResetPasswordRedirect`. The deep link handler at the
/// app level will route into [ResetPasswordPage] once the user taps it.
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    await ref
        .read(forgotPasswordControllerProvider.notifier)
        .sendResetEmail(_emailCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPasswordControllerProvider);
    final isLoading = state.isLoading;
    final emailSent = state.value == true;
    final errorMessage = state.hasError
        ? authFailureToMessage(_asFailure(state.error))
        : null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(UserRoutes.login),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(ArenaSpacing.lg),
          child: emailSent
              ? _SuccessView(email: _emailCtrl.text.trim())
              : _RequestForm(
                  formKey: _formKey,
                  emailCtrl: _emailCtrl,
                  isLoading: isLoading,
                  errorMessage: errorMessage,
                  onSubmit: _submit,
                ),
        ),
      ),
    );
  }
}

class _RequestForm extends StatelessWidget {
  const _RequestForm({
    required this.formKey,
    required this.emailCtrl,
    required this.isLoading,
    required this.errorMessage,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('MOT DE PASSE OUBLIÉ', style: ArenaTypography.displayMedium),
          const SizedBox(height: ArenaSpacing.sm),
          Text(
            "Entre l'adresse e-mail liée à ton compte, on t'envoie un lien"
            ' de réinitialisation.',
            style: ArenaTypography.bodyMedium.copyWith(
              color: ArenaColors.textMuted,
            ),
          ),
          const SizedBox(height: ArenaSpacing.xl),
          ArenaTextField(
            label: 'EMAIL',
            hint: 'joueur@arena.app',
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            prefixIcon: Icons.email_outlined,
            enabled: !isLoading,
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: ArenaSpacing.sm),
            _ErrorBanner(message: errorMessage!),
          ],
          const SizedBox(height: ArenaSpacing.lg),
          ArenaButton(
            label: 'ENVOYER LE LIEN',
            fullWidth: true,
            size: ArenaButtonSize.large,
            isLoading: isLoading,
            onPressed: onSubmit,
          ),
        ],
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
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
              Icons.mark_email_read_outlined,
              color: ArenaColors.success,
              size: 48,
            ),
          ),
        ),
        const SizedBox(height: ArenaSpacing.lg),
        Text(
          'EMAIL ENVOYÉ',
          style: ArenaTypography.displayMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: ArenaSpacing.sm),
        Text(
          'Un lien de réinitialisation vient de partir vers $email.\n'
          'Vérifie aussi ton dossier "Spam".',
          style: ArenaTypography.bodyMedium.copyWith(
            color: ArenaColors.textMuted,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: ArenaSpacing.xl),
        ArenaButton(
          label: 'RETOUR À LA CONNEXION',
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
