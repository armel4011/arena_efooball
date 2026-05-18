import 'package:arena/core/theme/arena_theme.dart';
import 'package:flutter/material.dart';

/// Lot C — Widget filtre déroulant générique (item 1 du prompt utilisateur).
/// Réunit les filtres scattered d'une page dans une icône cliquable :
/// au tap, ouvre une bottom-sheet plein écran avec des sections de
/// filtres organisées. Chaque section est un `ArenaFilterSection` qui
/// peut être :
///   - `radio` (mono-sélection — ex. status, pays unique)
///   - `multi` (multi-sélection — ex. activité)
///
/// Le widget est totalement contrôlé : il reçoit les valeurs en input et
/// les changements passent par le callback `onApply(snapshot)`. La
/// pastille de comptage `activeCount` est calculée par le parent — le
/// menu n'enregistre rien de son côté.
///
/// Exemple :
/// ```dart
/// ArenaFilterMenu(
///   activeCount: filter.activeFilterCount,
///   sections: const [
///     ArenaFilterSection(
///       key: 'status',
///       title: 'Statut',
///       mode: ArenaFilterMode.radio,
///       options: [
///         ArenaFilterOption(id: 'active', label: 'Actifs'),
///         ArenaFilterOption(id: 'banned', label: 'Bannis'),
///       ],
///     ),
///   ],
///   initialSelection: {'status': [filter.status]},
///   onApply: (snapshot) => setState(() => filter = filter.copyWith(...)),
/// )
/// ```
class ArenaFilterMenu extends StatelessWidget {
  const ArenaFilterMenu({
    required this.sections,
    required this.initialSelection,
    required this.onApply,
    this.activeCount = 0,
    this.label = 'FILTRES',
    super.key,
  });

  /// Sections affichées dans la bottom-sheet, dans l'ordre.
  final List<ArenaFilterSection> sections;

  /// Valeurs initiales par sectionId → liste d'IDs sélectionnés.
  final Map<String, List<String>> initialSelection;

  /// Notification quand l'utilisateur tape "Appliquer".
  final ValueChanged<Map<String, List<String>>> onApply;

  /// Pastille de compteur. 0 = pas de badge.
  final int activeCount;

  /// Label affiché à côté de l'icône (override pour le test).
  final String label;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _open(context),
      borderRadius: BorderRadius.circular(ArenaRadius.round),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ArenaSpacing.md,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: activeCount > 0
              ? ArenaColors.signalBlue.withValues(alpha: 0.15)
              : ArenaColors.carbon,
          borderRadius: BorderRadius.circular(ArenaRadius.round),
          border: Border.all(
            color: activeCount > 0
                ? ArenaColors.signalBlue
                : ArenaColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_list_rounded,
              size: 18,
              color: activeCount > 0
                  ? ArenaColors.signalBlue
                  : ArenaColors.silver,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: ArenaText.body.copyWith(
                color: activeCount > 0
                    ? ArenaColors.signalBlue
                    : ArenaColors.silver,
                fontWeight:
                    activeCount > 0 ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            if (activeCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 1,
                ),
                decoration: BoxDecoration(
                  color: ArenaColors.signalBlue,
                  borderRadius: BorderRadius.circular(ArenaRadius.round),
                ),
                child: Text(
                  '$activeCount',
                  style: ArenaText.small.copyWith(
                    color: ArenaColors.bone,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: ArenaColors.void_,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ArenaRadius.lg),
        ),
      ),
      builder: (sheetCtx) => _ArenaFilterSheet(
        sections: sections,
        initialSelection: initialSelection,
        onApply: (snapshot) {
          onApply(snapshot);
          Navigator.of(sheetCtx).pop();
        },
      ),
    );
  }
}

/// Une section de la bottom-sheet du filtre. Soit mono-sélection
/// (radio), soit multi-sélection (checkbox).
class ArenaFilterSection {
  const ArenaFilterSection({
    required this.id,
    required this.title,
    required this.options,
    this.mode = ArenaFilterMode.multi,
  });

