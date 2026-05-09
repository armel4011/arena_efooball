import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// PHASE 11bis · P5 — payment failure landing.
///
/// Reached on CinetPay / NowPayments error callbacks. Lists the failure
/// cause + machine-readable error code (so the user can paste it to
/// support) and three solution rows. Keeps the same visual gravity as
/// the success page (radial wash, 100dp hero) but tinted in neon-red.
///
/// Maps to screen P5 of `arena_v2.html`.
class PaymentFailedPage extends StatelessWidget {
  const PaymentFailedPage({
    this.causeMessage = 'Solde Mobile Money insuffisant.',
    this.errorCode = 'MOMO_INSUFFICIENT_FUNDS',
    this.solutions = const [
      'Recharge ton compte et réessaie',
      'Essaie un autre moyen de paiement',
      'Contacte le support de ton opérateur',
    ],
    this.onRetry,
    this.onChangeMethod,
    this.onContactSupport,
    super.key,
  });

  final String causeMessage;
  final String errorCode;
  final List<String> solutions;
  final VoidCallback? onRetry;
  final VoidCallback? onChangeMethod;
  final VoidCallback? onContactSupport;

  @override
  Widget build(BuildContext context) {
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
                'PAIEMENT ÉCHOUÉ',
                textAlign: TextAlign.center,
                style: ArenaText.h1.copyWith(color: ArenaColors.neonRed),
              ),
              const SizedBox(height: ArenaSpacing.sm),
              Text(
                "Ton compte n'a pas été débité.",
                textAlign: TextAlign.center,
                style: ArenaText.body,
              ),
              const SizedBox(height: ArenaSpacing.lg),
              _CauseCard(message: causeMessage, code: errorCode)
                  .animate(delay: 200.ms)
                  .fadeIn(duration: ArenaDurations.medium),
              const SizedBox(height: ArenaSpacing.md),
              _SolutionsCard(items: solutions)
                  .animate(delay: 300.ms)
                  .fadeIn(duration: ArenaDurations.medium),
              const SizedBox(height: ArenaSpacing.xl),
              ArenaButton(
                label: '↻ RÉESSAYER',
                fullWidth: true,
                size: ArenaButtonSize.large,
                onPressed: onRetry ?? () => Navigator.maybePop(context),
              ),
              const SizedBox(height: ArenaSpacing.sm),
              ArenaButton(
                label: 'CHANGER DE MÉTHODE',
                variant: ArenaButtonVariant.secondary,
                fullWidth: true,
                onPressed:
                    onChangeMethod ?? () => Navigator.maybePop(context),
              ),
              const SizedBox(height: ArenaSpacing.lg),
              Center(
                child: TextButton(
                  onPressed: onContactSupport,
                  child: Text(
                    'Contacter le support ARENA',
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
            colors: [ArenaColors.neonRed, Color(0xFF8B0020)],
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
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.lg),
      decoration: arenaDangerCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('⚠ Cause', style: ArenaText.h3),
          const SizedBox(height: ArenaSpacing.sm),
          Text(message, style: ArenaText.body),
          const SizedBox(height: ArenaSpacing.sm),
          RichText(
            text: TextSpan(
              style: ArenaText.bodyMuted,
              children: [
                const TextSpan(text: 'Code erreur : '),
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
          Text('💡 Solutions', style: ArenaText.h3),
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
