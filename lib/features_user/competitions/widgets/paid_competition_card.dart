import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/competition.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Card "PAYANTE" : layout premium avec récompense en or, trophée,
/// glow doré, et footer dédié au prix d'entrée.
class PaidCompetitionCard extends StatelessWidget {
  const PaidCompetitionCard({
    required this.competition,
    required this.isRegistered,
    required this.hasPendingPayment,
    required this.onTap,
    required this.onRegister,
    super.key,
  });

  final Competition competition;
  final bool isRegistered;
  final bool hasPendingPayment;
  final VoidCallback onTap;
  final VoidCallback? onRegister;

  static const _gold = ArenaColors.tierGoldWarm;
  static const _goldDeep = ArenaColors.tierGoldDeep;

  @override
  Widget build(BuildContext context) {
    final c = competition;
    final dateLabel =
        DateFormat('d MMM · HH:mm', 'fr').format(c.startDate.toLocal());
    final prize = _formatPrize(c.prizePoolLocal,
        c.prizePoolCurrency ?? c.registrationCurrency,);

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
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0x1AFFC93C), // gold tint top (10% alpha sur tierGoldWarm)
              ArenaColors.carbon, // fades to carbon
            ],
          ),
          borderRadius: BorderRadius.circular(ArenaRadius.lg),
          border: Border.all(
            color: isRegistered
                ? ArenaColors.statusOk
                : _gold.withValues(alpha: 0.4),
            width: isRegistered ? 1.5 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: _gold.withValues(alpha: 0.12),
              blurRadius: 22,
              spreadRadius: -4,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header : emoji + nom + chip PAYANTE ──────────────
            Row(
              children: [
                Text(
                  _gameEmoji(c.game),
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
                    color: _gold.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(ArenaRadius.round),
                    border: Border.all(color: _gold.withValues(alpha: 0.6)),
                  ),
                  child: Text(
                    'PAYANTE',
                    style: ArenaText.small.copyWith(
                      color: _gold,
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
            const SizedBox(height: ArenaSpacing.md),

            // ─── Trophée + récompense en gros (gradient or) ──────
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
                      colors: [_gold, _goldDeep],
                    ),
                    borderRadius:
                        BorderRadius.circular(ArenaRadius.lg),
                    boxShadow: [
                      BoxShadow(
                        color: _gold.withValues(alpha: 0.35),
                        blurRadius: 14,
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: const Text('🏆',
                      style: TextStyle(fontSize: 30),),
                ),
                const SizedBox(width: ArenaSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'À GAGNER',
                        style: ArenaText.small.copyWith(
                          color: _gold,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      ShaderMask(
                        shaderCallback: (b) => const LinearGradient(
                          colors: [_gold, _goldDeep],
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

            // ─── Footer : frais + capacité + chip INSCRIT ────────
            Row(
              children: [
                const Icon(
                  Icons.payments_outlined,
                  size: 14,
                  color: ArenaColors.silver,
                ),
                const SizedBox(width: 4),
                Text(
                  '${_money(c.registrationFee)} ${c.registrationCurrency}',
                  style: ArenaText.bodyMuted
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: ArenaSpacing.md),
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
                      color: ArenaColors.statusOk.withValues(alpha: 0.15),
                      borderRadius:
                          BorderRadius.circular(ArenaRadius.round),
                      border: Border.all(
                        color: ArenaColors.statusOk.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      '✓ INSCRIT',
                      style: ArenaText.small.copyWith(
                        color: ArenaColors.statusOk,
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
          label: hasPendingPayment
              ? '⏱ VOIR LE STATUT DU PAIEMENT'
              : "✓ S'INSCRIRE · "
                  '${_money(c.registrationFee)} ${c.registrationCurrency}',
          variant: hasPendingPayment
              ? ArenaButtonVariant.secondary
              : ArenaButtonVariant.primary,
          fullWidth: true,
          onPressed: onRegister,
        ),
      ],
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

  static String _money(double v) =>
      NumberFormat.decimalPattern('fr').format(v).replaceAll(',', ' ');
}