  /// Identifiant unique (clé du Map de selection).
  final String id;

  /// Titre affiché en haut de la section.
  final String title;

  /// Options de la section.
  final List<ArenaFilterOption> options;

  /// Mode : radio (un seul choix actif) ou multi (multiple choix).
  final ArenaFilterMode mode;
}

class ArenaFilterOption {
  const ArenaFilterOption({required this.id, required this.label});
  final String id;
  final String label;
}

enum ArenaFilterMode { radio, multi }

class _ArenaFilterSheet extends StatefulWidget {
  const _ArenaFilterSheet({
    required this.sections,
    required this.initialSelection,
    required this.onApply,
  });

  final List<ArenaFilterSection> sections;
  final Map<String, List<String>> initialSelection;
  final ValueChanged<Map<String, List<String>>> onApply;

  @override
  State<_ArenaFilterSheet> createState() => _ArenaFilterSheetState();
}

class _ArenaFilterSheetState extends State<_ArenaFilterSheet> {
  late Map<String, Set<String>> _selection;

  @override
  void initState() {
    super.initState();
    _selection = {
      for (final s in widget.sections)
        s.id: <String>{...?widget.initialSelection[s.id]},
    };
  }

  void _toggle(ArenaFilterSection section, String optionId) {
    setState(() {
      final cur = _selection[section.id] ?? <String>{};
      if (section.mode == ArenaFilterMode.radio) {
        // toggle : tapper la même option la désactive
        if (cur.contains(optionId)) {
          _selection[section.id] = <String>{};
        } else {
          _selection[section.id] = <String>{optionId};
        }
      } else {
        if (cur.contains(optionId)) {
          cur.remove(optionId);
        } else {
          cur.add(optionId);
        }
        _selection[section.id] = cur;
      }
    });
  }

  void _reset() {
    setState(() {
      _selection = {for (final s in widget.sections) s.id: <String>{}};
    });
  }

  void _apply() {
    final snap = <String, List<String>>{
      for (final entry in _selection.entries) entry.key: entry.value.toList(),
    };
    widget.onApply(snap);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) => Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: ArenaColors.silverDim,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ArenaSpacing.lg,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text('Filtres', style: ArenaText.h3),
                ),
                TextButton(
                  onPressed: _reset,
                  child: Text(
                    'Tout réinitialiser',
                    style: ArenaText.small.copyWith(
                      color: ArenaColors.signalBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: ArenaSpacing.sm),
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.symmetric(
                horizontal: ArenaSpacing.lg,
              ),
              children: [
                for (final s in widget.sections) ...[
                  Text(s.title, style: ArenaText.inputLabel),
                  const SizedBox(height: ArenaSpacing.sm),
                  Wrap(
                    spacing: ArenaSpacing.xs,
                    runSpacing: ArenaSpacing.xs,
                    children: [
                      for (final o in s.options)
                        _OptionChip(
                          label: o.label,
                          active: _selection[s.id]?.contains(o.id) ?? false,
                          onTap: () => _toggle(s, o.id),
                        ),
                    ],
                  ),
                  const SizedBox(height: ArenaSpacing.md),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(ArenaSpacing.lg),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: ArenaColors.signalBlue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ArenaRadius.md),
                  ),
                ),
                onPressed: _apply,
                child: Text(
                  'APPLIQUER',
                  style: ArenaText.button.copyWith(color: ArenaColors.bone),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  const _OptionChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ArenaRadius.round),
      child: AnimatedContainer(
        duration: ArenaDurations.short,
        padding: const EdgeInsets.symmetric(
          horizontal: ArenaSpacing.md,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: active
              ? ArenaColors.signalBlue.withValues(alpha: 0.15)
              : ArenaColors.carbon,
          borderRadius: BorderRadius.circular(ArenaRadius.round),
          border: Border.all(
            color: active ? ArenaColors.signalBlue : ArenaColors.border,
          ),
        ),
        child: Text(
          label,
          style: ArenaText.body.copyWith(
            color: active ? ArenaColors.signalBlue : ArenaColors.silver,
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
