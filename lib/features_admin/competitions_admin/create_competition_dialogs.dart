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

/// Bottom sheet de la bibliothèque de configs de récompense : chaque entrée est
/// cliquable (applique la config aux controllers du wizard) avec suppression.
class _RewardLibrarySheet extends StatefulWidget {
  const _RewardLibrarySheet({
    required this.initial,
    required this.currency,
    required this.onApply,
    required this.onDelete,
  });

  final List<RewardConfigTemplate> initial;
  final String currency;
  final ValueChanged<RewardConfigTemplate> onApply;
  final ValueChanged<RewardConfigTemplate> onDelete;

  @override
  State<_RewardLibrarySheet> createState() => _RewardLibrarySheetState();
}

class _RewardLibrarySheetState extends State<_RewardLibrarySheet> {
  late final List<RewardConfigTemplate> _saved = [...widget.initial];
  static final List<int> _blockSizes = [for (final b in prizeBlocks) b.size];

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
            Text('Mes configs de récompense', style: ArenaText.h2),
            const SizedBox(height: ArenaSpacing.xs),
            Text(
              'Touche une config pour appliquer sa répartition à cette '
              'compétition.',
              style: ArenaText.small,
            ),
            const SizedBox(height: ArenaSpacing.md),
            if (saved.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: ArenaSpacing.lg),
                child: Text('Aucune config enregistrée.', style: ArenaText.body),
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
                    final subtitle = '${tpl.rewardedCount} récompensé'
                        '${tpl.rewardedCount > 1 ? 's' : ''} · '
                        'cagnotte ${tpl.totalShares(_blockSizes)} '
                        '${widget.currency}';
                    return Material(
                      color: ArenaColors.carbon,
                      borderRadius: BorderRadius.circular(ArenaRadius.md),
                      child: InkWell(
                        onTap: () => widget.onApply(tpl),
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
                                    Text(subtitle, style: ArenaText.small),
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

/// Bottom sheet de la bibliothèque de jeux de codes marchands : chaque entrée
/// applique la paire Orange/MTN aux controllers du wizard, avec suppression.
class _PaymentCodeLibrarySheet extends StatefulWidget {
  const _PaymentCodeLibrarySheet({
    required this.initial,
    required this.onApply,
    required this.onDelete,
  });

  final List<PaymentCodeTemplate> initial;
  final ValueChanged<PaymentCodeTemplate> onApply;
  final ValueChanged<PaymentCodeTemplate> onDelete;

  @override
  State<_PaymentCodeLibrarySheet> createState() =>
      _PaymentCodeLibrarySheetState();
}

class _PaymentCodeLibrarySheetState extends State<_PaymentCodeLibrarySheet> {
  late final List<PaymentCodeTemplate> _saved = [...widget.initial];

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
            Text('Mes codes marchands', style: ArenaText.h2),
            const SizedBox(height: ArenaSpacing.xs),
            Text(
              'Touche un jeu de codes pour remplir Orange Money + MTN MoMo.',
              style: ArenaText.small,
            ),
            const SizedBox(height: ArenaSpacing.md),
            if (saved.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: ArenaSpacing.lg),
                child: Text('Aucun code enregistré.', style: ArenaText.body),
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
                    final subtitle = [
                      if (tpl.orangeCode.isNotEmpty) 'Orange ${tpl.orangeCode}',
                      if (tpl.mtnCode.isNotEmpty) 'MTN ${tpl.mtnCode}',
                    ].join(' · ');
                    return Material(
                      color: ArenaColors.carbon,
                      borderRadius: BorderRadius.circular(ArenaRadius.md),
                      child: InkWell(
                        onTap: () => widget.onApply(tpl),
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
                                      subtitle,
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
