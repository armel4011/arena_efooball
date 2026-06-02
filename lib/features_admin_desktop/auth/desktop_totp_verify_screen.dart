import 'package:arena/core/utils/arena_error_message.dart';
import 'package:arena/features_admin/auth_admin/admin_auth_providers.dart';
import 'package:arena/features_admin_desktop/auth/desktop_auth_scaffold.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Vérification du 2e facteur (TOTP) au login desktop.
///
/// Accepte un code 6 chiffres (Google Authenticator) ou un backup code
/// `XXXX-XXXX`. Sur succès, [adminTotpSessionProvider] est marqué vérifié
/// et le routeur redirige vers le dashboard.
class DesktopTotpVerifyScreen extends ConsumerStatefulWidget {
  const DesktopTotpVerifyScreen({super.key});

  @override
  ConsumerState<DesktopTotpVerifyScreen> createState() =>
      _DesktopTotpVerifyScreenState();
}

class _DesktopTotpVerifyScreenState
    extends ConsumerState<DesktopTotpVerifyScreen> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    await ref.read(adminTotpVerifyControllerProvider.notifier).verify(code);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminTotpVerifyControllerProvider);
    final isLoading = state.isLoading;
    final error = state.hasError ? state.error : null;

    return DesktopAuthScaffold(
      title: 'Vérification en deux étapes',
      subtitle: 'Saisissez le code à 6 chiffres de votre application '
          "d'authentification, ou un code de secours (XXXX-XXXX).",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (error != null) ...[
            InfoBar(
              title: const Text('Code refusé'),
              content: Text(arenaErrorMessage(error)),
              severity: InfoBarSeverity.error,
            ),
            const SizedBox(height: 16),
          ],
          InfoLabel(
            label: 'Code TOTP',
            child: TextBox(
              controller: _codeController,
              placeholder: '123456',
              enabled: !isLoading,
              autofocus: true,
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
                  : const Text('VÉRIFIER'),
            ),
          ),
        ],
      ),
    );
  }
}
