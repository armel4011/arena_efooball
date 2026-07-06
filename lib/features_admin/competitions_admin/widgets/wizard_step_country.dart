import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/utils/supported_countries.dart';
import 'package:arena/features_shared/payment_option_draft.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Étape « Pays » du wizard — insérée après « Frais ».
///
/// 1. Sélecteur du PAYS ORGANISATEUR (single-select, défaut CM) → alimente
///    `competitions.country_code` (scoping admin).
/// 2. Si la compétition est PAYANTE (frais > 0) : éditeur des options de
///    paiement — liste de pays activés, chacun avec une liste libre
///    d'opérateurs (nom + code de transfert). Si GRATUITE : masqué, note.
///
/// Toute la donnée éditable vit dans le State parent ([PaymentDraftCountry]
/// + controllers) ; ce widget est une présentation pure qui remonte les
/// mutations via callbacks et déclenche [onChanged] pour rafraîchir la garde
/// `_canAdvance` du wizard.
class WizardStepCountry extends StatelessWidget {
  const WizardStepCountry({
    required this.organizerCountry,
    required this.onOrganizerChanged,
    required this.isPaid,
    required this.loading,
    required this.countries,
    required this.operatorTemplateCount,
    required this.onAddCountry,
    required this.onRemoveCountry,
    required this.onCountryCodeChanged,
    required this.onAddOperator,
    required this.onRemoveOperator,
    required this.onSaveOperator,
    required this.onOpenOperatorTemplates,
    required this.onChanged,
    super.key,
  });

  final String organizerCountry;
  final ValueChanged<String> onOrganizerChanged;
  final bool isPaid;

  /// Préremplissage async des options en cours (mode édition) → spinner.
  final bool loading;
  final List<PaymentDraftCountry> countries;

  /// Nombre de modèles d'opérateurs enregistrés (badge du bouton).
  final int operatorTemplateCount;

  final VoidCallback onAddCountry;
  final ValueChanged<int> onRemoveCountry;
  final void Function(int countryIndex, String code) onCountryCodeChanged;
  final ValueChanged<int> onAddOperator;
  final void Function(int countryIndex, int operatorIndex) onRemoveOperator;
  final void Function(int countryIndex, int operatorIndex) onSaveOperator;
  final ValueChanged<int> onOpenOperatorTemplates;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.countryOrganizerLabel, style: ArenaText.inputLabel),
        const SizedBox(height: ArenaSpacing.xs),
        _CountryDropdown(
          value: organizerCountry,
          onChanged: onOrganizerChanged,
        ),
        const SizedBox(height: ArenaSpacing.xs),
        Text(l10n.countryOrganizerHint, style: ArenaText.small),
        const SizedBox(height: ArenaSpacing.lg),
        if (!isPaid)
          Container(
            padding: const EdgeInsets.all(ArenaSpacing.md),
            decoration: BoxDecoration(
              color: ArenaColors.signalBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(ArenaRadius.md),
              border: Border.all(
                color: ArenaColors.signalBlue.withValues(alpha: 0.3),
              ),
            ),
            child: Text(l10n.countryFreeNote, style: ArenaText.body),
          )
        else if (loading)
          const Padding(
            padding: EdgeInsets.all(ArenaSpacing.lg),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          _PaymentEditor(
            l10n: l10n,
            countries: countries,
            operatorTemplateCount: operatorTemplateCount,
            onAddCountry: onAddCountry,
            onRemoveCountry: onRemoveCountry,
            onCountryCodeChanged: onCountryCodeChanged,
            onAddOperator: onAddOperator,
            onRemoveOperator: onRemoveOperator,
            onSaveOperator: onSaveOperator,
            onOpenOperatorTemplates: onOpenOperatorTemplates,
            onChanged: onChanged,
          ),
      ],
    );
  }
}

class _PaymentEditor extends StatelessWidget {
  const _PaymentEditor({
    required this.l10n,
    required this.countries,
    required this.operatorTemplateCount,
    required this.onAddCountry,
    required this.onRemoveCountry,
    required this.onCountryCodeChanged,
    required this.onAddOperator,
    required this.onRemoveOperator,
    required this.onSaveOperator,
    required this.onOpenOperatorTemplates,
    required this.onChanged,
  });

  final AppLocalizations l10n;
  final List<PaymentDraftCountry> countries;
  final int operatorTemplateCount;
  final VoidCallback onAddCountry;
  final ValueChanged<int> onRemoveCountry;
  final void Function(int countryIndex, String code) onCountryCodeChanged;
  final ValueChanged<int> onAddOperator;
  final void Function(int countryIndex, int operatorIndex) onRemoveOperator;
  final void Function(int countryIndex, int operatorIndex) onSaveOperator;
  final ValueChanged<int> onOpenOperatorTemplates;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(ArenaSpacing.md),
          decoration: arenaWarningCardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.countryPaymentSectionTitle, style: ArenaText.h3),
              const SizedBox(height: ArenaSpacing.xs),
              Text(l10n.countryPaymentSectionHint, style: ArenaText.small),
            ],
          ),
        ),
        const SizedBox(height: ArenaSpacing.md),
        for (var ci = 0; ci < countries.length; ci++) ...[
          _CountryCard(
            l10n: l10n,
            country: countries[ci],
            operatorTemplateCount: operatorTemplateCount,
            onRemoveCountry: () => onRemoveCountry(ci),
            onCountryCodeChanged: (code) => onCountryCodeChanged(ci, code),
            onAddOperator: () => onAddOperator(ci),
            onRemoveOperator: (oi) => onRemoveOperator(ci, oi),
            onSaveOperator: (oi) => onSaveOperator(ci, oi),
            onOpenOperatorTemplates: () => onOpenOperatorTemplates(ci),
            onChanged: onChanged,
          ),
          const SizedBox(height: ArenaSpacing.md),
        ],
        _TextButtonRow(
          icon: Icons.add_location_alt_outlined,
          label: l10n.countryAddCountry,
          onPressed: onAddCountry,
        ),
      ],
    );
  }
}

