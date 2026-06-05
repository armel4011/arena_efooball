import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_user/payments/payment_method.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

/// Pourquoi le paiement a échoué — pilote le message + le code erreur
/// de [PaymentFailedPage]. PHASE 11bis.
enum PaymentFailReason { rejected, network, unknown }

/// PHASE 11bis · P5 — Paiement échoué.
///
/// Atteinte depuis P3 quand le super-admin a refusé manuellement
/// (`status='rejected'` + `rejection_reason`), ou pour un cas générique
/// (réseau / inconnu) qui reste en place pour V2.
///
/// Maps to screen P5 of `arena_v2.html`.
class PaymentFailedPage extends StatelessWidget {
  const PaymentFailedPage({
    this.reason = PaymentFailReason.unknown,
    this.adminReason,
    this.method,
    this.onRetry,
    this.onContactSupport,
    super.key,
  });

  final PaymentFailReason reason;

  /// Justification saisie par le super-admin quand reason == rejected.
  final String? adminReason;
  final PaymentMethod? method;
  final VoidCallback? onRetry;
  final VoidCallback? onContactSupport;

  String _causeMessage(AppLocalizations l10n) {
    switch (reason) {
      case PaymentFailReason.rejected:
        return adminReason?.trim().isNotEmpty ?? false
            ? '${l10n.paymentFailedRejectedWithReason}$adminReason'
            : l10n.paymentFailedRejectedGeneric;
      case PaymentFailReason.network:
        return l10n.paymentFailedNetwork;
      case PaymentFailReason.unknown:
        return l10n.paymentFailedUnknown;
    }
  }

  String get _errorCode {
    switch (reason) {
      case PaymentFailReason.rejected:
        return 'PAY_ADMIN_REJECTED';
      case PaymentFailReason.network:
        return 'PAY_NETWORK_ERROR';
      case PaymentFailReason.unknown:
        return 'PAY_UNKNOWN';
    }
  }

  List<String> _solutions(AppLocalizations l10n) {
    switch (reason) {
      case PaymentFailReason.rejected:
        return [
          l10n.paymentFailedSolutionCheckAmount,
          l10n.paymentFailedSolutionRetryFromSignup,
          l10n.paymentFailedSolutionContactIfError,
        ];
      case PaymentFailReason.network:
        return [
          l10n.paymentFailedSolutionCheckInternet,
          l10n.paymentFailedSolutionRetryFromSignup,
        ];
      case PaymentFailReason.unknown:
        return [
          l10n.paymentFailedSolutionRetryFromSignup,
          l10n.paymentFailedSolutionContactSupport,
        ];
    }
  }

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
              ArenaColors.neonRed.withValues(alpha: 0.15),
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
              const _FailureHero()
                  .animate()
                  .scale(
                    begin: const Offset(0.6, 0.6),
                    end: const Offset(1, 1),
                    duration: ArenaDurations.long,
                    curve: Curves.elasticOut,
                  )
                  .shake(
                    hz: 4,
                    duration: ArenaDurations.medium,
                    delay: 100.ms,
                  ),
              const SizedBox(height: ArenaSpacing.lg),
              Text(
                _title(l10n),
                textAlign: TextAlign.center,
                style: ArenaText.h1.copyWith(color: ArenaColors.neonRed),
              ),
              const SizedBox(height: ArenaSpacing.sm),
              Text(
                l10n.paymentFailedAccountNotRegistered,
                textAlign: TextAlign.center,
                style: ArenaText.body,
              ),
              const SizedBox(height: ArenaSpacing.lg),
              _CauseCard(message: _causeMessage(l10n), code: _errorCode)
                  .animate(delay: 200.ms)
                  .fadeIn(duration: ArenaDurations.medium),
              const SizedBox(height: ArenaSpacing.md),
              _SolutionsCard(items: _solutions(l10n))
                  .animate(delay: 300.ms)
                  .fadeIn(duration: ArenaDurations.medium),
              const SizedBox(height: ArenaSpacing.xl),
              ArenaButton(
                label: l10n.paymentFailedRetryButton,
                fullWidth: true,
                size: ArenaButtonSize.large,
                onPressed: onRetry ?? () => context.go(UserRoutes.home),
              ),
              const SizedBox(height: ArenaSpacing.lg),
              Center(
                child: TextButton(
                  onPressed: onContactSupport,
                  child: Text(
                    l10n.paymentFailedContactSupportLink,
                    style: ArenaText.body.copyWith(
                      color: ArenaColors.signalBlue,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _title(AppLocalizations l10n) {
    switch (reason) {
      case PaymentFailReason.rejected:
        return l10n.paymentFailedTitleRejected;
      case PaymentFailReason.network:
      case PaymentFailReason.unknown:
        return l10n.paymentFailedTitleFailed;
    }
  }
}

class _FailureHero extends StatelessWidget {
  const _FailureHero();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [ArenaColors.neonRed, ArenaColors.statusDangerDeep],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: ArenaColors.neonRed.withValues(alpha: 0.45),
              blurRadius: 40,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.close, size: 50, color: Colors.white),
      ),
    );
  }
}

class _CauseCard extends StatelessWidget {
  const _CauseCard({required this.message, required this.code});
  final String message;
  final String code;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.lg),
      decoration: arenaDangerCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.paymentFailedCauseTitle, style: ArenaText.h3),
          const SizedBox(height: ArenaSpacing.sm),
          Text(message, style: ArenaText.body),
          const SizedBox(height: ArenaSpacing.sm),
          RichText(
            text: TextSpan(
              style: ArenaText.bodyMuted,
              children: [
                TextSpan(text: l10n.paymentFailedErrorCodeLabel),
                TextSpan(
                  text: code,
                  style: ArenaText.mono.copyWith(color: ArenaColors.neonRed),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SolutionsCard extends StatelessWidget {
  const _SolutionsCard({required this.items});
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.lg),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(color: ArenaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.paymentFailedSolutionsTitle, style: ArenaText.h3),
          const SizedBox(height: ArenaSpacing.sm),
          for (final s in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '→  ',
                    style: ArenaText.body.copyWith(
                      color: ArenaColors.signalBlue,
                    ),
                  ),
                  Expanded(child: Text(s, style: ArenaText.body)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
