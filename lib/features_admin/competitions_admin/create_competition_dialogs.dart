part of 'create_competition_page.dart';

/// Petite popup qui demande le nom d'un modèle. StatefulWidget pour que le
/// `TextEditingController` soit créé et disposé selon le cycle de vie du
/// widget (et non à la complétion du `showDialog`, ce qui détruit le
/// controller alors que le `TextField` est encore monté → assertion
/// `_dependents.isEmpty`).
class _TemplateNameDialog extends StatefulWidget {
  const _TemplateNameDialog();

  @override
  State<_TemplateNameDialog> createState() => _TemplateNameDialogState();
}

class _TemplateNameDialogState extends State<_TemplateNameDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_ctrl.text);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ArenaColors.surface,
      title: Text('Nom du modèle', style: ArenaText.h3),
      content: ArenaTextField(
        controller: _ctrl,
        hint: 'Ex. Tournoi payant week-end',
        autofocus: true,
        textInputAction: TextInputAction.done,
        onChanged: (_) {},
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Annuler', style: ArenaText.body),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(
            'Enregistrer',
            style: ArenaText.h3.copyWith(color: ArenaColors.neonRed),
          ),
        ),
      ],
    );
  }
}

/// Bottom sheet de la bibliothèque de modèles : liste les modèles nommés,
/// chacun cliquable (insertion) avec une action de suppression. État local
/// (copie de la liste) pour se rafraîchir après suppression sans dépendre du
/// provider dans la route modale.
class _TemplateLibrarySheet extends StatefulWidget {
  const _TemplateLibrarySheet({
    required this.initial,
    required this.onInsert,
    required this.onDelete,
  });

  final List<DescriptionTemplate> initial;
  final ValueChanged<DescriptionTemplate> onInsert;
  final ValueChanged<DescriptionTemplate> onDelete;

  @override
  State<_TemplateLibrarySheet> createState() => _TemplateLibrarySheetState();
}

/// Bibliothèque GÉNÉRIQUE (nom + aperçu) — utilisée pour les modèles de
/// codes de paiement et de barème de récompenses. Mêmes ergonomie/visuel que
/// [_TemplateLibrarySheet] mais sans dépendre d'un type concret.
class _NamedTemplateSheet extends StatefulWidget {
  const _NamedTemplateSheet({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.onInsert,
    required this.onDelete,
  });

  final String title;
  final String subtitle;

  /// Couples (nom, aperçu) dans l'ordre d'affichage.
  final List<({String name, String preview})> items;
  final ValueChanged<int> onInsert;
  final ValueChanged<int> onDelete;

  @override
  State<_NamedTemplateSheet> createState() => _NamedTemplateSheetState();
}

class _NamedTemplateSheetState extends State<_NamedTemplateSheet> {
  late final List<({String name, String preview})> _items = [...widget.items];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(ArenaSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: ArenaText.h2),
            const SizedBox(height: ArenaSpacing.xs),
            Text(widget.subtitle, style: ArenaText.small),
            const SizedBox(height: ArenaSpacing.md),
            if (_items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: ArenaSpacing.lg),
                child: Text('Aucun modèle enregistré.', style: ArenaText.body),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _items.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: ArenaSpacing.xs),
                  itemBuilder: (_, i) {
                    final item = _items[i];
                    return Material(
                      color: ArenaColors.carbon,
                      borderRadius: BorderRadius.circular(ArenaRadius.md),
                      child: InkWell(
                        onTap: () => widget.onInsert(i),
                        borderRadius: BorderRadius.circular(ArenaRadius.md),
                        child: Padding(
                          padding: const EdgeInsets.all(ArenaSpacing.md),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.name, style: ArenaText.h3),
                                    const SizedBox(height: 2),
                                    Text(
                                      item.preview,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: ArenaText.small,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: ArenaColors.danger,
                                ),
                                tooltip: 'Supprimer',
                                onPressed: () {
                                  widget.onDelete(i);
                                  setState(() => _items.removeAt(i));
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TemplateLibrarySheetState extends State<_TemplateLibrarySheet> {
  late final List<DescriptionTemplate> _saved = [...widget.initial];

  @override
  Widget build(BuildContext context) {
    final saved = _saved;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(ArenaSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Mes modèles de description', style: ArenaText.h2),
            const SizedBox(height: ArenaSpacing.xs),
            Text(
              'Touche un modèle pour insérer son texte dans la description.',
              style: ArenaText.small,
            ),
            const SizedBox(height: ArenaSpacing.md),
            if (saved.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: ArenaSpacing.lg),
                child: Text('Aucun modèle enregistré.', style: ArenaText.body),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: saved.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: ArenaSpacing.xs),
                  itemBuilder: (_, i) {
                    final tpl = saved[i];
                    final preview = tpl.text.replaceAll('\n', ' ').trim();
                    return Material(
                      color: ArenaColors.carbon,
                      borderRadius: BorderRadius.circular(ArenaRadius.md),
                      child: InkWell(
                        onTap: () => widget.onInsert(tpl),
                        borderRadius: BorderRadius.circular(ArenaRadius.md),
                        child: Padding(
                          padding: const EdgeInsets.all(ArenaSpacing.md),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(tpl.name, style: ArenaText.h3),
                                    const SizedBox(height: 2),
                                    Text(
                                      preview,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: ArenaText.small,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: ArenaColors.danger,
                                ),
                                tooltip: 'Supprimer',
                                onPressed: () {
                                  widget.onDelete(tpl);
                                  setState(() => _saved.removeAt(i));
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
