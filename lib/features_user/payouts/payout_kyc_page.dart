import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/features_shared/widgets/arena_stepper.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// PHASE 11bis · P7 — KYC document capture for large payouts.
///
/// Triggered when a player's pending payout crosses the regulatory
/// threshold (V1.0 = 100 000 XAF). Three-step capture: ID recto +
/// ID verso + selfie. The submission goes to the admin queue for
/// manual review (24h SLA target). This first wave only ships the
/// recto step — subsequent steps reuse the same layout.
///
/// Maps to screen P7 of `arena_v2.html`.
class PayoutKycPage extends StatefulWidget {
  const PayoutKycPage({
    required this.pendingAmountXaf,
    super.key,
  });

  final int pendingAmountXaf;

  @override
  State<PayoutKycPage> createState() => _PayoutKycPageState();
}

class _PayoutKycPageState extends State<PayoutKycPage> {
  int _step = 0;
  bool _captured = false;

  static const _stepCount = 3;

  List<String> _stepTitles(AppLocalizations l10n) => <String>[
        l10n.payoutKycStepIdRecto,
        l10n.payoutKycStepIdVerso,
        l10n.payoutKycStepSelfie,
      ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: ArenaAppBar(title: l10n.payoutKycAppBarTitle),
      body: ArenaScreenBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(ArenaSpacing.lg),
            children: [
              _PendingAmountCard(amountXaf: widget.pendingAmountXaf)
                  .animate()
                  .fadeIn(duration: ArenaDurations.medium),
              const SizedBox(height: ArenaSpacing.lg),
              ArenaStepper(totalSteps: _stepCount, currentStep: _step),
              const SizedBox(height: ArenaSpacing.sm),
              Text(
                'ÉTAPE ${(_step + 1).toString().padLeft(2, '0')}/$_stepCount · ${_stepTitles(l10n)[_step].toUpperCase()}',
                style: ArenaText.monoSmall.copyWith(
                  color: ArenaColors.statusWarn,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: ArenaSpacing.lg),
              Text(
                l10n.payoutKycAcceptedDocsLabel,
                style: ArenaText.monoSmall.copyWith(
                  color: ArenaColors.silver,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: ArenaSpacing.sm),
              const _AcceptedDocs()
                  .animate(delay: 100.ms)
                  .fadeIn(duration: ArenaDurations.medium),
              const SizedBox(height: ArenaSpacing.lg),
              _CaptureCard(
                captured: _captured,
                onCapture: () => setState(() => _captured = true),
                onRetake: () => setState(() => _captured = false),
              ).animate(delay: 200.ms).fadeIn(
                    duration: ArenaDurations.medium,
                  ),
              const SizedBox(height: ArenaSpacing.md),
              const _SecurityNote(),
              const SizedBox(height: ArenaSpacing.xl),
              ArenaButton(
                label: _step == _stepCount - 1
                    ? l10n.payoutKycSubmitForReview
                    : l10n.payoutKycNextRectoRequired,
                fullWidth: true,
                size: ArenaButtonSize.large,
                onPressed: _captured
                    ? () {
                        if (_step == _stepCount - 1) {
                          Navigator.maybePop(context, true);
                        } else {
                          setState(() {
                            _step++;
                            _captured = false;
                          });
                        }
                      }
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingAmountCard extends StatelessWidget {
  const _PendingAmountCard({required this.amountXaf});

  final int amountXaf;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.lg),
      decoration: arenaWarningCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.payoutKycPendingGain(_formatXaf(amountXaf)),
            style: ArenaText.h3,
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Text(
            l10n.payoutKycPendingExplain,
            style: ArenaText.body,
          ),
        ],
      ),
    );
  }
}

class _AcceptedDocs extends StatelessWidget {
  const _AcceptedDocs();

  List<(String, String)> _docs(AppLocalizations l10n) => <(String, String)>[
        ('🪪', l10n.payoutKycDocNationalId),
        ('📘', l10n.payoutKycDocPassport),
        ('🚗', l10n.payoutKycDocDriverLicense),
      ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final docs = _docs(l10n);
    return Container(
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(color: ArenaColors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < docs.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ArenaSpacing.md,
                vertical: 12,
              ),
              child: Row(
                children: [
                  Text(
                    docs[i].$1,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: ArenaSpacing.sm),
                  Expanded(
                    child: Text(docs[i].$2, style: ArenaText.body),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CaptureCard extends StatelessWidget {
  const _CaptureCard({
    required this.captured,
    required this.onCapture,
    required this.onRetake,
  });

  final bool captured;
  final VoidCallback onCapture;
  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (captured) {
      return Container(
        padding: const EdgeInsets.all(ArenaSpacing.lg),
        decoration: arenaSuccessCardDecoration(),
        child: Column(
          children: [
            const Icon(
              Icons.check_circle,
              size: 48,
              color: ArenaColors.statusOk,
            ),
            const SizedBox(height: ArenaSpacing.sm),
            Text(l10n.payoutKycPhotoCaptured, style: ArenaText.h3),
            const SizedBox(height: ArenaSpacing.sm),
            ArenaButton(
              label: l10n.payoutKycRetake,
              variant: ArenaButtonVariant.secondary,
              onPressed: onRetake,
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.xl),
      decoration: BoxDecoration(
        color: ArenaColors.signalBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(
          color: ArenaColors.signalBlue,
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          const Text('📷', style: TextStyle(fontSize: 42)),
          const SizedBox(height: ArenaSpacing.sm),
          Text(
            l10n.payoutKycPhotographFront,
            style: ArenaText.body.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.payoutKycCaptureHint,
            textAlign: TextAlign.center,
            style: ArenaText.bodyMuted,
          ),
          const SizedBox(height: ArenaSpacing.md),
          ArenaButton(
            label: l10n.payoutKycTakePhoto,
            onPressed: onCapture,
          ),
        ],
      ),
    );
  }
}

class _SecurityNote extends StatelessWidget {
  const _SecurityNote();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: arenaGlowCardDecoration(),
      child: RichText(
        text: TextSpan(
          style: ArenaText.body,
          children: [
            const TextSpan(text: '🔒 '),
            TextSpan(
              text: l10n.payoutKycSecurityLabel,
              style: ArenaText.body.copyWith(fontWeight: FontWeight.w700),
            ),
            TextSpan(
              text: l10n.payoutKycSecurityNote,
            ),
          ],
        ),
      ),
    );
  }
}

String _formatXaf(int amount) {
  final s = amount.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  return buf.toString();
}
