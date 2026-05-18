import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/repositories/referral_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

/// Lot D — Widget partagé : carte de progression parrainage à afficher
/// quand `competition.referral_quota > 0`. Utilisé sur la page détail
/// (`_GatedDetailView`) ET sur `RegistrationConfirmPage` pour gater
/// l'inscription. Le widget est purement informatif — le gating
/// d'inscription est appliqué côté `enforce_referral_quota_on_registration`
/// trigger DB de toute façon.
class ReferralProgressCard extends ConsumerWidget {
  const ReferralProgressCard({
    required this.competitionId,
    required this.referralQuota,
    super.key,
  });

  final String competitionId;
  final int referralQuota;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eligibilityAsync =
        ref.watch(referralEligibilityProvider(competitionId));
    final codeAsync = ref.watch(myReferralCodeProvider);

    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.lg),
      decoration: BoxDecoration(
        color: ArenaColors.signalBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(
          color: ArenaColors.signalBlue.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.group_outlined,
                size: 18,
                color: ArenaColors.signalBlue,
              ),
              const SizedBox(width: ArenaSpacing.xs),
              Expanded(
                child: Text(
                  'Parrainage requis',
                  style: ArenaText.h3.copyWith(
                    color: ArenaColors.signalBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ArenaSpacing.xs),
          Text(
            'Tu dois parrainer $referralQuota ami(s) pour '
            "t'inscrire à cette compétition gratuite. Partage ton code "
            "avec eux pour qu'ils créent leur compte ARENA.",
            style: ArenaText.small,
          ),
          const SizedBox(height: ArenaSpacing.md),
          eligibilityAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: ArenaSpacing.sm),
              child: LinearProgressIndicator(
                color: ArenaColors.signalBlue,
                backgroundColor: ArenaColors.carbon2,
                minHeight: 6,
              ),
            ),
            error: (e, _) => Text(
              'Impossible de vérifier ta progression : $e',
              style: ArenaText.small.copyWith(color: ArenaColors.neonRed),
            ),
            data: (eg) => _ProgressBlock(eligibility: eg),
          ),
          const SizedBox(height: ArenaSpacing.md),
          codeAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (code) => code == null
                ? const SizedBox.shrink()
                : _ReferralCodeCopy(code: code),
          ),
        ],
      ),
    );
  }
}

class _ProgressBlock extends StatelessWidget {
  const _ProgressBlock({required this.eligibility});
  final ReferralEligibility eligibility;

  @override
  Widget build(BuildContext context) {
    final eg = eligibility;
    final ratio =
        eg.target == 0 ? 1.0 : (eg.current / eg.target).clamp(0.0, 1.0);
    final color =
        eg.eligible ? ArenaColors.statusOk : ArenaColors.signalBlue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              '${eg.current} / ${eg.target}',
              style: ArenaText.bigNumber.copyWith(
                color: color,
                fontSize: 22,
              ),
            ),
            const SizedBox(width: ArenaSpacing.sm),
            Expanded(
              child: Text(
                eg.eligible
                    ? "✓ Quota atteint — tu peux t'inscrire !"
                    : 'Encore ${eg.target - eg.current} ami(s) à parrainer',
                style: ArenaText.body.copyWith(color: color),
              ),
            ),
          ],
        ),
        const SizedBox(height: ArenaSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: ArenaColors.carbon2,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

class _ReferralCodeCopy extends StatelessWidget {
  const _ReferralCodeCopy({required this.code});
  final String code;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Code $code copié dans le presse-papier'),
        backgroundColor: ArenaColors.statusOk,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _share() async {
    await Share.share(
      "Rejoins-moi sur ARENA ! Tournois d'e-sport mobile gratuits avec "
      "récompenses. Utilise mon code de parrainage à l'inscription : $code",
      subject: 'Rejoins-moi sur ARENA',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.md),
        border: Border.all(color: ArenaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TON CODE',
            style: ArenaText.small.copyWith(
              color: ArenaColors.silver,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            code,
            style: ArenaText.invitCode.copyWith(color: ArenaColors.bone),
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _copy(context),
                  icon: const Icon(
                    Icons.content_copy_rounded,
                    size: 16,
                    color: ArenaColors.signalBlue,
                  ),
                  label: Text(
                    'Copier',
                    style: ArenaText.button
                        .copyWith(color: ArenaColors.signalBlue),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: ArenaColors.signalBlue),
                  ),
                ),
              ),
              const SizedBox(width: ArenaSpacing.sm),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _share,
                  icon: const Icon(
                    Icons.share_rounded,
                    size: 16,
                    color: ArenaColors.bone,
                  ),
                  label: Text(
                    'Partager',
                    style: ArenaText.button.copyWith(color: ArenaColors.bone),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: ArenaColors.signalBlue,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
