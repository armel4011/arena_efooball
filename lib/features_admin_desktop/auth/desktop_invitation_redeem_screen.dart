import 'package:arena/core/router/admin_desktop_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/utils/arena_error_message.dart';
import 'package:arena/features_admin/auth_admin/admin_auth_providers.dart';
import 'package:arena/features_admin_desktop/auth/desktop_auth_scaffold.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Version CGU admin acceptée à l'inscription (alignée sur le mobile).
const String _kAdminCguVersion = '2026-05-01';

/// Inscription admin par code d'invitation — version desktop (Fluent UI).
///
/// Réutilise [invitationRedeemControllerProvider] (le même que le mobile) :
/// la validation du code + création du compte passe par l'EF `register-admin`.
/// Après succès, le routeur enchaîne sur `/totp/setup` via son
/// `refreshListenable` (compte créé + session établie, TOTP non encore actif).
class DesktopInvitationRedeemScreen extends ConsumerStatefulWidget {
  const DesktopInvitationRedeemScreen({super.key});

  @override
  ConsumerState<DesktopInvitationRedeemScreen> createState() =>
      _DesktopInvitationRedeemScreenState();
}

class _DesktopInvitationRedeemScreenState
    extends ConsumerState<DesktopInvitationRedeemScreen> {
  final _codeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _cguChecked = false;
  String? _validationError;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  /// Reproduit la validation du formulaire mobile (mêmes règles).
  String? _validate() {
    final code = _codeCtrl.text.trim().toUpperCase().replaceAll(
          RegExp(r'\s+'),
          '',
        );
    if (!RegExp(r'^ARENA(-[A-Z0-9]{4}){3}$').hasMatch(code)) {
      return 'Format de code attendu : ARENA-XXXX-XXXX-XXXX';
    }
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) return 'Email invalide';
    if (_usernameCtrl.text.trim().length < 3) {
      return 'Le nom affiché doit faire au moins 3 caractères';
    }
    final pwd = _passwordCtrl.text;
    if (pwd.length < 12) return 'Mot de passe : minimum 12 caractères';
    if (!RegExp('[A-Z]').hasMatch(pwd)) {
      return 'Mot de passe : au moins une majuscule';
    }
    if (!RegExp('[a-z]').hasMatch(pwd)) {
      return 'Mot de passe : au moins une minuscule';
    }
    if (!RegExp(r'\d').hasMatch(pwd)) {
      return 'Mot de passe : au moins un chiffre';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-]').hasMatch(pwd)) {
      return 'Mot de passe : au moins un caractère spécial';
    }
    if (_confirmCtrl.text != pwd) {
      return 'Les mots de passe ne correspondent pas';
    }
    if (!_cguChecked) return 'Vous devez accepter les CGU admin';
    return null;
  }

  Future<void> _submit() async {
    final err = _validate();
    if (err != null) {
      setState(() => _validationError = err);
      return;
    }
    setState(() => _validationError = null);

    await ref.read(invitationRedeemControllerProvider.notifier).redeem(
          code: _codeCtrl.text.trim().toUpperCase(),
          email: _emailCtrl.text.trim().toLowerCase(),
          password: _passwordCtrl.text,
          username: _usernameCtrl.text.trim(),
          cguAcceptedAt: DateTime.now().toUtc(),
          cguVersionAccepted: _kAdminCguVersion,
        );
    if (!mounted) return;
    final state = ref.read(invitationRedeemControllerProvider);
    if (state.value != null) {
      // Compte créé + session active → enrôlement TOTP obligatoire.
      context.go(AdminDesktopRoutes.totpSetup);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(invitationRedeemControllerProvider);
    final isLoading = state.isLoading;
    final error = state.hasError ? state.error : null;
    final edgeError = error != null ? arenaErrorMessage(error) : null;

    return DesktopAuthScaffold(
      title: 'Devenir admin',
      subtitle: "Saisissez le code d'invitation reçu par email.",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_validationError != null) ...[
            InfoBar(
              title: const Text('Formulaire incomplet'),
              content: Text(_validationError!),
              severity: InfoBarSeverity.warning,
              onClose: () => setState(() => _validationError = null),
            ),
            const SizedBox(height: 16),
          ],
          if (edgeError != null) ...[
            InfoBar(
              title: const Text('Inscription refusée'),
              content: Text(edgeError),
              severity: InfoBarSeverity.error,
            ),
            const SizedBox(height: 16),
          ],
          InfoLabel(
            label: "Code d'invitation",
            child: TextBox(
              controller: _codeCtrl,
              placeholder: 'ARENA-XXXX-XXXX-XXXX',
              enabled: !isLoading,
              maxLength: 20,
            ),
          ),
          const SizedBox(height: 16),
          InfoLabel(
            label: 'Email',
            child: TextBox(
              controller: _emailCtrl,
              placeholder: 'admin@arena.app',
              enabled: !isLoading,
            ),
          ),
          const SizedBox(height: 16),
          InfoLabel(
            label: 'Nom affiché',
            child: TextBox(
              controller: _usernameCtrl,
              placeholder: 'Jean Admin',
              enabled: !isLoading,
            ),
          ),
          const SizedBox(height: 16),
          InfoLabel(
            label: 'Mot de passe',
            child: PasswordBox(
              controller: _passwordCtrl,
              placeholder: 'Au moins 12 caractères',
              enabled: !isLoading,
            ),
          ),
          const SizedBox(height: 16),
          InfoLabel(
            label: 'Confirmer le mot de passe',
            child: PasswordBox(
              controller: _confirmCtrl,
              placeholder: '••••••••••••',
              enabled: !isLoading,
              onSubmitted: (_) => _submit(),
            ),
          ),
          const SizedBox(height: 16),
          Checkbox(
            checked: _cguChecked,
            onChanged: isLoading
                ? null
                : (v) => setState(() => _cguChecked = v ?? false),
            content: const Text(
              "J'accepte les CGU admin (responsabilité accrue, audit, "
              'accès aux données joueurs).',
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
                  : const Text('VALIDER LE CODE'),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.center,
            child: HyperlinkButton(
              onPressed:
                  isLoading ? null : () => context.go(AdminDesktopRoutes.login),
              child: const Text(
                'Déjà un compte ? Se connecter',
                style: TextStyle(color: ArenaColors.silver),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
