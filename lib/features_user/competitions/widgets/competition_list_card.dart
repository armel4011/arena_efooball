import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/competition.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_user/competitions/widgets/competition_phase_ui.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Card d'une compétition dans la liste #10 — **design « bande latérale »**
/// (compact, pro). Une bande de couleur à gauche identifie le tier au scroll,
/// la **valeur de la récompense** et le **nombre de récompensés** sont mis en
/// avant, et un CTA d'inscription est rendu sous la carte.
///
/// **3 tiers** (couleur de bande + accent) :
/// * **Payante** (`registrationFee > 0`) → OR (`tierGoldWarm`).
/// * **Gratuite + récompense** (`isFree && prizePoolLocal > 0`) → TURQUOISE
///   (`iceCyan`).
/// * **Gratuite pure** → VERT (`statusOk`) — pas de gain, « jeu amical ».
class CompetitionListCard extends StatelessWidget {
  const CompetitionListCard({
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

  bool get _isPaid => !competition.isFree;
  bool get _hasPrize => competition.prizePoolLocal > 0;

  /// Couleur d'accent (bande + valeur) par tier.
  Color get _accent {
    if (_isPaid) return ArenaColors.tierGoldWarm;
    if (_hasPrize) return ArenaColors.iceCyan;
    return ArenaColors.statusOk;
  }

  /// Libellé du tier (haut, à côté du jeu).
  String get _tierLabel {
    if (_isPaid) return 'PREMIUM';
    if (_hasPrize) return '+ GAINS';
    return 'GRATUIT';
  }

  /// Nombre de places récompensées = entrées > 0 dans la répartition des gains.
  int get _rewardedCount =>
      competition.prizeDistribution.where((m) => m > 0).length;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = competition;
    final accent = _accent;
    final currency = c.prizePoolCurrency ?? c.registrationCurrency;
    final phaseLabel = competitionPhaseLabel(c.status.phase, l10n).toUpperCase();

    final card = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ArenaRadius.lg),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: ArenaColors.carbon,
          borderRadius: BorderRadius.circular(ArenaRadius.lg),
          border: Border.all(color: ArenaColors.border),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Bande latérale couleur = tier ──────────────────────────
              Container(width: 5, color: accent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(ArenaSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ligne 1 : jeu + titre + badge inscrit
                      Row(
                        children: [
                          Text(
                            _gameEmoji(c.game),
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: ArenaSpacing.xs),
                          Expanded(
                            child: Text(
                              c.name.toUpperCase(),
                              style: ArenaText.body.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (c.isPinned) ...[
                            const SizedBox(width: ArenaSpacing.xs),
                            const _PinnedBadge(),
                          ],
                          if (isRegistered) ...[
                            const SizedBox(width: ArenaSpacing.xs),
                            const _Tag(label: '✓ INSCRIT', color: ArenaColors.statusOk),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Ligne 2 : tier · statut · joueurs
                      Text(
                        '$_tierLabel · $phaseLabel · '
                        '${c.currentPlayers}/${c.maxPlayers} joueurs',
                        style: ArenaText.monoSmall.copyWith(
                          color: ArenaColors.silver,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: ArenaSpacing.sm),
                      // Bloc récompense mis en avant
                      if (_hasPrize)
                        _RewardBlock(
                          amount: c.prizePoolLocal,
                          currency: currency,
                          rewardedCount: _rewardedCount,
                          accent: accent,
                        )
                      else
                        Text(
                          '⚔️  Jeu amical · pas de gain',
                          style: ArenaText.body.copyWith(
                            color: ArenaColors.statusOk,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      const SizedBox(height: ArenaSpacing.sm),
                      // Ligne bas : frais + date de début
                      Row(
                        children: [
                          const Icon(
                            Icons.confirmation_number_outlined,
                            size: 13,
                            color: ArenaColors.silver,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isPaid
                                ? '${_money(c.registrationFee)} '
                                    '${c.registrationCurrency}'
                                : 'GRATUIT',
                            style: ArenaText.monoSmall
                                .copyWith(color: ArenaColors.silver),
                          ),
                          const SizedBox(width: ArenaSpacing.md),
                          const Icon(
                            Icons.schedule,
                            size: 13,
                            color: ArenaColors.silver,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _dateLabel(c.startDate),
                            style: ArenaText.monoSmall
                                .copyWith(color: ArenaColors.silver),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (onRegister == null) return card;

    final ctaVariant =
        _isPaid ? ArenaButtonVariant.primary : ArenaButtonVariant.success;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        card,
        const SizedBox(height: ArenaSpacing.sm),
        ArenaButton(
          label: hasPendingPayment
              ? '⏱ VOIR LE STATUT DU PAIEMENT'
              : _isPaid
                  ? "S'INSCRIRE · ${_money(c.registrationFee)} ${c.registrationCurrency}"
                  : "S'INSCRIRE GRATUITEMENT",
          variant:
              hasPendingPayment ? ArenaButtonVariant.secondary : ctaVariant,
          fullWidth: true,
          onPressed: onRegister,
        ),
      ],
    );
  }

  static String _gameEmoji(GameType g) => switch (g) {
        GameType.efootball => '⚽',
        GameType.draughts => '🔴',
        GameType.eaSportsFc => '🎯',
      };

  static String _money(double v) =>
      NumberFormat.decimalPattern('fr').format(v).replaceAll(',', ' ');

  static String _dateLabel(DateTime startUtc) =>
      DateFormat('d MMM · HH:mm', 'fr').format(startUtc.toLocal());
}

/// Bloc « récompense » : montant XL + nombre de récompensés (médailles).
class _RewardBlock extends StatelessWidget {
  const _RewardBlock({
    required this.amount,
    required this.currency,
    required this.rewardedCount,
    required this.accent,
  });

  final double amount;
  final String currency;
  final int rewardedCount;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final rewardedLabel = rewardedCount <= 1
        ? '1 place récompensée'
        : '$rewardedCount places récompensées';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            const Text('🏆', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Text(
              _money(amount),
              style: ArenaText.mono.copyWith(
                color: accent,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                currency,
                style: ArenaText.monoSmall.copyWith(color: accent),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '🥇🥈🥉  $rewardedLabel',
          style: ArenaText.monoSmall.copyWith(color: ArenaColors.bone),
        ),
      ],
    );
  }

  static String _money(double v) =>
      NumberFormat.decimalPattern('fr').format(v).replaceAll(',', ' ');
}

/// Badge « À LA UNE » — signale une compétition épinglée par l'admin.
/// Icône épingle + libellé, en accent OR (`tierGoldWarm`) pour évoquer
/// la mise en avant premium. Réutilise le rendu de [_Tag].
class _PinnedBadge extends StatelessWidget {
  const _PinnedBadge();

  @override
  Widget build(BuildContext context) {
    const color = ArenaColors.tierGoldWarm;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(ArenaRadius.round),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.push_pin, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            'À LA UNE',
            style: ArenaText.monoSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Petit tag arrondi (ex. « ✓ INSCRIT »).
class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(ArenaRadius.round),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: ArenaText.monoSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
