import 'package:arena/core/utils/arena_error_message.dart';
import 'package:arena/features_admin/auth_admin/admin_auth_providers.dart';
import 'package:arena/features_admin_desktop/auth/desktop_auth_scaffold.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Connexion admin desktop — email + mot de passe.
///
/// Réutilise [adminSignInControllerProvider] (le même que le mobile) :
/// la vérification du rôle admin/super_admin est faite côté repository,
/// et le routeur enchaîne automatiquement vers `/totp/verify` via son
/// `refreshListenable` une fois la session créée.
class DesktopLoginScreen extends ConsumerStatefulWidget {
  const DesktopLoginScreen({super.key});

  @override
  ConsumerState<DesktopLoginScreen> createState() =>
      _DesktopLoginScreenState();
}

class _DesktopLoginScreenState extends ConsumerState<DesktopLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) return;
    await ref
        .read(adminSignInControllerProvider.notifier)
        .signIn(email: email, password: password);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminSignInControllerProvider);
    final isLoading = state.isLoading;
    final error = state.hasError ? state.error : null;

    return DesktopAuthScaffold(
      title: 'Connexion',
      subtitle: 'Accès réservé aux administrateurs ARENA.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (error != null) ...[
            InfoBar(
              title: const Text('Connexion refusée'),
              content: Text(arenaErrorMessage(error)),
              severity: InfoBarSeverity.error,
            ),
            const SizedBox(height: 16),
          ],
          InfoLabel(
            label: 'Email',
            child: TextBox(
              controller: _emailController,
              placeholder: 'admin@arena.app',
              enabled: !isLoading,
              onSubmitted: (_) => _submit(),
            ),
          ),
          const SizedBox(height: 16),
          InfoLabel(
            label: 'Mot de passe',
            child: PasswordBox(
              controller: _passwordController,
              placeholder: '••••••••••••',
              enabled: !isLoading,
              onSubmitted: (_) => _submit(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: isLoading ? null : _submit,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      child: ProgressRing(strokeWidth: 2.5),
                    )
                  : const Text('SE CONNECTER'),
            ),
          ),
        ],
      ),
    );
  }
}
