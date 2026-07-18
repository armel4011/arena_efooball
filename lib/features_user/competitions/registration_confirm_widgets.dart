part of 'registration_confirm_page.dart';

/// Titre display tout en haut du checkout — reproduit le `m-text-display`
/// de la maquette avec un accent italic ice-cyan sur la fin de phrase
/// ("Confirme ton inscription.") pour donner du caractère.
class _DisplayTitle extends StatelessWidget {
  const _DisplayTitle();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return RichText(
      text: TextSpan(
        style: ArenaText.h1.copyWith(
          color: ArenaColors.bone,
          fontSize: 28,
          letterSpacing: 1,
          height: 1,
        ),
        children: [
          TextSpan(text: l10n.regConfirmDisplayTitleStart),
          TextSpan(
            text: l10n.regConfirmDisplayTitleAccent,
            style: ArenaText.serifAccent.copyWith(
              color: ArenaColors.iceCyan,
              fontSize: 22,
            ),
          ),
        ],
      ),
    );
  }
}

/// Banner premium pour la compétition — reproduit `.m-banner` de la
/// maquette (~70 px). Gradient `signalBlueDark → signalBlue` (sans
/// couleur game-themed pour rester neutre — la page checkout n'a pas
/// accès au `GameType` enum, seulement au label string). Affiche un
/// pill `GRATUIT` ou `PAYANTE` en haut à droite.
class _CompetitionBanner extends StatelessWidget {
  const _CompetitionBanner({
    required this.name,
    required this.gameLabel,
    required this.gameEmoji,
    required this.dateLabel,
    required this.formatLabel,
    required this.isFree,
  });

  final String name;
  final String gameLabel;
  final String gameEmoji;
  final String dateLabel;
  final String formatLabel;
  final bool isFree;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ArenaSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ArenaColors.signalBlue, ArenaColors.signalBlueDark],
        ),
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        boxShadow: const [
          BoxShadow(
            color: ArenaColors.signalBlueGlow,
            blurRadius: 18,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name.toUpperCase(),
                  style: ArenaText.h2.copyWith(
                    color: ArenaColors.bone,
                    fontSize: 18,
                    letterSpacing: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: ArenaSpacing.xs),
              _Pill(
                label: isFree ? l10n.regConfirmPillFree : l10n.regConfirmPillPaid,
                accent:
                    isFree ? ArenaColors.statusOk : ArenaColors.tierGoldWarm,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$gameEmoji  $gameLabel  ·  $formatLabel',
            style: ArenaText.small.copyWith(
              color: ArenaColors.bone.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '🗓  $dateLabel',
            style: ArenaText.small.copyWith(
              color: ArenaColors.bone.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pill `GRATUIT` / `PAYANTE` — fond `bone @ 25 %` translucide, texte
/// `accent` bold mono.
class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: ArenaColors.bone.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(ArenaRadius.round),
      ),
      child: Text(
        label,
        style: ArenaText.badge.copyWith(
          color: ArenaColors.bone,
          letterSpacing: 1,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PaymentBreakdown extends StatelessWidget {
  const _PaymentBreakdown({required this.entryFeeXaf});

  final int entryFeeXaf;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(color: ArenaColors.border),
      ),
      child: Column(
        children: [
          _Row(
            label: l10n.regConfirmBreakdownFee,
            value: '${_formatXaf(entryFeeXaf)} XAF',
          ),
          const ArenaDivider(),
          _Row(
            label: l10n.regConfirmBreakdownService,
            value: l10n.regConfirmBreakdownServiceIncluded,
          ),
          const ArenaDivider(),
          _Row(
            label: l10n.regConfirmBreakdownTotal,
            value: '${_formatXaf(entryFeeXaf)} XAF',
            emphasis: true,
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.emphasis = false,
  });
  final String label;
  final String value;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ArenaSpacing.md,
        vertical: 10,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: emphasis ? ArenaText.h3 : ArenaText.bodyMuted,
            ),
          ),
          Text(
            value,
            style: emphasis
                ? ArenaText.monoLg.copyWith(color: ArenaColors.signalBlue)
                : ArenaText.mono,
          ),
        ],
      ),
    );
  }
}

/// Répartition des gains — total en `bigNumber` vert au centre, puis
/// **tous** les rangs récompensés affichés dans une grille de cards
/// (4 colonnes, multi-lignes si > 4). Reproduit la maquette `m-row gap:
/// 6px` + `m-card flex:1 align-items:center` mais wrap automatiquement
/// pour supporter les compétitions à 8 / 16 / 32 / 64 rangs (max
/// `kMaxRewardedRanks` configurable côté admin).
///
/// Palette : podium (tierGoldWarm / silver / hotCoral) sur les 3
/// premiers, puis pearl pour le reste — distingue visuellement le
/// podium sans saturer les rangs de fond de classement.
class _PrizeDistribution extends StatelessWidget {
  const _PrizeDistribution({
    required this.totalXaf,
    required this.distribution,
  });

  final int totalXaf;

