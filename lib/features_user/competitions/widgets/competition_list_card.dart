import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/competition.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Card d'une compétition dans la liste #10 — reproduit `.m-banner-efoot/
/// fifa/fc` de `arena_premium_reference.html` : un banner pleine largeur
/// au gradient game-themed (eFoot bleu / FIFA vert / FC orange), titre
/// bone (préfixé d'une ★ pour les payantes), badge statut translucide à
/// droite, et meta bottom "N/M joueurs · ✓ INSCRIT (opt) · fee XAF".
///
/// Quand `onRegister != null`, un bouton `S'INSCRIRE` (ou `VOIR LE
/// STATUT` en cas de paiement en attente) est rendu juste sous le banner
/// en `ArenaButtonVariant.primary` (full width). Le précédent split
/// Paid/Free Card a été fusionné ici — la distinction visuelle se fait
/// désormais via l'étoile préfixe et la libellé du fee (`GRATUIT` ou
/// montant en mono).
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
  /// `awaiting_admin`. Le bouton CTA passe alors à `VOIR LE STATUT`.
  final bool hasPendingPayment;
  final VoidCallback onTap;

  /// `null` quand le joueur est déjà inscrit OU que la comp n'accepte
  /// plus d'inscriptions. Sinon, bouton `S'INSCRIRE` visible sous la card.
  final VoidCallback? onRegister;

  @override
  Widget build(BuildContext context) {
    final c = competition;
    final gradient = _gradientFor(c.game);
    final statusLabel = _statusLabel(c.status);
    final feeLabel = c.isFree
        ? 'GRATUIT'
        : '${_money(c.registrationFee)} ${c.registrationCurrency}';
    final players = '${c.currentPlayers}/${c.maxPlayers} joueurs';
    final title = c.isFree ? c.name : '★ ${c.name}';

    final banner = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ArenaRadius.lg),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(ArenaRadius.lg),
          border: isRegistered
              ? Border.all(color: ArenaColors.statusOk, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: ArenaColors.void_.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(ArenaSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: ArenaText.h3.copyWith(
                      color: ArenaColors.bone,
                      fontSize: 16,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: ArenaSpacing.xs),
                _StatusPill(label: statusLabel),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _dateLabel(c.startDate),
              style: ArenaText.small.copyWith(
                color: ArenaColors.bone.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: ArenaSpacing.sm),
            Row(
              children: [
                Text(
                  players,
                  style: ArenaText.small.copyWith(
                    color: ArenaColors.bone.withValues(alpha: 0.9),
                  ),
                ),
                if (isRegistered) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      '·',
                      style: ArenaText.small.copyWith(
                        color: ArenaColors.bone.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  Text(
                    '✓ INSCRIT',
                    style: ArenaText.small.copyWith(
                      color: ArenaColors.bone,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  feeLabel,
                  style: ArenaText.mono.copyWith(
                    color: ArenaColors.bone,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (onRegister == null) return banner;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        banner,
        const SizedBox(height: ArenaSpacing.sm),
        ArenaButton(
          label: hasPendingPayment
              ? '⏱ VOIR LE STATUT DU PAIEMENT'
              : c.isFree
                  ? "S'INSCRIRE GRATUITEMENT"
                  : "S'INSCRIRE · ${_money(c.registrationFee)} ${c.registrationCurrency}",
          variant: hasPendingPayment
              ? ArenaButtonVariant.secondary
              : ArenaButtonVariant.primary,
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
