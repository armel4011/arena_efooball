import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/repositories/competition_repository.dart';
import 'package:arena/features_shared/prize_ranks.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_divider.dart';
import 'package:arena/features_user/payments/payment_method.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Final inscription confirmation before payment (PHASE 4 + 11bis).
///
/// Deux flow possibles :
///   • Compétition **gratuite** (`registration_fee = 0`) → INSERT direct
///     dans `competition_registrations` (RLS self-insert) + retour HOME.
///   • Compétition **payante** → routing vers P1 PaymentMethodPicker
///     puis P2 avec le code marchand correspondant.
///
/// Maps to screen #12 of `arena_v2.html`.
class RegistrationConfirmPage extends ConsumerStatefulWidget {
  const RegistrationConfirmPage({
    required this.competitionId,
    required this.competitionName,
    required this.gameLabel,
    required this.gameEmoji,
    required this.dateLabel,
    required this.formatLabel,
    required this.entryFeeXaf,
    required this.totalPrizeXaf,
    required this.prizeDistribution,
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

  /// Pourcentages de gains par rang, fournis par la compétition.
  final List<int> prizeDistribution;

  @override
  ConsumerState<RegistrationConfirmPage> createState() =>
      _RegistrationConfirmPageState();
}

class _RegistrationConfirmPageState
    extends ConsumerState<RegistrationConfirmPage> {
  bool _ack = false;
  bool _submitting = false;

  bool get _isFree => widget.entryFeeXaf == 0;

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
              isFree: _isFree,
            ).animate().fadeIn(duration: ArenaDurations.medium),
            const SizedBox(height: ArenaSpacing.lg),
            if (!_isFree) ...[
              _SectionLabel('Paiement'),
              const SizedBox(height: ArenaSpacing.sm),
              _PaymentBreakdown(entryFeeXaf: widget.entryFeeXaf)
                  .animate(delay: 100.ms)
                  .fadeIn(duration: ArenaDurations.medium),
              const SizedBox(height: ArenaSpacing.lg),
            ],
            _SectionLabel('Récompense du tournoi'),
            const SizedBox(height: ArenaSpacing.sm),
            _PrizeDistribution(
              totalXaf: widget.totalPrizeXaf,
              distribution: widget.prizeDistribution,
            )
                .animate(delay: 200.ms)
                .fadeIn(duration: ArenaDurations.medium),
            const SizedBox(height: ArenaSpacing.lg),
            _AckTile(
              checked: _ack,
              onChanged: (v) => setState(() => _ack = v),
            ),
            const SizedBox(height: ArenaSpacing.xl),
            ArenaButton(
              label: _isFree
                  ? "M'INSCRIRE GRATUITEMENT"
                  : 'PROCÉDER AU PAIEMENT '
                      '· ${_formatXaf(widget.entryFeeXaf)} XAF',
              fullWidth: true,
              size: ArenaButtonSize.large,
              isLoading: _submitting,
              onPressed: (_ack && !_submitting) ? _onSubmit : null,
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

  Future<void> _onSubmit() async {
    setState(() => _submitting = true);
    try {
      if (_isFree) {
        await ref
            .read(competitionRepositoryProvider)
            .registerSelfFree(widget.competitionId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Inscription confirmée à ${widget.competitionName}.'),
            backgroundColor: ArenaColors.statusOk,
          ),
        );
        context.go(UserRoutes.home);
      } else {
        // Récupère la compétition pour passer les codes marchands à la P2.
        final comp = await ref
            .read(competitionRepositoryProvider)
            .getById(widget.competitionId);
        if (!mounted) return;
        // P1 picker → on capture la méthode puis on push P2 avec le code.
        final selected = await context.push<PaymentMethod>(
          UserRoutes.paymentMethodPicker,
          extra: PaymentPickerArgs(
            amountXaf: widget.entryFeeXaf,
            contextLabel: widget.competitionName,
          ),
        );
        if (selected == null || !mounted) {
          setState(() => _submitting = false);
          return;
        }
        final merchantCode = switch (selected) {
          PaymentMethod.mtnMoMo => comp?.mtnMomoCode,
          PaymentMethod.orangeMoney => comp?.orangeMoneyCode,
        };
        if (!mounted) return;
        context.go(
          UserRoutes.paymentMomoDetails,
          extra: PaymentMomoArgs(
            method: selected,
            amountXaf: widget.entryFeeXaf,
            competitionId: widget.competitionId,
            competitionName: widget.competitionName,
            merchantCode: merchantCode ?? '',
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    }
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
    required this.isFree,
  });

  final String name;
  final String gameLabel;
  final String gameEmoji;
  final String dateLabel;
  final String formatLabel;
  final bool isFree;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.lg),
      decoration: arenaGlowCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(name, style: ArenaText.h2)),
              if (isFree)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: ArenaColors.statusOk.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(ArenaRadius.round),
                    border: Border.all(
                      color: ArenaColors.statusOk.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    'GRATUIT',
                    style: ArenaText.button.copyWith(
                      color: ArenaColors.statusOk,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
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
  const _PrizeDistribution({
    required this.totalXaf,
    required this.distribution,
  });

  final int totalXaf;

  /// Pourcentages de gains par rang, fournis par la compétition
  /// (ex. `[50, 25, 15, 10]`). On n'affiche que les rangs > 0.
  final List<int> distribution;

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
          for (var i = 0;
              i < distribution.length && i < kMaxRewardedRanks;
              i++)
            if (distribution[i] > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(
                      prizeRankEmoji(i),
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: ArenaSpacing.sm),
                    Expanded(
                      child: Text(
                        '${prizeRankLabel(i)} place',
                        style: ArenaText.body,
                      ),
                    ),
                    Text(
                      '${_formatXaf((totalXaf * distribution[i] / 100).round())}'
                      ' XAF',
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
