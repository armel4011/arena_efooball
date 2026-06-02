import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/utils/arena_error_message.dart';
import 'package:arena/data/repositories/auth_failure.dart';
import 'package:arena/features_admin/auth_admin/admin_auth_providers.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

/// Step-up TOTP gate (version desktop Fluent) pour les actions admin
/// sensibles : validation de paiement, résolution de litige, ban, etc.
///
/// Équivalent de `TotpGate.confirm` (mobile) mais sous forme de
/// [ContentDialog] Fluent. Réutilise [adminTotpStepUpControllerProvider]
/// — le même contrôleur que le mobile, qui appelle l'Edge Function
/// `admin-stepup-totp`.
///
/// Retourne `true` quand l'admin a re-vérifié son code TOTP, `false`
/// quand il annule ou échoue.
///
/// En build debug, si le backend signale `BackendUnavailableFailure`
/// (EF non déployée), un bouton de contournement « DEV » apparaît pour
/// ne pas bloquer le workflow ; il est masqué en release.
Future<bool> showDesktopTotpGate(
  BuildContext context,
  WidgetRef ref, {
  required String reason,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => _DesktopTotpDialog(reason: reason),
  );
  ref.read(adminTotpStepUpControllerProvider.notifier).reset();
  return result ?? false;
}

class _DesktopTotpDialog extends ConsumerStatefulWidget {
  const _DesktopTotpDialog({required this.reason});

  final String reason;

  @override
  ConsumerState<_DesktopTotpDialog> createState() => _DesktopTotpDialogState();
}

class _DesktopTotpDialogState extends ConsumerState<_DesktopTotpDialog> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_codeController.text.length != 6) return;
    await ref
        .read(adminTotpStepUpControllerProvider.notifier)
        .verify(_codeController.text);
    if (!mounted) return;
    final state = ref.read(adminTotpStepUpControllerProvider);
    if (state.value ?? false) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminTotpStepUpControllerProvider);
    final isLoading = state.isLoading;
    final error = state.hasError ? state.error : null;
    final backendDown = error is BackendUnavailableFailure;

    return ContentDialog(
      constraints: const BoxConstraints(maxWidth: 420),
      title: Text(
        'VÉRIFICATION 2FA',
        style: GoogleFonts.bebasNeue(
          color: ArenaColors.bone,
          fontSize: 22,
          letterSpacing: 1.2,
        ),
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.reason,
            style: GoogleFonts.spaceGrotesk(
              color: ArenaColors.silver,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          InfoLabel(
            label: 'Code TOTP',
            child: TextBox(
              controller: _codeController,
              placeholder: '123 456',
              enabled: !isLoading,
              autofocus: true,
              maxLength: 6,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              onSubmitted: (_) => _submit(),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            InfoBar(
              title: const Text('Code refusé'),
              content: Text(arenaErrorMessage(error)),
              severity: InfoBarSeverity.error,
            ),
          ],
        ],
      ),
      actions: [
        Button(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
        if (backendDown && kDebugMode)
          Button(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continuer (DEV)'),
          ),
        FilledButton(
          onPressed: isLoading ? null : _submit,
          child: isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: ProgressRing(strokeWidth: 2.5),
                )
              : const Text('Confirmer'),
        ),
      ],
    );
  }
}
