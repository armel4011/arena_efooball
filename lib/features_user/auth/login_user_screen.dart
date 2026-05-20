import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/repositories/auth_failure.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:arena/features_shared/widgets/google_sign_in_button.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
import 'package:arena/features_user/auth/widgets/auth_error_banner.dart';
import 'package:arena/features_user/auth/widgets/auth_failure_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LoginUserScreen extends ConsumerStatefulWidget {
  const LoginUserScreen({super.key});

  @override
  ConsumerState<LoginUserScreen> createState() => _LoginUserScreenState();
}

class _LoginUserScreenState extends ConsumerState<LoginUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    await ref.read(signInControllerProvider.notifier).signIn(
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
        );
  }

  Future<void> _submitGoogle() async {
    FocusScope.of(context).unfocus();
    await ref.read(googleSsoControllerProvider.notifier).signIn();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signInControllerProvider);
    final googleState = ref.watch(googleSsoControllerProvider);
    final isLoading = state.isLoading || googleState.isLoading;
    // Affiche d'abord l'erreur du flow actif. Email > Google si les deux
    // ont fini en erreur (cas tordu où l'utilisateur a tenté les deux).
    final errorMessage = state.hasError
        ? authFailureToMessage(_asFailure(state.error))
        : googleState.hasError
            ? authFailureToMessage(_asFailure(googleState.error))
            : null;

    return Scaffold(
      appBar: ArenaAppBar(
        title: '',
        onBack: isLoading ? null : () => context.goNamed('user.splash'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(ArenaSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('CONNEXION', style: ArenaTypography.displayMedium),
                const SizedBox(height: ArenaSpacing.sm),
                Text(
                  'Continue ton parcours sur ARENA.',
                  style: ArenaTypography.bodyMedium.copyWith(
                    color: ArenaColors.textMuted,
                  ),
                ),
                const SizedBox(height: ArenaSpacing.xl),
                ArenaTextField(
                  label: 'EMAIL',
                  hint: 'joueur@arena.app',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.email_outlined,
                  enabled: !isLoading,
                ),
                const SizedBox(height: ArenaSpacing.md),
                ArenaTextField(
                  label: 'MOT DE PASSE',
                  hint: '••••••••',
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  prefixIcon: Icons.lock_outline,
                  enabled: !isLoading,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility : Icons.visibility_off,
                      color: ArenaColors.textMuted,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                const SizedBox(height: ArenaSpacing.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: isLoading
                        ? null
                        : () => context.goNamed('user.forgotPassword'),
                    child: const Text('Mot de passe oublié ?'),
                  ),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: ArenaSpacing.sm),
                  AuthErrorBanner(message: errorMessage),
                ],
                const SizedBox(height: ArenaSpacing.lg),
                ArenaButton(
                  label: 'SE CONNECTER',
                  fullWidth: true,
                  size: ArenaButtonSize.large,
                  isLoading: isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: ArenaSpacing.lg),
                const _OrDivider(),
                const SizedBox(height: ArenaSpacing.md),
                GoogleSignInButton(
                  label: 'Continuer avec Google',
                  fullWidth: true,
                  isLoading: googleState.isLoading,
                  onPressed: isLoading ? null : _submitGoogle,
                ),
                const SizedBox(height: ArenaSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Pas encore inscrit ? ',
                      style: ArenaTypography.bodyMedium.copyWith(
                        color: ArenaColors.textMuted,
                      ),
                    ),
                    GestureDetector(
                      onTap: isLoading
                          ? null
                          : () => context.goNamed('user.register'),
                      child: Text(
                        "S'inscrire",
                        style: ArenaTypography.labelLarge.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Expanded(child: Divider(color: ArenaColors.border, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ArenaSpacing.md),
          child: Text('OU', style: ArenaText.small),
        ),
        const Expanded(child: Divider(color: ArenaColors.border, height: 1)),
      ],
    );
  }
}

AuthFailure _asFailure(Object? error) {
  if (error is AuthFailure) return error;
  return UnknownAuthFailure(error);
}
