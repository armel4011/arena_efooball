import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_stepper.dart';
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
  static const _stepTitles = <String>[
    "Pièce d'identité (recto)",
    "Pièce d'identité (verso)",
    'Selfie de vérification',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ArenaAppBar(title: 'Vérification KYC'),
      body: SafeArea(
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
              'Étape ${_step + 1} / $_stepCount — ${_stepTitles[_step]}',
              style: ArenaText.bodyMuted,
            ),
            const SizedBox(height: ArenaSpacing.lg),
            Text('DOCUMENTS ACCEPTÉS', style: ArenaText.inputLabel),
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
                  ? 'ENVOYER POUR VÉRIFICATION'
                  : 'SUIVANT (recto requis)',
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
    );
  }
}

class _PendingAmountCard extends StatelessWidget {
  const _PendingAmountCard({required this.amountXaf});

  final int amountXaf;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.lg),
      decoration: arenaWarningCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💰 Gain de ${_formatXaf(amountXaf)} XAF',
            style: ArenaText.h3,
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Text(
            "Pour ce montant, on doit vérifier ton identité avant le payout. "
            "C'est rapide (sous 24h).",
            style: ArenaText.body,
          ),
        ],
      ),
    );
  }
}

class _AcceptedDocs extends StatelessWidget {
  const _AcceptedDocs();

  static const _docs = <(String, String)>[
    ('🪪', "Carte d'identité nationale"),
    ('📘', 'Passeport'),
    ('🚗', 'Permis de conduire'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(color: ArenaColors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < _docs.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ArenaSpacing.md,
                vertical: 12,
              ),
              child: Row(
                children: [
                  Text(_docs[i].$1,
                      style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: ArenaSpacing.sm),
                  Expanded(
                    child: Text(_docs[i].$2, style: ArenaText.body),
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
    if (captured) {
      return Container(
        padding: const EdgeInsets.all(ArenaSpacing.lg),
        decoration: arenaSuccessCardDecoration(),
        child: Column(
          children: [
            const Icon(Icons.check_circle,
                size: 48, color: ArenaColors.statusOk),
            const SizedBox(height: ArenaSpacing.sm),
            Text('Photo capturée', style: ArenaText.h3),
            const SizedBox(height: ArenaSpacing.sm),
            ArenaButton(
              label: 'REPRENDRE',
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
            'Photographier le recto',
            style: ArenaText.body.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Bonne lumière, photo nette, pas de reflets',
            textAlign: TextAlign.center,
            style: ArenaText.bodyMuted,
          ),
          const SizedBox(height: ArenaSpacing.md),
          ArenaButton(
            label: '📸 PRENDRE EN PHOTO',
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
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: arenaGlowCardDecoration(),
      child: RichText(
        text: TextSpan(
          style: ArenaText.body,
          children: [
            const TextSpan(text: '🔒 '),
            TextSpan(
              text: 'Sécurité : ',
              style: ArenaText.body.copyWith(fontWeight: FontWeight.w700),
            ),
            const TextSpan(
              text: 'tes documents sont chiffrés et utilisés uniquement '
                  'pour la vérification réglementaire.',
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
