import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// PHASE 7 — recording-blocked landing page.
///
/// Shown when the system-overlay permission, foreground services or
/// battery-saver block the screen recorder. The user has two ways out:
/// fix the OS settings and retry, or forfeit the match. Reproduces
/// `arena_v2.html` #18 — danger-card cause + numbered solution list +
/// retry / forfeit / contact CTAs.
///
/// Maps to screen #18 of `arena_v2.html`.
class RecordingErrorPage extends StatelessWidget {
  const RecordingErrorPage({
    this.cause = 'SYSTEM_ALERT_WINDOW',
    this.onRetry,
    this.onForfeit,
    this.onContactSupport,
    super.key,
  });

  final String cause;
  final VoidCallback? onRetry;
  final VoidCallback? onForfeit;
  final VoidCallback? onContactSupport;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final solutions = <String>[
      l10n.recordingErrorSolutionStep1,
      l10n.recordingErrorSolutionStep2,
      l10n.recordingErrorSolutionStep3,
      l10n.recordingErrorSolutionStep4,
    ];
    return Scaffold(
      appBar: ArenaAppBar(title: l10n.recordingErrorAppBarTitle),
      body: ArenaScreenBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(ArenaSpacing.lg),
            children: [
              const _ErrorIcon().animate().fadeIn(
                    duration: ArenaDurations.medium,
                  ),
              const SizedBox(height: ArenaSpacing.md),
              Text(
                l10n.recordingErrorHeadline,
                textAlign: TextAlign.center,
                style: ArenaText.h1.copyWith(color: ArenaColors.neonRed),
              ),
              const SizedBox(height: ArenaSpacing.sm),
              Text(
                l10n.recordingErrorAntiCheatNotice,
                textAlign: TextAlign.center,
                style: ArenaText.body,
              ),
              const SizedBox(height: ArenaSpacing.lg),
              _CauseCard(cause: cause)
                  .animate(delay: 100.ms)
                  .fadeIn(duration: ArenaDurations.medium),
              const SizedBox(height: ArenaSpacing.lg),
              Text(
                l10n.recordingErrorSolutionsLabel,
                style: ArenaText.inputLabel,
              ),
              const SizedBox(height: ArenaSpacing.sm),
              _SolutionsCard(solutions: solutions)
                  .animate(delay: 200.ms)
                  .fadeIn(duration: ArenaDurations.medium),
              const SizedBox(height: ArenaSpacing.xl),
              ArenaButton(
                label: l10n.recordingErrorRetryButton,
                fullWidth: true,
                size: ArenaButtonSize.large,
                onPressed: onRetry ?? () => Navigator.maybePop(context),
              ),
              const SizedBox(height: ArenaSpacing.sm),
              ArenaButton(
                label: l10n.recordingErrorForfeitButton,
                variant: ArenaButtonVariant.danger,
                fullWidth: true,
                onPressed: onForfeit,
              ),
              const SizedBox(height: ArenaSpacing.lg),
              Center(
                child: TextButton(
                  onPressed: onContactSupport,
                  child: Text(
                    l10n.recordingErrorContactSupport,
                    style:
                        ArenaText.body.copyWith(color: ArenaColors.signalBlue),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorIcon extends StatelessWidget {
  const _ErrorIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: ArenaColors.neonRed.withValues(alpha: 0.45),
              blurRadius: 32,
              spreadRadius: -2,
            ),
          ],
        ),
        child: const Text('🚫', style: TextStyle(fontSize: 60)),
      ),
    );
  }
}

class _CauseCard extends StatelessWidget {
  const _CauseCard({required this.cause});
  final String cause;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.lg),
      decoration: arenaDangerCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.recordingErrorCauseTitle, style: ArenaText.h3),
          const SizedBox(height: ArenaSpacing.sm),
          RichText(
            text: TextSpan(
              style: ArenaText.bodyMuted,
              children: [
                TextSpan(text: l10n.recordingErrorCausePermissionPrefix),
                TextSpan(
                  text: cause,
                  style: ArenaText.mono.copyWith(color: ArenaColors.neonRed),
                ),
                TextSpan(text: l10n.recordingErrorCausePermissionSuffix),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SolutionsCard extends StatelessWidget {
  const _SolutionsCard({required this.solutions});
  final List<String> solutions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(color: ArenaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < solutions.length; i++)
            Padding(
              padding: EdgeInsets.only(
                bottom: i == solutions.length - 1 ? 0 : ArenaSpacing.sm,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 22,
                    child: Text(
                      '${i + 1}.',
                      style: ArenaText.bodyMuted.copyWith(
                        color: ArenaColors.signalBlue,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(solutions[i], style: ArenaText.body),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
