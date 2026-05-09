import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_stepper.dart';
import 'package:flutter/material.dart';

/// PHASE 11 · A8 — 5-step competition creation wizard.
///
/// Steps : Infos → Format → Prix (Top 4) → Frais → Review. The current
/// implementation ships the Prix step (the most visually unique one);
/// remaining steps surface as terse placeholders since the full form
/// belongs to PHASE 11.2.
///
/// Maps to screen A8 of `arena_v2.html`.
class CreateCompetitionPage extends StatefulWidget {
  const CreateCompetitionPage({super.key});

  @override
  State<CreateCompetitionPage> createState() => _CreateCompetitionPageState();
}

class _CreateCompetitionPageState extends State<CreateCompetitionPage> {
  static const _stepCount = 5;
  int _step = 2;
  _PrizeMode _mode = _PrizeMode.percentage;

  static const _shares = <(String, String, double, Color)>[
    ('🥇', '1ère place', 0.50, ArenaColors.gameFifa),
    ('🥈', '2e place', 0.25, ArenaColors.silver),
    ('🥉', '3e place', 0.15, Color(0xFFCD7F32)),
    ('  ', '4e place', 0.10, ArenaColors.silverDim),
  ];

  static const _totalXaf = 60000;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ArenaAppBar(title: 'Nouvelle compét.'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(ArenaSpacing.lg),
          children: [
            ArenaStepper(totalSteps: _stepCount, currentStep: _step),
            const SizedBox(height: ArenaSpacing.sm),
            Text(
              'Étape ${_step + 1} / $_stepCount — Prix (Top 4)',
              style: ArenaText.bodyMuted,
            ),
            const SizedBox(height: ArenaSpacing.lg),
            _ModeCard(
              mode: _mode,
              onChanged: (m) => setState(() => _mode = m),
            ),
            const SizedBox(height: ArenaSpacing.lg),
            for (final (emoji, label, share, color) in _shares) ...[
              _ShareRow(
                emoji: emoji,
                label: label,
                share: share,
                color: color,
                amountXaf: (_totalXaf * share).round(),
              ),
              const SizedBox(height: ArenaSpacing.md),
            ],
            Container(
              padding: const EdgeInsets.all(ArenaSpacing.md),
              decoration: arenaSuccessCardDecoration(),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '✓ Total',
                      style: ArenaText.body
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    '100% · ${_formatXaf(_totalXaf)} XAF',
                    style: ArenaText.mono.copyWith(
                      color: ArenaColors.statusOk,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: ArenaSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: ArenaButton(
                    label: '← RETOUR',
                    variant: ArenaButtonVariant.secondary,
                    fullWidth: true,
                    onPressed: _step > 0
                        ? () => setState(() => _step--)
                        : null,
                  ),
                ),
                const SizedBox(width: ArenaSpacing.xs),
                Expanded(
                  child: ArenaButton(
                    label: 'SUIVANT →',
                    fullWidth: true,
                    onPressed: _step < _stepCount - 1
                        ? () => setState(() => _step++)
                        : () => Navigator.maybePop(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum _PrizeMode { percentage, fixed }

class _ModeCard extends StatelessWidget {
  const _ModeCard({required this.mode, required this.onChanged});

  final _PrizeMode mode;
  final ValueChanged<_PrizeMode> onChanged;

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
          Text('MODE DE DISTRIBUTION', style: ArenaText.inputLabel),
          const SizedBox(height: ArenaSpacing.sm),
          Row(
            children: [
              Expanded(
                child: ArenaButton(
                  label: '% POURCENTAGE',
                  variant: mode == _PrizeMode.percentage
                      ? ArenaButtonVariant.primary
                      : ArenaButtonVariant.secondary,
                  fullWidth: true,
                  onPressed: () => onChanged(_PrizeMode.percentage),
                ),
              ),
              const SizedBox(width: ArenaSpacing.xs),
              Expanded(
                child: ArenaButton(
                  label: '💰 MONTANTS FIXES',
                  variant: mode == _PrizeMode.fixed
                      ? ArenaButtonVariant.primary
                      : ArenaButtonVariant.secondary,
                  fullWidth: true,
                  onPressed: () => onChanged(_PrizeMode.fixed),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShareRow extends StatelessWidget {
  const _ShareRow({
    required this.emoji,
    required this.label,
    required this.share,
    required this.color,
    required this.amountXaf,
  });

  final String emoji;
  final String label;
  final double share;
  final Color color;
  final int amountXaf;

  @override
  Widget build(BuildContext context) {
    final pct = (share * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$emoji $label', style: ArenaText.inputLabel),
        const SizedBox(height: ArenaSpacing.xs),
        Row(
          children: [
            Container(
              width: 60,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ArenaColors.carbon,
                borderRadius: BorderRadius.circular(ArenaRadius.md),
                border: Border.all(color: ArenaColors.borderHi),
              ),
              child: Text('$pct', style: ArenaText.mono),
            ),
            const SizedBox(width: ArenaSpacing.xs),
            Text('%', style: ArenaText.bodyMuted),
            const SizedBox(width: ArenaSpacing.sm),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: share,
                  minHeight: 4,
                  backgroundColor: ArenaColors.carbon2,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ),
            const SizedBox(width: ArenaSpacing.sm),
            Text(
              _formatXaf(amountXaf),
              style: ArenaText.mono.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ],
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
