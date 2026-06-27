import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/utils/date_formatter.dart';
import 'package:arena/data/models/competition.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_user/competitions/widgets/competition_phase_ui.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Card d'une compétition dans la liste #10 — **design premium** (fond en
/// dégradé subtil par tier + bande latérale colorée). La **valeur de la
/// récompense** et le **nombre de récompensés** sont le bloc le plus
/// proéminent ; un CTA d'inscription est rendu sous la carte.
///
/// **3 tiers** (gradient de fond + accent) :
/// * **Payante** (`registrationFee > 0`) → OR (`tierGoldWarm`), badge PREMIUM.
/// * **Gratuite + récompense** (`isFree && prizePoolLocal > 0`) → TURQUOISE
///   (`iceCyan`), badge + GAINS.
/// * **Gratuite pure** → VERT (`statusOk`), badge GRATUIT — « jeu amical ».
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

  /// Dégradé de fond subtil par tier : carbon → légère teinte de l'accent,
  /// pour un rendu premium sans nuire à la lisibilité du texte.
  LinearGradient get _bgGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          _accent.withValues(alpha: 0.10),
          ArenaColors.carbon,
        ],
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = competition;
    final accent = _accent;
    final currency = c.prizePoolCurrency ?? c.registrationCurrency;
    final phaseLabel = competitionStatusLabel(c.status, l10n).toUpperCase();

    final card = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ArenaRadius.lg),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: _bgGradient,
          borderRadius: BorderRadius.circular(ArenaRadius.lg),
          border: Border.all(color: accent.withValues(alpha: 0.45)),
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
                      // Ligne 1 : badge tier en évidence + badges À LA UNE/INSCRIT
                      Row(
                        children: [
                          _TierBadge(label: _tierLabel, color: accent),
                          const Spacer(),
                          if (c.isPinned) const _PinnedBadge(),
                          if (isRegistered) ...[
                            const SizedBox(width: ArenaSpacing.xs),
                            const _Tag(
                              label: '✓ INSCRIT',
                              color: ArenaColors.statusOk,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: ArenaSpacing.sm),
                      // Ligne 2 : jeu + titre
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
                        ],
                      ),
                      const SizedBox(height: ArenaSpacing.xs),
                      // Statut de la compétition
                      Text(
                        phaseLabel,
                        style: ArenaText.monoSmall.copyWith(
                          color: ArenaColors.silver,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: ArenaSpacing.sm),
                      // Bloc récompense mis en avant (le plus proéminent)
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
                      // Participants + barre de remplissage colorée par tier
                      _ParticipantsBar(
                        current: c.currentPlayers,
                        max: c.maxPlayers,
                        ratio: c.fillRatio,
                        accent: accent,
                      ),
                      const SizedBox(height: ArenaSpacing.sm),
                      // Frais (discret).
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
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Jour / date / heure — mis en avant (pastille accentuée).
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: ArenaSpacing.sm,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: ArenaColors.signalBlue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(ArenaRadius.sm),
                          border: Border.all(
                            color: ArenaColors.signalBlue.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.event,
                              size: 16,
                              color: ArenaColors.signalBlue,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _dateLabel(c.startDate),
                                style: ArenaText.body.copyWith(
                                  color: ArenaColors.bone,
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
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
        GameType.eaSportsFc => '🎮',
      };

  static String _money(double v) =>
      NumberFormat.decimalPattern('fr').format(v).replaceAll(',', ' ');

  static String _dateLabel(DateTime startUtc) =>
      formatRelativeDate(startUtc);
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

/// Badge tier mis en évidence (« PREMIUM » / « + GAINS » / « GRATUIT »).
/// Fond translucide de l'accent + bordure + texte coloré.
class _TierBadge extends StatelessWidget {
  const _TierBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(ArenaRadius.round),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: ArenaText.badge.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

/// Barre de remplissage des participants : « X/Y joueurs » + jauge fine
/// colorée selon le tier (fond border, remplissage accent).
class _ParticipantsBar extends StatelessWidget {
  const _ParticipantsBar({
    required this.current,
    required this.max,
    required this.ratio,
    required this.accent,
  });

  final int current;
  final int max;
  final double ratio;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.group_outlined,
              size: 13,
              color: ArenaColors.silver,
            ),
            const SizedBox(width: 4),
            Text(
              '$current/$max joueurs',
              style: ArenaText.monoSmall.copyWith(color: ArenaColors.silver),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(ArenaRadius.round),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 4,
            backgroundColor: ArenaColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(accent),
          ),
        ),
      ],
    );
  }
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
