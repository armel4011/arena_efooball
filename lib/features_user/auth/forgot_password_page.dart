import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/repositories/auth_failure.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
import 'package:arena/features_user/auth/widgets/auth_error_banner.dart';
import 'package:arena/features_user/auth/widgets/auth_failure_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Étape 1 du flow de réinitialisation par OTP.
///
/// L'utilisateur saisit son email → Supabase envoie un email contenant
/// un code à 6 chiffres (`{{ .Token }}` dans le template recovery).
/// Après envoi, on enchaîne sur la page de saisie du code OTP.
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
    final email = _emailCtrl.text.trim();
    await ref
        .read(forgotPasswordControllerProvider.notifier)
        .sendResetEmail(email);
    if (!mounted) return;
    final state = ref.read(forgotPasswordControllerProvider);
    if (state.hasValue && (state.value ?? false)) {
      context.goNamed(
        'user.resetPasswordCode',
        queryParameters: {'email': email},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPasswordControllerProvider);
    final isLoading = state.isLoading;
    final errorMessage =
        state.hasError ? authFailureToMessage(_asFailure(state.error)) : null;

    return Scaffold(
      appBar: ArenaAppBar(
        title: '',
        onBack: isLoading ? null : () => context.goNamed('user.login'),
      ),
      body: ArenaScreenBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(ArenaSpacing.lg),
            child: _RequestForm(
              formKey: _formKey,
              emailCtrl: _emailCtrl,
              isLoading: isLoading,
              errorMessage: errorMessage,
              onSubmit: _submit,
            ),
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
            "Entre l'adresse e-mail liée à ton compte, on t'envoie un code"
            ' à 6 chiffres pour réinitialiser ton mot de passe.',
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
            AuthErrorBanner(message: errorMessage!),
          ],
          const SizedBox(height: ArenaSpacing.lg),
          ArenaButton(
            label: 'ENVOYER LE CODE',
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

AuthFailure _asFailure(Object? error) {
  if (error is AuthFailure) return error;
  return UnknownAuthFailure(error);
}
