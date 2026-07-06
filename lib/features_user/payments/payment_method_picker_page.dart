import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/competition_payment_option.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/features_user/payments/payment_method.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// PHASE 11bis · P1 — picker d'opérateur Mobile Money.
///
/// Reçoit les [options] de paiement DÉJÀ filtrées sur le pays choisi par le
/// joueur (Orange Money, MTN MoMo, Wave, Moov… définis librement par l'admin
/// créateur). Sélection → retourne l'option choisie à la page appelante, qui
/// enchaîne sur P2.
class PaymentMethodPickerPage extends StatefulWidget {
  const PaymentMethodPickerPage({
    required this.amountXaf,
    required this.contextLabel,
    required this.options,
    this.onConfirm,
    super.key,
  });

  final int amountXaf;
  final String contextLabel;
  final List<CompetitionPaymentOption> options;
  final ValueChanged<CompetitionPaymentOption>? onConfirm;

  @override
  State<PaymentMethodPickerPage> createState() =>
      _PaymentMethodPickerPageState();
}

class _PaymentMethodPickerPageState extends State<PaymentMethodPickerPage> {
  late CompetitionPaymentOption? _selected =
      widget.options.isEmpty ? null : widget.options.first;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: ArenaAppBar(title: l10n.paymentPickerAppBarTitle),
      body: ArenaScreenBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(ArenaSpacing.lg),
            children: [
              _AmountCard(
                amountXaf: widget.amountXaf,
                contextLabel: widget.contextLabel,
              ).animate().fadeIn(duration: ArenaDurations.medium),
              const SizedBox(height: ArenaSpacing.lg),
              Text(
                l10n.paymentPickerMobileMoneySection,
                style: ArenaText.monoSmall.copyWith(
                  color: ArenaColors.silver,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: ArenaSpacing.sm),
              for (final o in widget.options)
                Padding(
                  padding: const EdgeInsets.only(bottom: ArenaSpacing.sm),
                  child: _OperatorTile(
                    option: o,
                    selected: _selected?.id == o.id,
                    onTap: () => setState(() => _selected = o),
                  ),
                ),
              const SizedBox(height: ArenaSpacing.xl),
              ArenaButton(
                label: l10n.paymentPickerContinueButton,
                fullWidth: true,
                size: ArenaButtonSize.large,
                onPressed: _selected == null
                    ? null
                    : () {
                        final choice = _selected!;
                        final cb = widget.onConfirm;
                        if (cb != null) {
                          cb(choice);
                        } else {
                          Navigator.maybePop(context, choice);
                        }
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card centrée façon maquette P1 : caption mono "MONTANT À PAYER" +
/// chiffre big signalBlue 32px + sous-titre `XAF · {contextLabel}`.
class _AmountCard extends StatelessWidget {
  const _AmountCard({required this.amountXaf, required this.contextLabel});

  final int amountXaf;
  final String contextLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.lg),
      decoration: arenaGlowCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            l10n.paymentPickerAmountLabel,
            style: ArenaText.monoSmall.copyWith(
              color: ArenaColors.silver,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _formatXaf(amountXaf),
            style: ArenaText.mono.copyWith(
              color: ArenaColors.signalBlue,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'XAF · $contextLabel',
            style: ArenaText.small.copyWith(color: ArenaColors.silver),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _OperatorTile extends StatelessWidget {
  const _OperatorTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final CompetitionPaymentOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final operator = PaymentOperator.fromOption(option);
    // Aperçu discret du code de transfert (tronqué si long) — le code
    // complet reste visible en P2.
    final preview = _previewCode(option.transferCode);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ArenaRadius.lg),
      child: AnimatedContainer(
        duration: ArenaDurations.short,
        padding: const EdgeInsets.all(ArenaSpacing.md),
        decoration: BoxDecoration(
          color: ArenaColors.carbon,
          borderRadius: BorderRadius.circular(ArenaRadius.lg),
          border: Border.all(
            color: selected ? ArenaColors.signalBlue : ArenaColors.border,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: ArenaColors.signalBlue.withValues(alpha: 0.18),
                    blurRadius: 18,
                    spreadRadius: -2,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            PaymentOperatorLogo(operator: operator),
            const SizedBox(width: ArenaSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    operator.label,
                    style: ArenaText.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (preview != null) ...[
                    const SizedBox(height: 2),
                    Text(preview, style: ArenaText.bodyMuted),
                  ],
                ],
              ),
            ),
            AnimatedContainer(
              duration: ArenaDurations.short,
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? ArenaColors.signalBlue : Colors.transparent,
                border: Border.all(
                  color: selected ? ArenaColors.signalBlue : ArenaColors.border,
                ),
              ),
              alignment: Alignment.center,
              child: selected
                  ? const Icon(Icons.check, size: 14, color: ArenaColors.bone)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  static String? _previewCode(String code) {
    final c = code.trim();
    if (c.isEmpty) return null;
    if (c.length <= 14) return c;
    return '${c.substring(0, 12)}…';
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
