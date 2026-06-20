import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/features_admin/competitions_admin/widgets/competition_form_widgets.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Étape 1 du wizard — infos générales : nom, jeu, description, date de
/// début et liens stores (optionnels).
class WizardStepInfos extends StatelessWidget {
  const WizardStepInfos({
    required this.nameCtrl,
    required this.descCtrl,
    required this.androidStoreUrlCtrl,
    required this.iosStoreUrlCtrl,
    required this.game,
    required this.startDate,
    required this.isEditing,
    required this.onChanged,
    required this.onGameChanged,
    required this.onPickStartDate,
    required this.onInsertStandard,
    required this.onSaveTemplate,
    required this.onOpenLibrary,
    required this.savedCount,
    super.key,
  });

  final TextEditingController nameCtrl;
  final TextEditingController descCtrl;
  final TextEditingController androidStoreUrlCtrl;
  final TextEditingController iosStoreUrlCtrl;
  final GameType game;
  final DateTime? startDate;
  final bool isEditing;
  final VoidCallback onChanged;
  final ValueChanged<GameType> onGameChanged;
  final VoidCallback onPickStartDate;

  /// Insère le pitch standard du jeu courant dans la description.
  final VoidCallback onInsertStandard;

  /// Enregistre la description courante comme nouveau modèle nommé
  /// (demande un nom).
  final VoidCallback onSaveTemplate;

  /// Ouvre la bibliothèque de modèles enregistrés (choisir / supprimer).
  final VoidCallback onOpenLibrary;

  /// Nombre de modèles nommés dans la bibliothèque.
  final int savedCount;

  /// En mode édition, grise et désactive un champ verrouillé (ici le jeu).
  Widget _lockable(Widget child) {
    if (!isEditing) return child;
    return IgnorePointer(
      child: Opacity(opacity: 0.45, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Nom de la compétition', style: ArenaText.inputLabel),
        const SizedBox(height: ArenaSpacing.xs),
        ArenaTextField(
          controller: nameCtrl,
          hint: 'Cameroon eFootball Cup',
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: ArenaSpacing.md),
        Text('Jeu', style: ArenaText.inputLabel),
        const SizedBox(height: ArenaSpacing.xs),
        _lockable(
          GamePicker(
            current: game,
            onChanged: onGameChanged,
          ),
        ),
        const SizedBox(height: ArenaSpacing.md),
        Text('Description (optionnel)', style: ArenaText.inputLabel),
        const SizedBox(height: ArenaSpacing.xs),
        ArenaTextField(
          controller: descCtrl,
          hint: 'Petite phrase de pitch…',
          minLines: 2,
          maxLines: 6,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: ArenaSpacing.xs),
        Row(
          children: [
            Expanded(
              child: ArenaButton(
                label: 'MODÈLE STANDARD',
                variant: ArenaButtonVariant.ghost,
                icon: Icons.auto_awesome,
                fullWidth: true,
                onPressed: onInsertStandard,
              ),
            ),
            const SizedBox(width: ArenaSpacing.xs),
            Expanded(
              child: ArenaButton(
                label: 'ENREGISTRER',
                variant: ArenaButtonVariant.secondary,
                icon: Icons.bookmark_add_outlined,
                fullWidth: true,
                onPressed: onSaveTemplate,
              ),
            ),
          ],
        ),
        if (savedCount > 0) ...[
          const SizedBox(height: ArenaSpacing.xs),
          ArenaButton(
            label: 'MES MODÈLES ($savedCount)',
            variant: ArenaButtonVariant.secondary,
            icon: Icons.bookmarks_outlined,
            fullWidth: true,
            onPressed: onOpenLibrary,
          ),
        ],
        Padding(
          padding: const EdgeInsets.only(top: ArenaSpacing.xs),
          child: Text(
            savedCount > 0
                ? 'Insère le pitch standard de ${game.label}, ouvre ta '
                    'bibliothèque ($savedCount modèle'
                    '${savedCount > 1 ? 's' : ''}), ou enregistre le texte '
                    'actuel comme nouveau modèle nommé.'
                : 'Insère le pitch standard de ${game.label} (modifiable), '
                    'ou enregistre le texte actuel comme modèle nommé pour le '
                    'réutiliser à chaque fois.',
            style: ArenaText.small,
          ),
        ),
        const SizedBox(height: ArenaSpacing.md),
        Text('Date de début', style: ArenaText.inputLabel),
        const SizedBox(height: ArenaSpacing.xs),
        InkWell(
          onTap: onPickStartDate,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: ArenaSpacing.md,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: ArenaColors.carbon,
              borderRadius: BorderRadius.circular(ArenaRadius.md),
              border: Border.all(color: ArenaColors.border),
            ),
            child: Text(
              startDate == null
                  ? 'Choisir une date'
                  : DateFormat('EEEE dd/MM/yyyy HH:mm', 'fr_FR')
                      .format(startDate!),
              style: ArenaText.body,
            ),
          ),
        ),
        const SizedBox(height: ArenaSpacing.lg),
        Text('Liens stores du jeu (optionnel)', style: ArenaText.h3),
        const SizedBox(height: ArenaSpacing.xs),
        Text(
          "Le joueur verra 2 boutons sur la page d'inscription pour "
          'télécharger le jeu. Laisse vide pour ne pas afficher.',
          style: ArenaText.small,
        ),
        const SizedBox(height: ArenaSpacing.sm),
        Text('Play Store (Android)', style: ArenaText.inputLabel),
        const SizedBox(height: ArenaSpacing.xs),
        ArenaTextField(
          controller: androidStoreUrlCtrl,
          hint: 'https://play.google.com/store/apps/details?id=…',
          keyboardType: TextInputType.url,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: ArenaSpacing.sm),
        Text('App Store (iOS)', style: ArenaText.inputLabel),
        const SizedBox(height: ArenaSpacing.xs),
        ArenaTextField(
          controller: iosStoreUrlCtrl,
          hint: 'https://apps.apple.com/app/id…',
          keyboardType: TextInputType.url,
          onChanged: (_) => onChanged(),
        ),
      ],
    );
  }
}
