import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/features_user/payments/payment_method.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// PHASE 11bis · P1 — moyen de paiement picker.
///
/// V1.0 expose 2 entrées Mobile Money (MTN + Orange). Wave / Moov /
/// USDT / Bitcoin sont reportés en V2 quand les passerelles automatiques
/// CinetPay + NowPayments seront branchées. Sélection → P2.
///
/// Maps to screen P1 of `arena_v2.html`.
class PaymentMethodPickerPage extends StatefulWidget {
  const PaymentMethodPickerPage({
    required this.amountXaf,
    required this.contextLabel,
    this.onConfirm,
    super.key,
  });

  final int amountXaf;
  final String contextLabel;
  final ValueChanged<PaymentMethod>? onConfirm;

  @override
  State<PaymentMethodPickerPage> createState() =>
      _PaymentMethodPickerPageState();
}

class _PaymentMethodPickerPageState extends State<PaymentMethodPickerPage> {
  PaymentMethod _selected = PaymentMethod.mtnMoMo;

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
              for (final m in PaymentMethod.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: ArenaSpacing.sm),
                  child: _MethodTile(
                    method: m,
                    selected: _selected == m,
                    onTap: () => setState(() => _selected = m),
                  ),
                ),
              const SizedBox(height: ArenaSpacing.md),
              Container(
                padding: const EdgeInsets.all(ArenaSpacing.md),
                decoration: BoxDecoration(
                  color: ArenaColors.carbon,
                  borderRadius: BorderRadius.circular(ArenaRadius.md),
                  border: Border.all(color: ArenaColors.border),
                ),
                child: Text(
                  l10n.paymentPickerV2Notice,
                  style: ArenaText.small,
                ),
              ),
              const SizedBox(height: ArenaSpacing.xl),
              ArenaButton(
                label: l10n.paymentPickerContinueButton,
                fullWidth: true,
                size: ArenaButtonSize.large,
                onPressed: () {
                  final cb = widget.onConfirm;
                  if (cb != null) {
                    cb(_selected);
                  } else {
                    Navigator.maybePop(context, _selected);
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
/// Glow signalBlue pour mettre l'amount en valeur.
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

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
            PaymentMethodLogo(method: method),
            const SizedBox(width: ArenaSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.labelOf(l10n),
                    style: ArenaText.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(method.countriesLineOf(l10n), style: ArenaText.bodyMuted),
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
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
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
