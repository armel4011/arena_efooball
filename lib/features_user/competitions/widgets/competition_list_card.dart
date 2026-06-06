import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/competition.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Card d'une competition dans la liste #10 — **style Trading Card FUT**.
///
/// Structure (de haut en bas) :
///   ╭──────────────────────────────╮
///   │ [TIER BADGE]     [GAME LOGO] │ ← header sur fond accent tier
///   │┉┉┉┉┉┉┉┉┉┉┉┉┉┉┉┉┉┉┉┉┉┉┉┉┉┉┉┉┉│ ← dotted divider
///   │            🏆               │ ← hero : emoji + montant en gros
///   │       240 000 XAF            │
///   │       ★ A GAGNER ★           │
///   │┉┉┉┉┉┉┉┉┉┉┉┉┉┉┉┉┉┉┉┉┉┉┉┉┉┉┉┉┉│
///   │   TOURNOI DU WEEKEND         │ ← titre centre en Bebas
///   │  ⬢64j  ⬢5000  ⬢24/05         │ ← stats hexagones
///   ╰──────────────────────────────╯
///   + bordure DOUBLE (anneau exterieur + interieur) coloree par tier
///
/// **3 tiers** identifiables au scroll :
/// * **Payante** (`registrationFee > 0`) → OR (`tierGoldWarm`), emoji 🏆,
///   montant = prizePool. CTA "S'INSCRIRE · X XAF" en or.
/// * **Gratuite + recompense** (`isFree && prizePoolLocal > 0`) →
///   TURQUOISE (`iceCyan`), emoji 🎁, montant = prizePool.
/// * **Gratuite pure** → VERT (`statusOk`), emoji ⚔️, pas de montant
///   (label "JEU AMICAL" a la place).
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

  /// Couleur principale par tier (border, badge, montant).
  Color get _accent {
    if (_isPaid) return ArenaColors.tierGoldWarm;
    if (_hasPrize) return ArenaColors.iceCyan;
    return ArenaColors.statusOk;
  }

  /// Gradient de fond par tier — donne le hero du tier en arriere-plan.
  LinearGradient get _gradient {
    if (_isPaid) return ArenaColors.compTierPaid;
    if (_hasPrize) return ArenaColors.compTierFreePrize;
    return ArenaColors.compTierFreePure;
  }

  /// Glow assorti — donne du caractere a la card.
  Color get _glow {
    if (_isPaid) return ArenaColors.tierGoldWarm.withValues(alpha: 0.4);
    if (_hasPrize) return ArenaColors.iceCyanGlow;
    return ArenaColors.statusOk.withValues(alpha: 0.32);
  }

  /// (label, emoji) du badge tier en haut a gauche.
  (String, String) get _tierBadge {
    if (_isPaid) return ('PREMIUM', '★');
    if (_hasPrize) return ('+ GAINS', '🎁');
    return ('GRATUIT', '⚔');
  }

  /// Emoji XL du hero — depend du tier.
  String get _heroEmoji {
    if (_isPaid) return '🏆';
    if (_hasPrize) return '🎁';
    return '⚔️';
  }

  @override
  Widget build(BuildContext context) {
    final c = competition;
    final accent = _accent;
    final (tierLabel, tierEmoji) = _tierBadge;
    final gameLabel = _gameLabel(c.game);
    final statusLabel = _statusLabel(c.status);

    final card = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ArenaRadius.lg),
      child: Container(
        // ─── Bordure double : outer ring or/turquoise/vert ────────────
        decoration: BoxDecoration(
          color: ArenaColors.void_,
          borderRadius: BorderRadius.circular(ArenaRadius.lg),
          border: Border.all(color: accent, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: ArenaColors.void_.withValues(alpha: 0.5),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: _glow,
              blurRadius: 22,
              spreadRadius: -6,
            ),
          ],
        ),
        padding: const EdgeInsets.all(3),
        child: Container(
          // ─── Bordure interieure (ring inside) ───────────────────────
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: _gradient,
            borderRadius: BorderRadius.circular(ArenaRadius.md),
            border: Border.all(
              color: ArenaColors.void_.withValues(alpha: 0.6),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              _Header(
                tierLabel: tierLabel,
                tierEmoji: tierEmoji,
                gameLabel: gameLabel,
                statusLabel: statusLabel,
                isRegistered: isRegistered,
              ),
              _DottedDivider(color: accent),
              _HeroSection(
                emoji: _heroEmoji,
                hasPrize: _hasPrize || _isPaid,
                prizeAmount: c.prizePoolLocal,
                prizeCurrency:
                    c.prizePoolCurrency ?? c.registrationCurrency,
                accent: accent,
              ),
              _DottedDivider(color: accent),
              _Footer(
                title: c.name,
                playersLabel:
                    '${c.currentPlayers}/${c.maxPlayers} joueurs',
                dateLabel: _dateLabel(c.startDate),
                feeLabel: _isPaid
                    ? '${_money(c.registrationFee)} ${c.registrationCurrency}'
                    : 'GRATUIT',
              ),
            ],
          ),
        ),
      ),
    );

    if (onRegister == null) return card;

    final ctaVariant = _isPaid
        ? ArenaButtonVariant.primary
        : ArenaButtonVariant.success;
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
          variant: hasPendingPayment
              ? ArenaButtonVariant.secondary
              : ctaVariant,
          fullWidth: true,
          onPressed: onRegister,
        ),
      ],
    );
  }

  static String _gameLabel(GameType g) => switch (g) {
        GameType.efootball => '⚽ EFOOT',
        GameType.draughts => '🔴 DAMES',
        GameType.eaSportsFc => '🎯 FC',
      };

  static String _statusLabel(CompetitionStatus s) => switch (s) {
        CompetitionStatus.draft => 'BROUILLON',
        CompetitionStatus.registrationOpen => 'OUVERT',
        CompetitionStatus.registrationClosed => 'FERMÉ',
        CompetitionStatus.ongoing => 'EN COURS',
        CompetitionStatus.completed => 'TERMINÉ',
        CompetitionStatus.cancelled => 'ANNULÉ',
      };

  static String _money(double v) =>
      NumberFormat.decimalPattern('fr').format(v).replaceAll(',', ' ');

  static String _dateLabel(DateTime startUtc) =>
      DateFormat('d MMM · HH:mm', 'fr').format(startUtc.toLocal());
}

