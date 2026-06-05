import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_divider.dart';
import 'package:arena/features_user/payments/payment_method.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

/// PHASE 11bis · P4 — payment success landing.
///
/// Reached on a CinetPay / NowPayments OK callback. Renders a green
/// hero ✓ + receipt + tournament context ("Tu es inscrit à ..."), then
/// drops the user back at /home (or "MES INSCRIPTIONS" once that screen
/// lands in PHASE 11).
///
/// Maps to screen P4 of `arena_v2.html`.
class PaymentSuccessPage extends StatelessWidget {
  const PaymentSuccessPage({
    required this.amountXaf,
    required this.method,
    required this.transactionId,
    required this.dateLabel,
    this.tournamentName = 'FIFA WEEKEND CUP',
    this.tournamentStartLabel = 'Démarre le 11 mai à 14h',
    this.competitionId,
    this.onSeeMyEntries,
    this.onBackHome,
    super.key,
  });

  final int amountXaf;
  final PaymentMethod method;
  final String transactionId;
  final String dateLabel;
  final String tournamentName;
  final String tournamentStartLabel;
  final String? competitionId;
  final VoidCallback? onSeeMyEntries;
  final VoidCallback? onBackHome;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: ArenaColors.void_,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.6),
            radius: 0.9,
            colors: [
              ArenaColors.statusOk.withValues(alpha: 0.15),
              ArenaColors.void_,
            ],
            stops: const [0, 0.6],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(ArenaSpacing.lg),
            children: [
              const SizedBox(height: ArenaSpacing.xxl),
              const _SuccessHero().animate().scale(
                    begin: const Offset(0.6, 0.6),
                    end: const Offset(1, 1),
                    duration: ArenaDurations.long,
                    curve: Curves.elasticOut,
                  ),
              const SizedBox(height: ArenaSpacing.lg),
              Text(
                l10n.paymentSuccessTitle,
                textAlign: TextAlign.center,
                style: ArenaText.h1.copyWith(color: ArenaColors.statusOk),
              ),
              const SizedBox(height: ArenaSpacing.sm),
              Text(
                l10n.paymentSuccessSubtitle,
                textAlign: TextAlign.center,
                style: ArenaText.body,
              ),
              const SizedBox(height: ArenaSpacing.lg),
              _Receipt(
                amountXaf: amountXaf,
                method: method,
                transactionId: transactionId,
                dateLabel: dateLabel,
              ).animate(delay: 200.ms).fadeIn(
                    duration: ArenaDurations.medium,
                  ),
              const SizedBox(height: ArenaSpacing.md),
              _TournamentCard(
                name: tournamentName,
                startLabel: tournamentStartLabel,
              ).animate(delay: 300.ms).fadeIn(
                    duration: ArenaDurations.medium,
                  ),
              const SizedBox(height: ArenaSpacing.xl),
              if (competitionId != null) ...[
                ArenaButton(
                  label: l10n.paymentSuccessSeeCompetition,
                  fullWidth: true,
                  size: ArenaButtonSize.large,
                  onPressed: () => context.go(
                    UserRoutes.competitionPath(competitionId!),
                  ),
                ),
                const SizedBox(height: ArenaSpacing.sm),
              ],
              ArenaButton(
                label: l10n.paymentSuccessBackHome,
                variant: ArenaButtonVariant.ghost,
                fullWidth: true,
                onPressed: onBackHome ?? () => context.go(UserRoutes.home),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessHero extends StatelessWidget {
  const _SuccessHero();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [ArenaColors.statusOk, ArenaColors.statusOkDeep],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: ArenaColors.statusOk.withValues(alpha: 0.4),
              blurRadius: 40,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.check, size: 56, color: Colors.white),
      ),
    );
  }
}

class _Receipt extends StatelessWidget {
  const _Receipt({
    required this.amountXaf,
    required this.method,
    required this.transactionId,
    required this.dateLabel,
  });

  final int amountXaf;
  final PaymentMethod method;
  final String transactionId;
  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.lg),
      decoration: arenaSuccessCardDecoration(),
      child: Column(
        children: [
          _Row(
            label: l10n.paymentSuccessReceiptAmount,
            value: '${_formatXaf(amountXaf)} XAF',
            valueStyle: ArenaText.mono.copyWith(fontWeight: FontWeight.w700),
          ),
          const ArenaDivider(),
          _Row(label: l10n.paymentSuccessReceiptMethod, value: method.label),
          const ArenaDivider(),
          _Row(
            label: l10n.paymentSuccessReceiptTransaction,
            value: transactionId,
            valueStyle: ArenaText.mono.copyWith(color: ArenaColors.signalBlue),
          ),
          const ArenaDivider(),
          _Row(label: l10n.paymentSuccessReceiptDate, value: dateLabel),
        ],
      ),
    );
  }
}

class _TournamentCard extends StatelessWidget {
  const _TournamentCard({required this.name, required this.startLabel});

  final String name;
  final String startLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.lg),
      decoration: arenaGlowCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.paymentSuccessRegisteredLabel, style: ArenaText.h3),
          const SizedBox(height: ArenaSpacing.xs),
          Text(
            name.toUpperCase(),
            style: ArenaText.h2.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 2),
          Text(startLabel, style: ArenaText.bodyMuted),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.valueStyle});
  final String label;
  final String value;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: ArenaText.bodyMuted)),
          Text(value, style: valueStyle ?? ArenaText.body),
        ],
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
