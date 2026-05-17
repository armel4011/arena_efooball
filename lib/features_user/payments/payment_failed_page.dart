import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_user/payments/payment_method.dart';
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

  String get _causeMessage {
    switch (reason) {
      case PaymentFailReason.rejected:
        return adminReason?.trim().isNotEmpty ?? false
            ? 'Le super-admin a refusé ton paiement : $adminReason'
            : 'Le super-admin a refusé ton paiement (montant incorrect '
                'ou transaction introuvable sur le compte marchand).';
      case PaymentFailReason.network:
        return "Problème réseau pendant l'envoi. Aucun débit n'a été "
            'effectué côté ARENA.';
      case PaymentFailReason.unknown:
        return "Le paiement n'a pas pu être confirmé. Réessaie ou "
            'contacte le support.';
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

  List<String> get _solutions {
    switch (reason) {
      case PaymentFailReason.rejected:
        return [
          'Vérifie le montant exact + le code marchand',
          'Recommence depuis la page Inscription',
          "Contacte le support si tu penses que c'est une erreur",
        ];
      case PaymentFailReason.network:
        return [
          'Vérifie ta connexion Internet',
          'Recommence depuis la page Inscription',
        ];
      case PaymentFailReason.unknown:
        return [
          'Recommence depuis la page Inscription',
          'Contacte le support ARENA',
        ];
    }
  }

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
                _title,
                textAlign: TextAlign.center,
                style: ArenaText.h1.copyWith(color: ArenaColors.neonRed),
              ),
              const SizedBox(height: ArenaSpacing.sm),
              Text(
                "Ton compte n'a pas été inscrit.",
                textAlign: TextAlign.center,
                style: ArenaText.body,
              ),
              const SizedBox(height: ArenaSpacing.lg),
              _CauseCard(message: _causeMessage, code: _errorCode)
                  .animate(delay: 200.ms)
                  .fadeIn(duration: ArenaDurations.medium),
              const SizedBox(height: ArenaSpacing.md),
              _SolutionsCard(items: _solutions)
                  .animate(delay: 300.ms)
                  .fadeIn(duration: ArenaDurations.medium),
              const SizedBox(height: ArenaSpacing.xl),
              ArenaButton(
                label: '↻ RECOMMENCER',
                fullWidth: true,
                size: ArenaButtonSize.large,
                onPressed: onRetry ??
                    () => context.go(UserRoutes.home),
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

  String get _title {
    switch (reason) {
      case PaymentFailReason.rejected:
        return 'PAIEMENT REFUSÉ';
      case PaymentFailReason.network:
      case PaymentFailReason.unknown:
        return 'PAIEMENT ÉCHOUÉ';
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
