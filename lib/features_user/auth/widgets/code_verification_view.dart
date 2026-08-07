import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_code_input.dart';
import 'package:arena/features_user/auth/widgets/auth_error_banner.dart';
import 'package:flutter/material.dart';

/// Mise en page pro et partagée pour la saisie d'un code à 6 chiffres.
///
/// Utilisée par la confirmation d'inscription (étape OTP) et par la
/// réinitialisation de mot de passe — même look, même comportement :
/// badge d'en-tête, titre, email en évidence, champ segmenté
/// ([ArenaCodeInput]), bouton de validation et lien de renvoi.
class CodeVerificationView extends StatelessWidget {
  const CodeVerificationView({
    required this.title,
    required this.subtitle,
    required this.email,
    required this.controller,
    required this.verifyLabel,
    required this.resendLabel,
    required this.resendingLabel,
    required this.onVerify,
    required this.onResend,
    required this.isLoading,
    required this.resending,
    this.errorMessage,
    this.icon = Icons.mark_email_read_outlined,
    super.key,
  });

  final String title;
  final String subtitle;
  final String email;
  final TextEditingController controller;
  final String verifyLabel;
  final String resendLabel;
  final String resendingLabel;
  final VoidCallback onVerify;
  final VoidCallback onResend;
  final bool isLoading;
  final bool resending;
  final String? errorMessage;
  final IconData icon;

  bool get _isComplete => controller.text.trim().length == 6;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ArenaSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: ArenaSpacing.md),
          // Badge d'en-tête.
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: ArenaColors.surfaceLight,
                shape: BoxShape.circle,
                border: Border.all(color: ArenaColors.borderHi),
              ),
              child: Icon(icon, size: 32, color: ArenaColors.primary),
            ),
          ),
          const SizedBox(height: ArenaSpacing.lg),
          Text(
            title,
            textAlign: TextAlign.center,
            style: ArenaTypography.displayMedium,
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: ArenaTypography.bodyMedium.copyWith(
              color: ArenaColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            textAlign: TextAlign.center,
            style: ArenaTypography.labelLarge.copyWith(
              color: ArenaColors.primary,
            ),
          ),
          const SizedBox(height: ArenaSpacing.xl),
          ArenaCodeInput(
            controller: controller,
            enabled: !isLoading,
            hasError: errorMessage != null,
            // Auto-validation dès que les 6 chiffres sont saisis.
            onCompleted: () {
              if (!isLoading) onVerify();
            },
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: ArenaSpacing.md),
            AuthErrorBanner(message: errorMessage!),
          ],
          const SizedBox(height: ArenaSpacing.xl),
          ArenaButton(
            label: verifyLabel,
            fullWidth: true,
            size: ArenaButtonSize.large,
            isLoading: isLoading,
            onPressed: _isComplete && !isLoading ? onVerify : null,
          ),
          const SizedBox(height: ArenaSpacing.md),
          Center(
            child: TextButton(
              onPressed: isLoading || resending ? null : onResend,
              child: Text(resending ? resendingLabel : resendLabel),
            ),
          ),
        ],
      ),
    );
  }
}