// ════════════════════════════════════════════════════════════════════════
// HEADER
// ════════════════════════════════════════════════════════════════════════

/// Bandeau du haut — fond noir translucide pour rester lisible sur le
/// gradient tier, avec le badge tier a gauche et le badge game a droite.
class _Header extends StatelessWidget {
  const _Header({
    required this.tierLabel,
    required this.tierEmoji,
    required this.gameLabel,
    required this.statusLabel,
    required this.isRegistered,
  });

  final String tierLabel;
  final String tierEmoji;
  final String gameLabel;
  final String statusLabel;
  final bool isRegistered;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ArenaSpacing.md,
        vertical: ArenaSpacing.sm,
      ),
      color: ArenaColors.void_.withValues(alpha: 0.55),
      child: Row(
        children: [
          Text(
            '$tierEmoji  $tierLabel',
            style: ArenaText.badge.copyWith(
              color: ArenaColors.bone,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              fontSize: 11,
            ),
          ),
          if (isRegistered) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: ArenaColors.statusOk,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '✓ INSCRIT',
                style: ArenaText.small.copyWith(
                  color: ArenaColors.void_,
                  fontWeight: FontWeight.w900,
                  fontSize: 9,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ],
          const Spacer(),
          Text(
            statusLabel,
            style: ArenaText.small.copyWith(
              color: ArenaColors.bone.withValues(alpha: 0.75),
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              fontSize: 10,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: ArenaColors.bone.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            gameLabel,
            style: ArenaText.small.copyWith(
              color: ArenaColors.bone,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// HERO (zone valeur du gain)
// ════════════════════════════════════════════════════════════════════════

/// Section centrale "trading card" — emoji XL + montant XXL + label.
/// Cas gratuite pure (sans prize) : message "JEU AMICAL" a la place.
class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.emoji,
    required this.hasPrize,
    required this.prizeAmount,
    required this.prizeCurrency,
    required this.accent,
  });

  final String emoji;
  final bool hasPrize;
  final double prizeAmount;
  final String prizeCurrency;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    if (!hasPrize || prizeAmount <= 0) {
      // Gratuit pur — pas de gain a montrer
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ArenaSpacing.md,
          vertical: ArenaSpacing.lg,
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 6),
            Text(
              'JEU AMICAL',
              style: ArenaText.h3.copyWith(
                color: ArenaColors.bone,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Pas de gain · Pour le fun',
              style: ArenaText.small.copyWith(
                color: ArenaColors.bone.withValues(alpha: 0.75),
                fontSize: 11,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ArenaSpacing.md,
        vertical: ArenaSpacing.lg,
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 6),
          // ─── Montant XXL ───────────────────────────────────────────
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  _formatMoney(prizeAmount),
                  style: ArenaText.mono.copyWith(
                    color: ArenaColors.bone,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    height: 1,
                    shadows: [
                      Shadow(
                        color: ArenaColors.void_.withValues(alpha: 0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  prizeCurrency,
                  style: ArenaText.mono.copyWith(
                    color: ArenaColors.bone.withValues(alpha: 0.85),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // ─── Label etoiles "★ A GAGNER ★" ──────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 20,
                height: 1,
                color: ArenaColors.bone.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 6),
              Text(
                '★  À GAGNER  ★',
                style: ArenaText.badge.copyWith(
                  color: ArenaColors.bone,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.6,
                  fontSize: 10,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 20,
                height: 1,
                color: ArenaColors.bone.withValues(alpha: 0.5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatMoney(double v) =>
      NumberFormat.decimalPattern('fr').format(v).replaceAll(',', ' ');
}

// ════════════════════════════════════════════════════════════════════════
// FOOTER (titre + stats)
// ════════════════════════════════════════════════════════════════════════

/// Bandeau du bas — titre Bebas centre + 3 hex stats (joueurs · entrée · date).
class _Footer extends StatelessWidget {
  const _Footer({
    required this.title,
    required this.playersLabel,
    required this.dateLabel,
    required this.feeLabel,
  });

  final String title;
  final String playersLabel;
  final String dateLabel;
  final String feeLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ArenaSpacing.md,
        vertical: ArenaSpacing.sm + 2,
      ),
      color: ArenaColors.void_.withValues(alpha: 0.55),
      child: Column(
        children: [
          Text(
            title.toUpperCase(),
            style: ArenaText.h3.copyWith(
              color: ArenaColors.bone,
              fontSize: 14,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          // ─── Stats : 3 hexagones (joueurs · entrée · date) ─────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _HexStat(icon: '⬢', label: playersLabel),
              _HexStat(icon: '⬢', label: feeLabel),
              _HexStat(icon: '⬢', label: dateLabel),
            ],
          ),
        ],
      ),
    );
  }
}

class _HexStat extends StatelessWidget {
  const _HexStat({required this.icon, required this.label});
  final String icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            icon,
            style: TextStyle(
              fontSize: 9,
              color: ArenaColors.bone.withValues(alpha: 0.7),
              height: 1,
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: ArenaText.small.copyWith(
                color: ArenaColors.bone.withValues(alpha: 0.85),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// DOTTED DIVIDER
// ════════════════════════════════════════════════════════════════════════

/// Divider en pointilles (style ticket / trading card) couleur tier.
/// Calcule dynamiquement le nombre de dashes selon la largeur disponible.
class _DottedDivider extends StatelessWidget {
  const _DottedDivider({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 4.0;
        const gapWidth = 4.0;
        final count =
            (constraints.maxWidth / (dashWidth + gapWidth)).floor();
        return SizedBox(
          height: 1,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List<Widget>.generate(
              count,
              (_) => Container(
                width: dashWidth,
                height: 1,
                color: color.withValues(alpha: 0.65),
              ),
            ),
          ),
        );
      },
    );
  }
}
