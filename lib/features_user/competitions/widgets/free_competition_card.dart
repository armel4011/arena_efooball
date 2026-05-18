import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/competition.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Card "GRATUITE" — Lot D :
///   * Si récompense > 0 (item 4) : layout premium avec prize gros
///     caractères + gradient or, comme `PaidCompetitionCard` mais en
///     vert (statusOk) au lieu de doré.
///   * Si récompense = 0 : layout léger d'origine.
///   * Si `referralQuota > 0` (item 8) : badge "Parrainage requis :
///     N amis" en haut + tooltip "Tu pourras t'inscrire quand tu auras
///     parrainé N personnes via ton code".
class FreeCompetitionCard extends StatelessWidget {
  const FreeCompetitionCard({
    required this.competition,
    required this.isRegistered,
    required this.onTap,
    required this.onRegister,
    super.key,
  });

  final Competition competition;
  final bool isRegistered;
  final VoidCallback onTap;
  final VoidCallback? onRegister;

  static const _ok = ArenaColors.statusOk;
  static const _okDeep = ArenaColors.statusOkDeep;

  @override
  Widget build(BuildContext context) {
    final c = competition;
    final hasReward = c.prizePoolLocal > 0;
    final hasGating = c.referralQuota > 0;

    if (hasReward) {
      return _RewardedFreeCard(
        competition: c,
        isRegistered: isRegistered,
        hasGating: hasGating,
        onTap: onTap,
        onRegister: onRegister,
      );
    }
    return _LightFreeCard(
      competition: c,
      isRegistered: isRegistered,
      hasGating: hasGating,
      onTap: onTap,
      onRegister: onRegister,
    );
  }

  static String _gameEmoji(GameType g) => switch (g) {
        GameType.efootball => '⚽',
        GameType.fifaMobile => '🏆',
        GameType.eaSportsFc => '🎮',
      };

  static String _formatPrize(double pool, String currency) {
    final formatted = NumberFormat.decimalPattern('fr')
        .format(pool.round())
        .replaceAll(',', ' ');
    return '$formatted $currency';
  }
}

// ════════════════════════════════════════════════════════════════════
// VARIANTE 1 — Gratuite avec récompense (item 4 : prize gros caractères)
// ════════════════════════════════════════════════════════════════════
class _RewardedFreeCard extends StatelessWidget {
  const _RewardedFreeCard({
    required this.competition,
    required this.isRegistered,
    required this.hasGating,
    required this.onTap,
    required this.onRegister,
  });

  final Competition competition;
  final bool isRegistered;
  final bool hasGating;
  final VoidCallback onTap;
  final VoidCallback? onRegister;

