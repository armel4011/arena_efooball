import 'package:arena/core/router/admin_desktop_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/utils/arena_error_message.dart';
import 'package:arena/features_admin/auth_admin/admin_auth_providers.dart';
import 'package:arena/features_admin_desktop/auth/desktop_auth_scaffold.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Enrôlement TOTP au premier login admin sur desktop.
///
/// 3 étapes pilotées par [adminTotpSetupControllerProvider] :
///  1. `challenge == null`   → bouton « Générer le QR code »
///  2. `challenge != null`   → QR + secret manuel + champ code
///  3. `backupCodes != null` → affichage des codes de secours
class DesktopTotpSetupScreen extends ConsumerStatefulWidget {
  const DesktopTotpSetupScreen({super.key});

  @override
  ConsumerState<DesktopTotpSetupScreen> createState() =>
      _DesktopTotpSetupScreenState();
}

class _DesktopTotpSetupScreenState
    extends ConsumerState<DesktopTotpSetupScreen> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminTotpSetupControllerProvider);
    final isLoading = state.isLoading;
    final error = state.hasError ? state.error : null;
    final setup = state.valueOrNull;

    final challenge = setup?.challenge;
    final backupCodes = setup?.backupCodes;

    return DesktopAuthScaffold(
      title: 'Activer la double authentification',
      subtitle: backupCodes != null
          ? 'Conservez ces codes de secours en lieu sûr — ils ne seront '
              'plus jamais affichés.'
          : 'Le 2FA est obligatoire pour tous les comptes admin.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (error != null) ...[
            InfoBar(
              title: const Text('Erreur'),
              content: Text(arenaErrorMessage(error)),
              severity: InfoBarSeverity.error,
            ),
            const SizedBox(height: 16),
          ],

          // ─── Étape 3 : codes de secours ────────────────────────────
          if (backupCodes != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ArenaColors.carbon2,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  for (final code in backupCodes)
                    Text(
                      code,
                      style: GoogleFonts.spaceMono(
                        color: ArenaColors.bone,
                        fontSize: 15,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Button(
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: backupCodes.join('\n')),
                );
              },
              child: const Text('Copier les codes'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              // La session TOTP est déjà marquée vérifiée par verify() —
              // on rejoint simplement le dashboard.
              onPressed: () => context.go(AdminDesktopRoutes.dashboard),
              child: const Text("J'AI SAUVEGARDÉ MES CODES"),
            ),
          ]

          // ─── Étape 2 : QR + vérification ──────────────────────────
          else if (challenge != null) ...[
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                color: Colors.white,
                child: QrImageView(
                  data: challenge.otpauthUri,
                  size: 200,
                ),
              ),
            ),
            const SizedBox(height: 16),
            InfoLabel(
              label: 'Secret (saisie manuelle)',
              child: TextBox(
                readOnly: true,
                controller: TextEditingController(text: challenge.secret),
              ),
            ),
            const SizedBox(height: 16),
            InfoLabel(
              label: 'Premier code à 6 chiffres',
              child: TextBox(
                controller: _codeController,
                placeholder: '123456',
                enabled: !isLoading,
                onSubmitted: (_) => ref
                    .read(adminTotpSetupControllerProvider.notifier)
                    .verify(_codeController.text.trim()),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: isLoading
                  ? null
                  : () => ref
                      .read(adminTotpSetupControllerProvider.notifier)
                      .verify(_codeController.text.trim()),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        child: ProgressRing(strokeWidth: 2.5),
                      )
                    : const Text('ACTIVER LE 2FA'),
              ),
            ),
          ]

          // ─── Étape 1 : demander le challenge ───────────────────────
          else
            FilledButton(
              onPressed: isLoading
                  ? null
                  : () => ref
                      .read(adminTotpSetupControllerProvider.notifier)
                      .requestChallenge(),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        child: ProgressRing(strokeWidth: 2.5),
                      )
                    : const Text('GÉNÉRER LE QR CODE'),
              ),
            ),
        ],
      ),
    );
  }
}