class _CountryCard extends StatelessWidget {
  const _CountryCard({
    required this.l10n,
    required this.country,
    required this.operatorTemplateCount,
    required this.onRemoveCountry,
    required this.onCountryCodeChanged,
    required this.onAddOperator,
    required this.onRemoveOperator,
    required this.onSaveOperator,
    required this.onOpenOperatorTemplates,
    required this.onChanged,
  });

  final AppLocalizations l10n;
  final PaymentDraftCountry country;
  final int operatorTemplateCount;
  final VoidCallback onRemoveCountry;
  final ValueChanged<String> onCountryCodeChanged;
  final VoidCallback onAddOperator;
  final ValueChanged<int> onRemoveOperator;
  final ValueChanged<int> onSaveOperator;
  final VoidCallback onOpenOperatorTemplates;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.md),
        border: Border.all(color: ArenaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _CountryDropdown(
                  value: country.countryCode,
                  onChanged: onCountryCodeChanged,
                ),
              ),
              IconButton(
                tooltip: l10n.countryRemoveCountry,
                icon: const Icon(
                  Icons.delete_outline,
                  color: ArenaColors.neonRed,
                ),
                onPressed: onRemoveCountry,
              ),
            ],
          ),
          const SizedBox(height: ArenaSpacing.sm),
          for (var oi = 0; oi < country.operators.length; oi++) ...[
            _OperatorRow(
              l10n: l10n,
              operator: country.operators[oi],
              canRemove: country.operators.length > 1,
              onRemove: () => onRemoveOperator(oi),
              onSave: () => onSaveOperator(oi),
              onChanged: onChanged,
            ),
            const SizedBox(height: ArenaSpacing.sm),
          ],
          Row(
            children: [
              Expanded(
                child: _TextButtonRow(
                  icon: Icons.add,
                  label: l10n.countryAddOperator,
                  onPressed: onAddOperator,
                ),
              ),
              Expanded(
                child: _TextButtonRow(
                  icon: Icons.folder_open_outlined,
                  label: l10n.countryOperatorTemplatesButton(
                    operatorTemplateCount,
                  ),
                  onPressed:
                      operatorTemplateCount > 0 ? onOpenOperatorTemplates : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OperatorRow extends StatelessWidget {
  const _OperatorRow({
    required this.l10n,
    required this.operator,
    required this.canRemove,
    required this.onRemove,
    required this.onSave,
    required this.onChanged,
  });

  final AppLocalizations l10n;
  final PaymentDraftOperator operator;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onSave;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.countryOperatorNameLabel,
                style: ArenaText.inputLabel,
              ),
            ),
            IconButton(
              tooltip: l10n.countrySaveOperator,
              visualDensity: VisualDensity.compact,
              icon: const Icon(
                Icons.bookmark_add_outlined,
                size: 18,
                color: ArenaColors.silver,
              ),
              onPressed: onSave,
            ),
            if (canRemove)
              IconButton(
                tooltip: l10n.countryRemoveOperator,
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.close,
                  size: 18,
                  color: ArenaColors.neonRed,
                ),
                onPressed: onRemove,
              ),
          ],
        ),
        const SizedBox(height: ArenaSpacing.xs),
        ArenaTextField(
          controller: operator.labelCtrl,
          hint: l10n.countryOperatorNameHint,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: ArenaSpacing.xs),
        Text(l10n.countryTransferCodeLabel, style: ArenaText.inputLabel),
        const SizedBox(height: ArenaSpacing.xs),
        ArenaTextField(
          controller: operator.codeCtrl,
          hint: l10n.countryTransferCodeHint,
          onChanged: (_) => onChanged(),
        ),
      ],
    );
  }
}

/// Dropdown pays (drapeau + nom) sur [kSupportedCountries], calqué sur le
/// style de `CurrencyPicker`.
class _CountryDropdown extends StatelessWidget {
  const _CountryDropdown({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: ArenaColors.carbon,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: ArenaSpacing.md,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ArenaRadius.md),
          borderSide: const BorderSide(color: ArenaColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ArenaRadius.md),
          borderSide: const BorderSide(color: ArenaColors.border),
        ),
      ),
      dropdownColor: ArenaColors.carbon,
      style: ArenaText.body,
      items: [
        for (final c in kSupportedCountries)
          DropdownMenuItem(
            value: c.code,
            child: Text('${c.flag}  ${c.name}', style: ArenaText.body),
          ),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

/// Bouton texte + icône compact (ajouter pays / opérateur / ouvrir modèles).
/// `onPressed` nul → désactivé (grisé automatiquement par [TextButton]).
class _TextButtonRow extends StatelessWidget {
  const _TextButtonRow({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, overflow: TextOverflow.ellipsis),
    );
  }
}