  @override
  Widget build(BuildContext context) {
    final c = competition;
    final dateLabel =
        DateFormat('d MMM · HH:mm', 'fr').format(c.startDate.toLocal());
    final prize = FreeCompetitionCard._formatPrize(
      c.prizePoolLocal,
      c.prizePoolCurrency ?? c.registrationCurrency,
    );

    final body = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ArenaRadius.lg),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          ArenaSpacing.lg,
          ArenaSpacing.md,
          ArenaSpacing.lg,
          ArenaSpacing.lg,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              FreeCompetitionCard._ok.withValues(alpha: 0.14),
              ArenaColors.carbon,
            ],
          ),
          borderRadius: BorderRadius.circular(ArenaRadius.lg),
          border: Border.all(
            color: isRegistered
                ? FreeCompetitionCard._ok
                : FreeCompetitionCard._ok.withValues(alpha: 0.4),
            width: isRegistered ? 1.5 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: FreeCompetitionCard._ok.withValues(alpha: 0.12),
              blurRadius: 22,
              spreadRadius: -4,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  FreeCompetitionCard._gameEmoji(c.game),
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: ArenaSpacing.sm),
                Expanded(
                  child: Text(
                    c.name,
                    style: ArenaText.h3,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: ArenaSpacing.xs),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color:
                        FreeCompetitionCard._ok.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(ArenaRadius.round),
                    border: Border.all(
                      color: FreeCompetitionCard._ok.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Text(
                    'GRATUITE',
                    style: ArenaText.small.copyWith(
                      color: FreeCompetitionCard._ok,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '${c.game.label} · $dateLabel',
              style: ArenaText.bodyMuted,
            ),
            if (hasGating) ...[
              const SizedBox(height: ArenaSpacing.sm),
              _ReferralGateBadge(quota: c.referralQuota),
            ],
            const SizedBox(height: ArenaSpacing.md),

            // ─── Item 4 : récompense en gros caractères ────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        FreeCompetitionCard._ok,
                        FreeCompetitionCard._okDeep,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(ArenaRadius.lg),
                    boxShadow: [
                      BoxShadow(
                        color: FreeCompetitionCard._ok
                            .withValues(alpha: 0.35),
                        blurRadius: 14,
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: const Text(
                    '🎁',
                    style: TextStyle(fontSize: 30),
                  ),
                ),
                const SizedBox(width: ArenaSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'À GAGNER · GRATUIT',
                        style: ArenaText.small.copyWith(
                          color: FreeCompetitionCard._ok,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      ShaderMask(
                        shaderCallback: (b) => const LinearGradient(
                          colors: [
                            FreeCompetitionCard._ok,
                            FreeCompetitionCard._okDeep,
                          ],
                        ).createShader(b),
                        child: Text(
                          prize,
                          style: ArenaText.bigNumber.copyWith(
                            fontSize: 30,
                            color: ArenaColors.bone,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: ArenaSpacing.md),
            const Divider(height: 1, color: ArenaColors.border),
            const SizedBox(height: ArenaSpacing.sm),
            Row(
              children: [
                const Icon(
                  Icons.people_outline,
                  size: 14,
                  color: ArenaColors.silver,
                ),
                const SizedBox(width: 4),
                Text(
                  '${c.currentPlayers}/${c.maxPlayers}',
                  style: ArenaText.bodyMuted,
                ),
                const Spacer(),
                if (isRegistered)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: FreeCompetitionCard._ok
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(ArenaRadius.round),
                      border: Border.all(
                        color: FreeCompetitionCard._ok
                            .withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      '✓ INSCRIT',
                      style: ArenaText.small.copyWith(
                        color: FreeCompetitionCard._ok,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );

    if (onRegister == null) return body;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        body,
        const SizedBox(height: ArenaSpacing.sm),
        ArenaButton(
          label: hasGating
              ? '👥 PARRAINAGES REQUIS'
              : "✓ M'INSCRIRE GRATUITEMENT",
          variant: ArenaButtonVariant.primary,
          fullWidth: true,
          onPressed: onRegister,
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// VARIANTE 2 — Gratuite sans récompense (layout léger original)
// ════════════════════════════════════════════════════════════════════
class _LightFreeCard extends StatelessWidget {
  const _LightFreeCard({
    required this.competition,
    required this.isRegistered,
    required this.hasGating,
    required this.onTap,
    required this.onRegister,
  });

  final Competition competition;
  final bool isRegistered;
  final bool hasGating;
  final VoidCallback onTap;
  final VoidCallback? onRegister;

  @override
  Widget build(BuildContext context) {
    final c = competition;
    final dateLabel =
        DateFormat('d MMM · HH:mm', 'fr').format(c.startDate.toLocal());

    final body = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ArenaRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(ArenaSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ArenaColors.statusOk.withValues(alpha: 0.10),
              ArenaColors.carbon,
            ],
          ),
          borderRadius: BorderRadius.circular(ArenaRadius.lg),
          border: Border.all(
            color: isRegistered
                ? ArenaColors.statusOk
                : ArenaColors.statusOk.withValues(alpha: 0.35),
            width: isRegistered ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color:
                            ArenaColors.statusOk.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              ArenaColors.statusOk.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        FreeCompetitionCard._gameEmoji(c.game),
                        style: const TextStyle(fontSize: 26),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            ArenaColors.statusOk.withValues(alpha: 0.15),
                        borderRadius:
                            BorderRadius.circular(ArenaRadius.round),
                      ),
                      child: Text(
                        'GRATUITE',
                        style: ArenaText.small.copyWith(
                          color: ArenaColors.statusOk,
                          fontWeight: FontWeight.w700,
                          fontSize: 9,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: ArenaSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.name,
                        style: ArenaText.h3,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(c.game.label, style: ArenaText.bodyMuted),
                      const SizedBox(height: 2),
                      Text('🗓 $dateLabel', style: ArenaText.small),
                      const SizedBox(height: ArenaSpacing.xs),
                      Row(
                        children: [
                          const Icon(
                            Icons.people_outline,
                            size: 13,
                            color: ArenaColors.silver,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${c.currentPlayers}/${c.maxPlayers}',
                            style: ArenaText.small,
                          ),
                          const SizedBox(width: ArenaSpacing.sm),
                          if (isRegistered)
                            Text(
                              '· ✓ Inscrit',
                              style: ArenaText.small.copyWith(
                                color: ArenaColors.statusOk,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: ArenaSpacing.sm),
                const Icon(
                  Icons.chevron_right,
                  color: ArenaColors.silver,
                  size: 22,
                ),
              ],
            ),
            if (hasGating) ...[
              const SizedBox(height: ArenaSpacing.sm),
              _ReferralGateBadge(quota: c.referralQuota),
            ],
          ],
        ),
      ),
    );

    if (onRegister == null) return body;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        body,
        const SizedBox(height: ArenaSpacing.sm),
        ArenaButton(
          label: hasGating
              ? '👥 PARRAINAGES REQUIS'
              : "✓ M'INSCRIRE GRATUITEMENT",
          fullWidth: true,
          onPressed: onRegister,
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// Badge "Parrainage requis : N amis" — affiché sur les 2 variantes
// ════════════════════════════════════════════════════════════════════
class _ReferralGateBadge extends StatelessWidget {
  const _ReferralGateBadge({required this.quota});
  final int quota;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ArenaSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: ArenaColors.signalBlue.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(ArenaRadius.md),
        border: Border.all(
          color: ArenaColors.signalBlue.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.group_outlined,
            size: 14,
            color: ArenaColors.signalBlue,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Parrainage requis : $quota ami(s) via ton code',
              style: ArenaText.small.copyWith(
                color: ArenaColors.signalBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
