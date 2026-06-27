import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/features_admin/competitions_admin/widgets/competition_form_widgets.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Étape 4 du wizard — frais d'inscription + codes marchands (mode payé)
/// OU quota parrainage (mode gratuit) + commission ARENA.
///
/// Sorti de `create_competition_page.dart` pour le faire passer sous
/// 1000 lignes. Toutes les pièces de state sont passées en paramètres ;
/// le widget délègue `onChanged` au parent pour le `setState`.
class WizardStepFees extends StatelessWidget {
  const WizardStepFees({
    required this.entryFeeCtrl,
    required this.currency,
    required this.commissionXafCtrl,
    required this.orangeMomoCtrl,
    required this.mtnMomoCtrl,
    required this.referralQuotaCtrl,
    required this.isEditing,
    required this.savedTemplateCount,
    required this.onChanged,
    required this.onCurrencyChanged,
    required this.onSaveTemplate,
    required this.onOpenLibrary,
    super.key,
  });

  final TextEditingController entryFeeCtrl;
  final String currency;
  final TextEditingController commissionXafCtrl;
  final TextEditingController orangeMomoCtrl;
  final TextEditingController mtnMomoCtrl;
  final TextEditingController referralQuotaCtrl;
  final bool isEditing;

  /// Nombre de jeux de codes enregistrés (affiché sur le bouton « Modèles »).
  final int savedTemplateCount;
  final VoidCallback onChanged;
  final ValueChanged<String> onCurrencyChanged;
  final VoidCallback onSaveTemplate;
  final VoidCallback onOpenLibrary;

  Widget _lockable(Widget child) {
    if (!isEditing) return child;
    return IgnorePointer(
      child: Opacity(opacity: 0.45, child: child),
    );
  }

  int _referralQuota() => int.tryParse(referralQuotaCtrl.text.trim()) ?? 0;

  @override
  Widget build(BuildContext context) {
    final fee = double.tryParse(entryFeeCtrl.text) ?? 0;
    final isPaid = fee > 0;
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
            "ℹ Frais d'inscription = 0 → compétition GRATUITE (badge sur la "
            'carte + bypass paiement). Sinon le joueur paie en P2P sur les '
            'codes marchands ci-dessous, et le super-admin valide manuellement.',
            style: ArenaText.body,
          ),
        ),
        const SizedBox(height: ArenaSpacing.md),
        Text("Frais d'inscription", style: ArenaText.inputLabel),
        const SizedBox(height: ArenaSpacing.xs),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _lockable(
                ArenaTextField(
                  controller: entryFeeCtrl,
                  hint: '0',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[0-9.]')),
                  ],
                  onChanged: (_) => onChanged(),
                ),
              ),
            ),
            const SizedBox(width: ArenaSpacing.xs),
            Expanded(
              child: _lockable(
                CurrencyPicker(
                  current: currency,
                  onChanged: onCurrencyChanged,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: ArenaSpacing.md),
        Text('Commission ARENA (montant)', style: ArenaText.inputLabel),
        const SizedBox(height: ArenaSpacing.xs),
        Text(
          'Saisi en $currency, jamais affiché côté joueur. '
          "C'est ce que l'équipe ARENA conserve, séparé de la cagnotte distribuée.",
          style: ArenaText.small,
        ),
        const SizedBox(height: ArenaSpacing.xs),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: ArenaTextField(
                controller: commissionXafCtrl,
                hint: '0',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[0-9.]')),
                ],
                onChanged: (_) => onChanged(),
              ),
            ),
            const SizedBox(width: ArenaSpacing.xs),
            Expanded(
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: ArenaColors.carbon,
                  borderRadius: BorderRadius.circular(ArenaRadius.md),
                  border: Border.all(color: ArenaColors.border),
                ),
                child: Text(currency, style: ArenaText.body),
              ),
            ),
          ],
        ),
        if (!isPaid) ...[
          const SizedBox(height: ArenaSpacing.lg),
          Container(
            padding: const EdgeInsets.all(ArenaSpacing.md),
            decoration: BoxDecoration(
              color: ArenaColors.tierGoldWarm.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(ArenaRadius.md),
              border: Border.all(
                color: ArenaColors.tierGoldWarm.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '👥 Parrainage requis (optionnel — Lot D)',
                  style: ArenaText.h3,
                ),
                const SizedBox(height: ArenaSpacing.xs),
                Text(
                  'Force le joueur à parrainer N personnes via son code '
                  "(ARN-XXXX) avant de pouvoir s'inscrire. Pertinent pour "
                  'les compétitions gratuites avec récompense. 0 = pas de '
                  'gating.',
                  style: ArenaText.small,
                ),
                const SizedBox(height: ArenaSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: ArenaTextField(
                        controller: referralQuotaCtrl,
                        hint: '0',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (_) => onChanged(),
                      ),
                    ),
                    const SizedBox(width: ArenaSpacing.xs),
                    Expanded(
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: ArenaColors.carbon,
                          borderRadius: BorderRadius.circular(ArenaRadius.md),
                          border: Border.all(color: ArenaColors.border),
                        ),
                        child: Text('amis', style: ArenaText.body),
                      ),
                    ),
                  ],
                ),
                if (_referralQuota() > 0) ...[
                  const SizedBox(height: ArenaSpacing.sm),
                  Text(
                    'Tout invité actif compte vers le quota '
                    '(création de compte suffisante).',
                    style: ArenaText.small,
                  ),
                ],
              ],
            ),
          ),
        ],
        if (isPaid) ...[
          const SizedBox(height: ArenaSpacing.lg),
          Container(
            padding: const EdgeInsets.all(ArenaSpacing.md),
            decoration: arenaWarningCardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📱 Codes marchands (requis pour comp. payante)',
                  style: ArenaText.h3,
                ),
                const SizedBox(height: ArenaSpacing.xs),
                Text(
                  'Affichés au joueur sur P2 quand il paie. Le super-admin '
                  'valide ensuite manuellement chaque transaction reçue.',
                  style: ArenaText.small,
                ),
              ],
            ),
          ),
          const SizedBox(height: ArenaSpacing.md),
          Text('Code marchand Orange Money', style: ArenaText.inputLabel),
          const SizedBox(height: ArenaSpacing.xs),
          ArenaTextField(
            controller: orangeMomoCtrl,
            hint: 'ex. *126*1*001234#',
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(height: ArenaSpacing.md),
          Text('Code marchand MTN MoMo', style: ArenaText.inputLabel),
          const SizedBox(height: ArenaSpacing.xs),
          ArenaTextField(
            controller: mtnMomoCtrl,
            hint: 'ex. *126*7*009876#',
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: onSaveTemplate,
                  icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                  label: const Text('Enregistrer ces codes'),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: savedTemplateCount > 0 ? onOpenLibrary : null,
                  icon: const Icon(Icons.folder_open_outlined, size: 18),
                  label: Text('Modèles ($savedTemplateCount)'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