  /// Montants de gain par rang (en monnaie locale), fournis par la
  /// compétition. Toutes les places configurées par l'admin sont
  /// affichées, y compris celles à 0.
  final List<int> distribution;

  /// Couleur dédiée par rang. Les 3 premiers ont leur métal dédié,
  /// les suivants utilisent `pearl` (texte secondaire premium).
  static Color _colorForRank(int position) {
    switch (position) {
      case 0:
        return ArenaColors.tierGoldWarm;
      case 1:
        return ArenaColors.silver;
      case 2:
        return ArenaColors.hotCoral;
      default:
        return ArenaColors.pearl;
    }
  }

  // Layout : 4 colonnes fixes, peu importe le nombre de rangs. Le
  // LayoutBuilder calcule la largeur exacte de chaque card pour
  // respecter le spacing 6 px entre colonnes — évite le débordement
  // horizontal qu'aurait un Row avec >4 enfants.
  static const _columns = 4;
  static const _gap = 6.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ranks = distribution.length > kMaxRewardedRanks
        ? kMaxRewardedRanks
        : distribution.length;
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.lg),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(color: ArenaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(
              '${_formatXaf(totalXaf)} XAF',
              style: ArenaText.bigNumber.copyWith(
                color: ArenaColors.statusOk,
                fontSize: 28,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Center(
            child: Text(
              ranks <= 1
                  ? l10n.regConfirmRanksRewardedSingle
                  : '$ranks${l10n.regConfirmRanksRewardedPluralSuffix}',
              style: ArenaText.small.copyWith(color: ArenaColors.silver),
            ),
          ),
          const SizedBox(height: ArenaSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth =
                  (constraints.maxWidth - _gap * (_columns - 1)) / _columns;
              return Wrap(
                spacing: _gap,
                runSpacing: _gap,
                children: [
                  for (var i = 0; i < ranks; i++)
                    SizedBox(
                      width: cardWidth,
                      child: _RankCard(
                        emoji: prizeRankEmoji(i),
                        rankNumber: i + 1,
                        amount: distribution[i],
                        color: _colorForRank(i),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Mini card par rang — emoji 🥇/🥈/🥉/🏅 + indicateur `Nᵉ` (à partir
/// du 4ᵉ, l'emoji 🏅 ne discrimine plus le rang exact) + montant en
/// mono. Fond et border colorés selon `color` (gold/silver/hotCoral/
/// pearl).
class _RankCard extends StatelessWidget {
  const _RankCard({
    required this.emoji,
    required this.rankNumber,
    required this.amount,
    required this.color,
  });

  final String emoji;
  final int rankNumber;
  final int amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final showRankNumber = rankNumber > 3;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(ArenaRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          if (showRankNumber) ...[
            const SizedBox(height: 2),
            Text(
              prizeRankLabel(rankNumber - 1),
              style: ArenaText.mono.copyWith(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            _formatXaf(amount),
            style: ArenaText.mono.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _AckTile extends StatelessWidget {
  const _AckTile({required this.checked, required this.onChanged});
  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return InkWell(
      onTap: () => onChanged(!checked),
      borderRadius: BorderRadius.circular(ArenaRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(ArenaSpacing.md),
        decoration: BoxDecoration(
          color: ArenaColors.carbon,
          borderRadius: BorderRadius.circular(ArenaRadius.lg),
          border: Border.all(
            color: checked ? ArenaColors.signalBlue : ArenaColors.border,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(value: checked, onChanged: (v) => onChanged(v ?? false)),
            const SizedBox(width: ArenaSpacing.sm),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  l10n.regConfirmAckLabel,
                  style: ArenaText.body,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatXaf(int amount) {
  final s = amount.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  return buf.toString();
}

/// 2 boutons stores (Item 1 prompt 2026-05-19). Affichés en Row quand
/// les 2 sont présents, l'un en dessous de l'autre sinon.
class _StoreButtons extends StatelessWidget {
  const _StoreButtons({this.androidUrl, this.iosUrl});

  final String? androidUrl;
  final String? iosUrl;

  Future<void> _open(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.regConfirmStoreLinkError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasAndroid = androidUrl != null && androidUrl!.isNotEmpty;
    final hasIos = iosUrl != null && iosUrl!.isNotEmpty;
    if (!hasAndroid && !hasIos) return const SizedBox.shrink();

    final androidBtn = hasAndroid
        ? ArenaButton(
            label: l10n.regConfirmPlayStore,
            icon: Icons.android,
            fullWidth: true,
            variant: ArenaButtonVariant.secondary,
            onPressed: () => _open(context, androidUrl!),
          )
        : null;
    final iosBtn = hasIos
        ? ArenaButton(
            label: l10n.regConfirmAppStore,
            icon: Icons.apple,
            fullWidth: true,
            variant: ArenaButtonVariant.secondary,
            onPressed: () => _open(context, iosUrl!),
          )
        : null;

    if (hasAndroid && hasIos) {
      return Row(
        children: [
          Expanded(child: androidBtn!),
          const SizedBox(width: ArenaSpacing.sm),
          Expanded(child: iosBtn!),
        ],
      );
    }
    return androidBtn ?? iosBtn!;
  }
}
