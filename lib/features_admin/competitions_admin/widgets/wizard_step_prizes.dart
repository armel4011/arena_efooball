import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/features_admin/competitions_admin/widgets/competition_form_widgets.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:flutter/material.dart';

/// Étape 3 du wizard — répartition des récompenses : nombre de récompensés,
/// montant par place (top 4) et par bloc (5-8 … 65-128), total cagnotte.
///
/// Présentation pure : le calcul du total et la redistribution restent dans le
/// State du wizard (passés via [shareTotal] / [onRewardedCountChanged]).
class WizardStepPrizes extends StatelessWidget {
  const WizardStepPrizes({
    required this.rewardedCount,
    required this.currency,
    required this.topShareCtrls,
    required this.blockShareCtrls,
    required this.shareTotal,
    required this.onRewardedCountChanged,
    required this.onChanged,
    this.savedConfigCount = 0,
    this.onSaveConfig,
    this.onOpenConfigLibrary,
    super.key,
  });

  final int rewardedCount;
  final String currency;
  final List<TextEditingController> topShareCtrls;
  final List<TextEditingController> blockShareCtrls;
  final int shareTotal;
  final ValueChanged<int> onRewardedCountChanged;
  final VoidCallback onChanged;

  /// Bibliothèque de configs de récompense réutilisables (feature 2026-06-26).
  /// Optionnel : si [onSaveConfig] est nul, les boutons ne s'affichent pas.
  final int savedConfigCount;
  final VoidCallback? onSaveConfig;
  final VoidCallback? onOpenConfigLibrary;

  @override
  Widget build(BuildContext context) {
    final topCount = rewardedCount < 4 ? rewardedCount : 4;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(ArenaSpacing.md),
          decoration: BoxDecoration(
            color: ArenaColors.signalBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(ArenaRadius.md),
            border: Border.all(
              color: ArenaColors.signalBlue.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            'ℹ Saisis le montant attribué à chaque place — en $currency. '
            'La cagnotte de la compétition est la somme de ces montants.',
            style: ArenaText.body,
          ),
        ),
        const SizedBox(height: ArenaSpacing.lg),
        Text('Nombre de récompensés', style: ArenaText.inputLabel),
        const SizedBox(height: ArenaSpacing.xs),
        RewardedCountPicker(
          current: rewardedCount,
          onChanged: onRewardedCountChanged,
        ),
        const SizedBox(height: ArenaSpacing.lg),
        // Places 1 à 4 : une ligne individuelle modifiable chacune.
        for (var i = 0; i < topCount; i++) ...[
          ShareRow(
            position: i,
            controller: topShareCtrls[i],
            onChanged: onChanged,
          ),
          const SizedBox(height: ArenaSpacing.sm),
        ],
        // Blocs 5-8 / 9-16 / 17-32 / 33-64 : un montant par place, saisi une fois.
        for (var b = 0; b < prizeBlocks.length; b++)
          if (rewardedCount >= prizeBlocks[b].lastRank) ...[
            BlockShareRow(
              block: prizeBlocks[b],
              controller: blockShareCtrls[b],
              onChanged: onChanged,
            ),
            const SizedBox(height: ArenaSpacing.sm),
          ],
        const SizedBox(height: ArenaSpacing.md),
        ShareTotalCard(total: shareTotal, currency: currency),
        if (onSaveConfig != null) ...[
          const SizedBox(height: ArenaSpacing.md),
          ArenaButton(
            label: 'ENREGISTRER CETTE CONFIG',
            variant: ArenaButtonVariant.secondary,
            icon: Icons.bookmark_add_outlined,
            fullWidth: true,
            onPressed: onSaveConfig,
          ),
          if (savedConfigCount > 0) ...[
            const SizedBox(height: ArenaSpacing.xs),
            ArenaButton(
              label: 'MES CONFIGS ($savedConfigCount)',
              variant: ArenaButtonVariant.secondary,
              icon: Icons.bookmarks_outlined,
              fullWidth: true,
              onPressed: onOpenConfigLibrary,
            ),
          ],
          const SizedBox(height: ArenaSpacing.xs),
          Text(
            'Enregistre cette répartition comme modèle nommé pour la '
            'réutiliser dans tes prochaines compétitions.',
            style: ArenaText.small,
          ),
        ],
      ],
    );
  }
}
