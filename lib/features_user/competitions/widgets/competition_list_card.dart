import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/competition.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Card d'une competition dans la liste #10.
///
/// Deux designs distincts pour rendre la **valeur economique** lisible
/// en un coup d'oeil — c'est le point d'entree principal de l'app et le
/// joueur compare des dizaines de tournois :
///
/// * **Payante** (`registrationFee > 0`) : accent or chaud, badge
///   `★ PREMIUM`, bloc footer split ENTREE / A GAGNER. Le CTA reprend
///   le montant de l'inscription en or.
/// * **Gratuite avec recompense** (`isFree && prizePoolLocal > 0`) :
///   badge vert `GRATUIT`, mais headline sur la recompense
///   (`🎁 GAGNE X XAF`) en grand pour donner envie de cliquer.
/// * **Gratuite sans recompense** : badge `GRATUIT` simple, footer
///   minimaliste "JEU AMICAL".
///
/// Tous trois partagent le meme gradient game-themed (eFoot / FIFA / FC)
/// en arriere-plan pour conserver l'identite visuelle de la ligue.
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

  /// `true` quand un paiement de cet utilisateur sur cette comp est en
  /// `awaiting_admin`. Le bouton CTA passe alors a `VOIR LE STATUT`.
  final bool hasPendingPayment;
  final VoidCallback onTap;

  /// `null` quand le joueur est deja inscrit OU que la comp n'accepte
  /// plus d'inscriptions. Sinon, bouton `S'INSCRIRE` visible sous la card.
  final VoidCallback? onRegister;

  bool get _isPaid => !competition.isFree;
  bool get _hasPrize => competition.prizePoolLocal > 0;

  @override
  Widget build(BuildContext context) {
    final c = competition;
    final gradient = _gradientFor(c.game);
    final statusLabel = _statusLabel(c.status);
    final players = '${c.currentPlayers}/${c.maxPlayers} joueurs';

    final accent = _isPaid ? ArenaColors.tierGoldWarm : ArenaColors.statusOk;

    final banner = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ArenaRadius.lg),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(ArenaRadius.lg),
          border: Border.all(
            color: isRegistered ? ArenaColors.statusOk : accent,
            width: isRegistered ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: ArenaColors.void_.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            if (_isPaid)
              BoxShadow(
                color: ArenaColors.tierGoldWarm.withValues(alpha: 0.25),
                blurRadius: 18,
                spreadRadius: -6,
              ),
          ],
        ),
        padding: const EdgeInsets.all(ArenaSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Top : tier badge + statut ────────────────────────────
            Row(
              children: [
                _TierBadge(isPaid: _isPaid, hasPrize: _hasPrize),
                const Spacer(),
                _StatusPill(label: statusLabel),
              ],
            ),
            const SizedBox(height: ArenaSpacing.sm),
            // ─── Titre + date ─────────────────────────────────────────
            Text(
              c.name,
              style: ArenaText.h3.copyWith(
                color: ArenaColors.bone,
                fontSize: 17,
                letterSpacing: 0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 12,
                  color: ArenaColors.bone.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  _dateLabel(c.startDate),
                  style: ArenaText.small.copyWith(
                    color: ArenaColors.bone.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(width: ArenaSpacing.sm),
                Icon(
                  Icons.group_outlined,
                  size: 12,
                  color: ArenaColors.bone.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    players,
                    style: ArenaText.small.copyWith(
                      color: ArenaColors.bone.withValues(alpha: 0.75),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isRegistered) ...[
                  const SizedBox(width: ArenaSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: ArenaColors.statusOk.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '✓ INSCRIT',
                      style: ArenaText.small.copyWith(
                        color: ArenaColors.bone,
                        fontWeight: FontWeight.w700,
                        fontSize: 9,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: ArenaSpacing.md),
            // ─── Footer : prix d'entree + recompense ──────────────────
            _PriceFooter(
              registrationFee: c.registrationFee,
              registrationCurrency: c.registrationCurrency,
              prizePool: c.prizePoolLocal,
              prizeCurrency: c.prizePoolCurrency ?? c.registrationCurrency,
              isPaid: _isPaid,
            ),
          ],
        ),
      ),
    );

    if (onRegister == null) return banner;
    // Payante -> bouton primaire bleu (action principale, montant
    // affiche). Gratuite -> success vert (action sans friction).
    final ctaVariant = _isPaid
        ? ArenaButtonVariant.primary
        : ArenaButtonVariant.success;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        banner,
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

  static LinearGradient _gradientFor(GameType game) => switch (game) {
        GameType.efootball => ArenaColors.bannerEfoot,
        GameType.fifaMobile => ArenaColors.bannerFifa,
        GameType.eaSportsFc => ArenaColors.bannerFc,
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

/// Badge tier en haut a gauche de la card.
///  - payant   : `★ PREMIUM` en or
///  - gratuit avec prize : `🎁 GRATUIT + GAINS` en vert
///  - gratuit pur        : `GRATUIT` en vert
class _TierBadge extends StatelessWidget {
  const _TierBadge({required this.isPaid, required this.hasPrize});
  final bool isPaid;
  final bool hasPrize;

  @override
  Widget build(BuildContext context) {
    final (label, color) = isPaid
        ? ('★ PREMIUM', ArenaColors.tierGoldWarm)
        : hasPrize
            ? ('🎁 GRATUIT + GAINS', ArenaColors.statusOk)
            : ('GRATUIT', ArenaColors.statusOk);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(ArenaRadius.round),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.45),
            blurRadius: 10,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Text(
        label,
        style: ArenaText.badge.copyWith(
          color: ArenaColors.void_,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          fontSize: 10,
        ),
      ),
    );
  }
}

/// Footer prix d'entree / recompense — c'est la zone "valeur" de la card.
///  - payant   : 2 colonnes ENTREE / A GAGNER cote a cote
///  - gratuit avec prize : bandeau plein "🎁 GAGNE X" mis en avant
///  - gratuit pur        : ligne simple "JEU AMICAL · pas de gain"
class _PriceFooter extends StatelessWidget {
  const _PriceFooter({
    required this.registrationFee,
    required this.registrationCurrency,
    required this.prizePool,
    required this.prizeCurrency,
    required this.isPaid,
  });

  final double registrationFee;
  final String registrationCurrency;
  final double prizePool;
  final String prizeCurrency;
  final bool isPaid;

  @override
  Widget build(BuildContext context) {
    if (isPaid) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _PriceBlock(
              label: 'ENTRÉE',
              value: _CompetitionMoney.format(registrationFee),
              currency: registrationCurrency,
              accent: ArenaColors.tierGoldWarm,
            ),
          ),
          if (prizePool > 0) ...[
            const SizedBox(width: ArenaSpacing.sm),
            Expanded(
              child: _PriceBlock(
                label: 'À GAGNER',
                value: _CompetitionMoney.format(prizePool),
                currency: prizeCurrency,
                accent: ArenaColors.statusOk,
              ),
            ),
          ],
        ],
      );
    }
    // Gratuit
    if (prizePool > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ArenaSpacing.md,
          vertical: ArenaSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: ArenaColors.statusOk.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(ArenaRadius.md),
          border: Border.all(color: ArenaColors.statusOk),
        ),
        child: Row(
          children: [
            const Text('🎁 ', style: TextStyle(fontSize: 18)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'À GAGNER',
                    style: ArenaText.small.copyWith(
                      color: ArenaColors.statusOk,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.9,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    '${_CompetitionMoney.format(prizePool)} $prizeCurrency',
                    style: ArenaText.mono.copyWith(
                      color: ArenaColors.bone,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    // Gratuit pur — sobre.
    return Row(
      children: [
        Icon(
          Icons.sports_esports_outlined,
          size: 14,
          color: ArenaColors.bone.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 6),
        Text(
          'JEU AMICAL · PAS DE GAIN',
          style: ArenaText.small.copyWith(
            color: ArenaColors.bone.withValues(alpha: 0.7),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class _PriceBlock extends StatelessWidget {
  const _PriceBlock({
    required this.label,
    required this.value,
    required this.currency,
    required this.accent,
  });

  final String label;
  final String value;
  final String currency;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ArenaSpacing.sm,
        vertical: ArenaSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: ArenaColors.void_.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(ArenaRadius.md),
        border: Border.all(color: accent.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: ArenaText.small.copyWith(
              color: accent,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.9,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: ArenaText.mono.copyWith(
                    color: ArenaColors.bone,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  currency,
                  style: ArenaText.small.copyWith(
                    color: ArenaColors.bone.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pill statut (OUVERT/EN COURS/...) — fond bone @ 25 % translucide qui
/// reste lisible sur n'importe quel gradient game, texte bone bold mono.
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: ArenaColors.bone.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(ArenaRadius.round),
      ),
      child: Text(
        label,
        style: ArenaText.badge.copyWith(
          color: ArenaColors.bone,
          letterSpacing: 0.9,
        ),
      ),
    );
  }
}

class _CompetitionMoney {
  static String format(double v) =>
      NumberFormat.decimalPattern('fr').format(v).replaceAll(',', ' ');
}
