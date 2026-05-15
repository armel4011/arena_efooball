import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/repositories/auth_failure.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
import 'package:arena/features_user/auth/widgets/auth_failure_message.dart';
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
    if (v == null || v.isEmpty) return 'Mot de passe requis';
    if (v.length < 8) return 'Minimum 8 caractères';
    return null;
  }

  String? _validateConfirm(String? v) {
    if (v != _passwordCtrl.text) return 'Les mots de passe ne correspondent pas';
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
    final state = ref.watch(resetPasswordControllerProvider);
    final isLoading = state.isLoading;
    final passwordChanged = state.value == true;
    final errorMessage = state.hasError
        ? authFailureToMessage(_asFailure(state.error))
        : null;

    return Scaffold(
      // Pas de back — l'utilisateur a déjà validé son OTP, le retour
      // arrière ne servirait à rien et l'expose à des soucis de session
      // recovery déjà consommée.
      appBar: const ArenaAppBar(title: '', showBack: false),
      body: SafeArea(
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
                        'NOUVEAU MOT DE PASSE',
                        style: ArenaTypography.displayMedium,
                      ),
                      const SizedBox(height: ArenaSpacing.sm),
                      Text(
                        'Choisis un mot de passe solide. Il sera utilisé'
                        ' pour ta prochaine connexion.',
                        style: ArenaTypography.bodyMedium.copyWith(
                          color: ArenaColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: ArenaSpacing.xl),
                      ArenaTextField(
                        label: 'NOUVEAU MOT DE PASSE',
                        hint: 'Au moins 8 caractères',
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
                        label: 'CONFIRMER',
                        hint: 'Retape ton mot de passe',
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
                        _ErrorBanner(message: errorMessage),
                      ],
                      const SizedBox(height: ArenaSpacing.lg),
                      ArenaButton(
                        label: 'METTRE À JOUR',
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
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView();

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
              Icons.lock_open_outlined,
              color: ArenaColors.success,
              size: 48,
            ),
          ),
        ),
        const SizedBox(height: ArenaSpacing.lg),
        Text(
          'MOT DE PASSE MIS À JOUR',
          style: ArenaTypography.displayMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: ArenaSpacing.sm),
        Text(
          'Tu peux maintenant te connecter avec ton nouveau mot de passe.',
          style: ArenaTypography.bodyMedium.copyWith(
            color: ArenaColors.textMuted,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: ArenaSpacing.xl),
        ArenaButton(
          label: 'SE CONNECTER',
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
