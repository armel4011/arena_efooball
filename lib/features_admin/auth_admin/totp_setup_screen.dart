import 'package:arena/core/router/admin_router.dart';
import 'package:arena/core/theme/arena_colors.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/theme/arena_typography.dart';
import 'package:arena/data/repositories/auth_failure.dart';
import 'package:arena/features_admin/auth_admin/admin_auth_providers.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:arena/features_user/auth/widgets/auth_failure_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// PHASE 2bis sub-flow B.3 — TOTP setup at first login.
///
/// Flow :
/// 1. On mount, ask the controller for a fresh challenge (QR + secret).
/// 2. User scans the QR with Google Authenticator.
/// 3. User types the 6-digit code → controller verifies → backup codes
///    are returned and shown ONCE.
/// 4. User must check "I saved my codes" before continuing to dashboard.
class TotpSetupScreen extends ConsumerStatefulWidget {
  const TotpSetupScreen({super.key});

  @override
  ConsumerState<TotpSetupScreen> createState() => _TotpSetupScreenState();
}

class _TotpSetupScreenState extends ConsumerState<TotpSetupScreen> {
  final _codeCtrl = TextEditingController();
  bool _backupAcknowledged = false;

  @override
  void initState() {
    super.initState();
    // Fire once after the first build so Riverpod has a chance to set up.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminTotpSetupControllerProvider.notifier).requestChallenge();
    });
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminTotpSetupControllerProvider);
    final isLoading = state.isLoading;
    final value = state.value;
    final errorMessage = state.hasError
        ? authFailureToMessage(_asFailure(state.error))
        : null;

    final challenge = value?.challenge;
    final backupCodes = value?.backupCodes;
    final showBackup = backupCodes != null && backupCodes.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Configuration TOTP'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(ArenaSpacing.lg),
          child: showBackup
              ? _BackupCodesView(
                  codes: backupCodes,
                  acknowledged: _backupAcknowledged,
                  onAck: (v) => setState(() => _backupAcknowledged = v),
                  onContinue: _backupAcknowledged
                      ? () => context.go(AdminRoutes.home)
                      : null,
                )
              : _SetupView(
                  challenge: challenge,
                  isLoading: isLoading && challenge == null,
                  isVerifying: isLoading && challenge != null,
                  errorMessage: errorMessage,
                  codeCtrl: _codeCtrl,
                  onVerify: () {
                    if (_codeCtrl.text.length != 6) return;
                    ref
                        .read(adminTotpSetupControllerProvider.notifier)
                        .verify(_codeCtrl.text);
                  },
                  onRetry: () => ref
                      .read(adminTotpSetupControllerProvider.notifier)
                      .requestChallenge(),
                ),
        ),
      ),
    );
  }
}

class _SetupView extends StatelessWidget {
  const _SetupView({
    required this.challenge,
    required this.isLoading,
    required this.isVerifying,
    required this.errorMessage,
    required this.codeCtrl,
    required this.onVerify,
    required this.onRetry,
  });

  final TotpSetupChallenge? challenge;
  final bool isLoading;
  final bool isVerifying;
  final String? errorMessage;
  final TextEditingController codeCtrl;
  final VoidCallback onVerify;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 64),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (challenge == null && errorMessage != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: ArenaSpacing.lg),
          _ErrorBanner(message: errorMessage!),
          const SizedBox(height: ArenaSpacing.md),
          ArenaButton(
            label: 'RÉESSAYER',
            fullWidth: true,
            onPressed: onRetry,
          ),
        ],
      );
    }
    if (challenge == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '1. Installe Google Authenticator',
          style: ArenaTypography.headlineMedium,
        ),
        const SizedBox(height: ArenaSpacing.sm),
        Text(
          'Disponible sur Google Play et App Store. Tu peux aussi'
          " utiliser Authy ou Microsoft Authenticator.",
          style: ArenaTypography.bodyMedium.copyWith(
            color: ArenaColors.textMuted,
          ),
        ),
        const SizedBox(height: ArenaSpacing.xl),
        Text(
          '2. Scanne ce QR code',
          style: ArenaTypography.headlineMedium,
        ),
        const SizedBox(height: ArenaSpacing.md),
        Center(
          child: Container(
            padding: const EdgeInsets.all(ArenaSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: ArenaRadius.card,
            ),
            child: QrImageView(
              data: challenge!.otpauthUri,
              size: 220,
              backgroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: ArenaSpacing.md),
        Center(
          child: Column(
            children: [
              Text(
                'Ou entre ce code manuellement :',
                style: ArenaTypography.bodySmall.copyWith(
                  color: ArenaColors.textMuted,
                ),
              ),
              const SizedBox(height: ArenaSpacing.sm),
              SelectableText(
                challenge!.secret,
                style: ArenaTypography.codeMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: ArenaSpacing.xl),
        Text(
          '3. Entre le code à 6 chiffres',
          style: ArenaTypography.headlineMedium,
        ),
        const SizedBox(height: ArenaSpacing.md),
        ArenaTextField(
          label: 'CODE TOTP',
          hint: '123 456',
          controller: codeCtrl,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          prefixIcon: Icons.numbers,
          enabled: !isVerifying,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: ArenaSpacing.sm),
          _ErrorBanner(message: errorMessage!),
        ],
        const SizedBox(height: ArenaSpacing.lg),
        ArenaButton(
          label: 'VÉRIFIER & ACTIVER',
          fullWidth: true,
          size: ArenaButtonSize.large,
          isLoading: isVerifying,
          onPressed: onVerify,
        ),
      ],
    );
  }
}

class _BackupCodesView extends StatelessWidget {
  const _BackupCodesView({
    required this.codes,
    required this.acknowledged,
    required this.onAck,
    required this.onContinue,
  });

  final List<String> codes;
  final bool acknowledged;
  final ValueChanged<bool> onAck;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'CODES DE RÉCUPÉRATION',
          style: ArenaTypography.displayMedium,
        ),
        const SizedBox(height: ArenaSpacing.sm),
        Container(
          padding: const EdgeInsets.all(ArenaSpacing.md),
          decoration: BoxDecoration(
            color: ArenaColors.warning.withValues(alpha: 0.12),
            borderRadius: ArenaRadius.button,
            border: Border.all(
              color: ArenaColors.warning.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: ArenaColors.warning),
              const SizedBox(width: ArenaSpacing.sm),
              Expanded(
                child: Text(
                  'Note ces codes maintenant. Ils ne seront plus jamais'
                  ' affichés. Si tu perds ton téléphone, ils sont ton'
                  ' seul moyen de retrouver ton compte.',
                  style: ArenaTypography.bodySmall,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: ArenaSpacing.lg),
        Container(
          padding: const EdgeInsets.all(ArenaSpacing.md),
          decoration: BoxDecoration(
            color: ArenaColors.surface,
            borderRadius: ArenaRadius.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final c in codes)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: SelectableText(
                    c,
                    style: ArenaTypography.codeMedium,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: ArenaSpacing.md),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: acknowledged,
          onChanged: (v) => onAck(v ?? false),
          title: const Text('J\'ai sauvegardé mes codes en lieu sûr'),
        ),
        const SizedBox(height: ArenaSpacing.lg),
        ArenaButton(
          label: 'CONTINUER',
          fullWidth: true,
          size: ArenaButtonSize.large,
          onPressed: onContinue,
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
