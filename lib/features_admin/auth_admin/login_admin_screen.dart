import 'package:arena/core/router/admin_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/repositories/auth_failure.dart';
import 'package:arena/features_admin/auth_admin/admin_auth_providers.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:arena/features_user/auth/widgets/auth_failure_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LoginAdminScreen extends ConsumerStatefulWidget {
  const LoginAdminScreen({super.key});

  @override
  ConsumerState<LoginAdminScreen> createState() => _LoginAdminScreenState();
}

class _LoginAdminScreenState extends ConsumerState<LoginAdminScreen> {
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
    await ref.read(adminSignInControllerProvider.notifier).signIn(
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
        );
    if (!mounted) return;
    final state = ref.read(adminSignInControllerProvider);
    if (state.value != null) {
      // Email + password OK — go to TOTP verify (or setup if not enabled).
      final profile = state.value!;
      if (profile.totpEnabled) {
        context.go(AdminRoutes.totpVerify);
      } else {
        context.go(AdminRoutes.totpSetup);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminSignInControllerProvider);
    final isLoading = state.isLoading;
    final errorMessage =
        state.hasError ? authFailureToMessage(_asFailure(state.error)) : null;

    return Scaffold(
      appBar: ArenaAppBar(
        title: 'Console admin',
        onBack: () => context.go(AdminRoutes.splash),
      ),
      body: ArenaScreenBackground(
        accent: ArenaColors.neonRed,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(ArenaSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: ArenaSpacing.lg),
                  const Center(
                    child: Text(
                      '🛡',
                      style: TextStyle(fontSize: 54),
                    ),
                  ),
                  const SizedBox(height: ArenaSpacing.md),
                  Center(
                    child: Text(
                      'CONSOLE ADMIN',
                      style: ArenaText.h1,
                    ),
                  ),
                  const SizedBox(height: ArenaSpacing.sm),
                  Center(
                    child: Text(
                      'ACCÈS RESTREINT · AUTHENTIFICATION 2FA',
                      style: ArenaText.monoSmall.copyWith(
                        color: ArenaColors.neonRed,
                      ),
                    ),
                  ),
                  const SizedBox(height: ArenaSpacing.xl),
                  ArenaTextField(
                    label: 'EMAIL ADMIN',
                    hint: 'admin@arena.app',
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
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: isLoading
                          ? null
                          : () => _showForgotPasswordHint(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Mot de passe oublié ?',
                        style: ArenaText.small.copyWith(
                          color: ArenaColors.neonRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: ArenaSpacing.sm),
                    _ErrorBanner(message: errorMessage),
                  ],
                  const SizedBox(height: ArenaSpacing.sm),
                  ArenaButton(
                    label: 'SE CONNECTER',
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
                          : () => context.go(AdminRoutes.invitation),
                      child: const Text('Je suis invité (code admin)'),
                    ),
                  ),
                  const SizedBox(height: ArenaSpacing.md),
                  const _AdminWarningCard(
                    text: '⚠ Toute tentative non autorisée est journalisée '
                        'et signalée.',
                  ),
                  const SizedBox(height: ArenaSpacing.md),
                  Center(
                    child: Text(
                      'Pas de Google/Apple sign-in · Sécurité max',
                      style: ArenaText.small,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showForgotPasswordHint(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Réinitialisation admin : contacte ton super-admin pour '
          'régénérer ton accès.',
        ),
      ),
    );
  }
}

AuthFailure _asFailure(Object? error) {
  if (error is AuthFailure) return error;
  return UnknownAuthFailure(error);
}

class _AdminWarningCard extends StatelessWidget {
  const _AdminWarningCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.statusWarn.withValues(alpha: 0.12),
        borderRadius: ArenaRadius.button,
        border: Border.all(
          color: ArenaColors.statusWarn.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        text,
        style: ArenaText.small.copyWith(
          color: ArenaColors.bone,
          height: 1.5,
        ),
      ),
    );
  }
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
              style: ArenaText.body.copyWith(
                color: ArenaColors.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
