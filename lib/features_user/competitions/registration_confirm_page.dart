import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_divider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Final inscription confirmation before payment (PHASE 4 + 11bis).
///
/// Reached from `CompetitionDetailPage` CTA "S'inscrire" — shows a summary
/// of the competition, fee breakdown, prize distribution, and routes to
/// the payment picker on confirmation. Wave 1 ships the v2 visual; the
/// payment flow itself lives in PHASE 11bis (`/payments/*`).
///
/// Maps to screen #12 of `arena_v2.html`.
class RegistrationConfirmPage extends StatefulWidget {
  const RegistrationConfirmPage({
    required this.competitionId,
    required this.competitionName,
    required this.gameLabel,
    required this.gameEmoji,
    required this.dateLabel,
    required this.formatLabel,
    required this.entryFeeXaf,
    required this.totalPrizeXaf,
    super.key,
  });

  final String competitionId;
  final String competitionName;
  final String gameLabel;
  final String gameEmoji;
  final String dateLabel;
  final String formatLabel;
  final int entryFeeXaf;
  final int totalPrizeXaf;

  @override
  State<RegistrationConfirmPage> createState() =>
      _RegistrationConfirmPageState();
}

class _RegistrationConfirmPageState extends State<RegistrationConfirmPage> {
  bool _ack = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ArenaAppBar(title: 'Confirmer inscription'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(ArenaSpacing.lg),
          children: [
            _CompetitionSummary(
              name: widget.competitionName,
              gameLabel: widget.gameLabel,
              gameEmoji: widget.gameEmoji,
              dateLabel: widget.dateLabel,
              formatLabel: widget.formatLabel,
            ).animate().fadeIn(duration: ArenaDurations.medium),
            const SizedBox(height: ArenaSpacing.lg),
            _SectionLabel('Paiement'),
            const SizedBox(height: ArenaSpacing.sm),
            _PaymentBreakdown(entryFeeXaf: widget.entryFeeXaf)
                .animate(delay: 100.ms)
                .fadeIn(duration: ArenaDurations.medium),
            const SizedBox(height: ArenaSpacing.lg),
            _SectionLabel('Récompense du tournoi'),
            const SizedBox(height: ArenaSpacing.sm),
            _PrizeDistribution(totalXaf: widget.totalPrizeXaf)
                .animate(delay: 200.ms)
                .fadeIn(duration: ArenaDurations.medium),
            const SizedBox(height: ArenaSpacing.lg),
            _AckTile(
              checked: _ack,
              onChanged: (v) => setState(() => _ack = v),
            ),
            const SizedBox(height: ArenaSpacing.xl),
            ArenaButton(
              label: 'PROCÉDER AU PAIEMENT '
                  '· ${_formatXaf(widget.entryFeeXaf)} XAF',
              fullWidth: true,
              size: ArenaButtonSize.large,
              onPressed: _ack ? () => _onPay(context) : null,
            ),
            const SizedBox(height: ArenaSpacing.sm),
            ArenaButton(
              label: 'Annuler',
              fullWidth: true,
              variant: ArenaButtonVariant.ghost,
              onPressed: () => Navigator.maybePop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _onPay(BuildContext context) {
    // Routed in PHASE 11bis when /payments/method-picker lands. For wave 1
    // the CTA acknowledges the action so the user gets feedback.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Paiement disponible en PHASE 11bis (CinetPay + NowPayments).',
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label.toUpperCase(), style: ArenaText.inputLabel);
  }
}

class _CompetitionSummary extends StatelessWidget {
  const _CompetitionSummary({
    required this.name,
    required this.gameLabel,
    required this.gameEmoji,
    required this.dateLabel,
    required this.formatLabel,
  });

  final String name;
  final String gameLabel;
  final String gameEmoji;
  final String dateLabel;
  final String formatLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.lg),
      decoration: arenaGlowCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: ArenaText.h2),
          const SizedBox(height: ArenaSpacing.sm),
          Text('$gameEmoji $gameLabel', style: ArenaText.bodyMuted),
          const SizedBox(height: 2),
          Text('🗓 $dateLabel', style: ArenaText.bodyMuted),
          const SizedBox(height: 2),
          Text('🏆 $formatLabel', style: ArenaText.bodyMuted),
        ],
      ),
    );
  }
}

class _PaymentBreakdown extends StatelessWidget {
  const _PaymentBreakdown({required this.entryFeeXaf});

  final int entryFeeXaf;

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
          _Row(label: "Frais d'inscription", value: '${_formatXaf(entryFeeXaf)} XAF'),
          const ArenaDivider(),
          _Row(label: 'Frais de service', value: 'Inclus'),
          const ArenaDivider(),
          _Row(
            label: 'Total à payer',
            value: '${_formatXaf(entryFeeXaf)} XAF',
            emphasis: true,
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.emphasis = false});
  final String label;
  final String value;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ArenaSpacing.md,
        vertical: 10,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: emphasis ? ArenaText.h3 : ArenaText.bodyMuted,
            ),
          ),
          Text(
            value,
            style: emphasis
                ? ArenaText.monoLg.copyWith(color: ArenaColors.signalBlue)
                : ArenaText.mono,
          ),
        ],
      ),
    );
  }
}

class _PrizeDistribution extends StatelessWidget {
  const _PrizeDistribution({required this.totalXaf});

  final int totalXaf;

  static const _shares = <(String, String, double)>[
    ('🥇', '1ʳᵉ place', 0.5),
    ('🥈', '2ᵉ place', 0.3),
    ('🥉', '3ᵉ place', 0.2),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.lg),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(color: ArenaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(
              '${_formatXaf(totalXaf)} XAF',
              style: ArenaText.bigNumber.copyWith(color: ArenaColors.statusOk),
            ),
          ),
          const SizedBox(height: ArenaSpacing.md),
          for (final (emoji, label, share) in _shares)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: ArenaSpacing.sm),
                  Expanded(child: Text(label, style: ArenaText.body)),
                  Text(
                    '${_formatXaf((totalXaf * share).round())} XAF',
                    style: ArenaText.mono,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AckTile extends StatelessWidget {
  const _AckTile({required this.checked, required this.onChanged});
  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!checked),
      borderRadius: BorderRadius.circular(ArenaRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(ArenaSpacing.md),
        decoration: BoxDecoration(
          color: ArenaColors.carbon,
          borderRadius: BorderRadius.circular(ArenaRadius.lg),
          border: Border.all(
            color: checked ? ArenaColors.signalBlue : ArenaColors.border,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(value: checked, onChanged: (v) => onChanged(v ?? false)),
            const SizedBox(width: ArenaSpacing.sm),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  "J'accepte les règles du tournoi et le règlement intérieur.",
                  style: ArenaText.body,
                ),
              ),
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
