part of 'desktop_create_competition_page.dart';

// ─────────────────────────────────────────────────────────────────────
// Construction des étapes du wizard.
//
// Mixin appliqué à [_DesktopCreateCompetitionPageState] : il accède aux
// champs/controllers privés du State via des membres abstraits que le
// State implémente (ses propres champs annotés `@override`). Extrait pour
// alléger le god file — aucun changement de comportement.
// ─────────────────────────────────────────────────────────────────────

mixin _StepBuilders on ConsumerState<DesktopCreateCompetitionPage> {
  // Membres fournis par le State hôte.
  bool get _isEditing;
  GameType get _game;
  set _game(GameType value);
  TournamentFormat get _format;
  set _format(TournamentFormat value);
  int get _maxPlayers;
  set _maxPlayers(int value);
  DateTime? get _startDate;
  set _startDate(DateTime? value);
  String get _currency;
  set _currency(String value);
  int get _rewardedCount;
  set _rewardedCount(int value);
  bool get _publishNow;
  set _publishNow(bool value);
  bool get _autoGenerateBracket;
  set _autoGenerateBracket(bool value);
  int get _matchIntervalMinutes;
  set _matchIntervalMinutes(int value);
  bool get _thirdPlaceMatch;
  set _thirdPlaceMatch(bool value);

  TextEditingController get _nameCtrl;
  TextEditingController get _descCtrl;
  TextEditingController get _entryFeeCtrl;
  TextEditingController get _orangeMomoCtrl;
  TextEditingController get _mtnMomoCtrl;
  TextEditingController get _commissionXafCtrl;
  List<TextEditingController> get _topShareCtrls;
  List<TextEditingController> get _blockShareCtrls;
  TextEditingController get _referralQuotaCtrl;
  TextEditingController get _roundIntervalsCtrl;
  TextEditingController get _groupCountCtrl;
  TextEditingController get _qualifiersPerGroupCtrl;
  TextEditingController get _androidStoreUrlCtrl;
  TextEditingController get _iosStoreUrlCtrl;

  // Fournis par le mixin de logique (_SubmitAndCompute).
  int _shareTotal();
  double _computedPool();
  double _commissionXaf();
  int _referralQuota();

  /// Grise + désactive un champ verrouillé en mode édition.
  Widget _lockable(Widget child) {
    if (!_isEditing) return child;
    return IgnorePointer(child: Opacity(opacity: 0.45, child: child));
  }

  // ─── Modèles de description (parité avec le wizard mobile #178/#180) ──

  /// Insère le pitch standard du jeu courant dans la description.
  void _insertStandardDesc() {
    setState(() {
      _descCtrl.text = kDefaultDescriptionTemplates[_game] ?? '';
    });
  }

  /// Enregistre la description courante comme modèle nommé réutilisable.
  Future<void> _saveDescTemplate() async {
    final text = _descCtrl.text.trim();
    if (text.isEmpty) return;
    final nameCtrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => ContentDialog(
        title: const Text('Enregistrer le modèle'),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: TextBox(
            controller: nameCtrl,
            placeholder: 'Nom du modèle (ex. Tournoi du week-end)',
          ),
        ),
        actions: [
          Button(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(nameCtrl.text.trim()),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    nameCtrl.dispose();
    if (name == null || name.isEmpty) return;
    await ref
        .read(competitionDescTemplatesProvider.notifier)
        .saveTemplate(name, text);
  }

  /// Ouvre la bibliothèque de modèles nommés : insérer ou supprimer.
  Future<void> _openTemplateLibrary() async {
    final lib = ref.read(competitionDescTemplatesProvider).valueOrNull;
    if (lib == null || lib.saved.isEmpty) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => ContentDialog(
        title: const Text('Mes modèles'),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final tpl in lib.saved)
                ListTile(
                  title: Text(tpl.name),
                  subtitle: Text(
                    tpl.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onPressed: () {
                    setState(() => _descCtrl.text = tpl.text);
                    Navigator.of(ctx).pop();
                  },
                  trailing: IconButton(
                    icon: const Icon(FluentIcons.delete),
                    onPressed: () {
                      ref
                          .read(competitionDescTemplatesProvider.notifier)
                          .deleteTemplate(tpl.name);
                      Navigator.of(ctx).pop();
                    },
                  ),
                ),
            ],
          ),
        ),
        actions: [
          Button(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  // ─── Étape 0 — Infos ────────────────────────────────────────────────

  Widget _buildInfosStep() {
    final savedCount =
        ref.watch(competitionDescTemplatesProvider).valueOrNull?.saved.length ??
            0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle('Informations générales'),
        InfoLabel(
          label: 'Nom de la compétition',
          child: TextBox(
            controller: _nameCtrl,
            placeholder: 'Cameroon eFootball Cup',
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 16),
        InfoLabel(
          label: 'Jeu',
          child: _lockable(
            ComboBox<GameType>(
              value: _game,
              isExpanded: true,
              items: [
                for (final g in GameType.values)
                  ComboBoxItem<GameType>(value: g, child: Text(g.label)),
              ],
              onChanged: (v) => setState(() {
                final ng = v ?? _game;
                // Pré-remplit le pitch standard du nouveau jeu si le champ est
                // vide OU contient encore le pitch standard du jeu précédent
                // (ne jamais écraser un texte personnalisé).
                final prevStd =
                    (kDefaultDescriptionTemplates[_game] ?? '').trim();
                if (ng != _game &&
                    (_descCtrl.text.trim().isEmpty ||
                        _descCtrl.text.trim() == prevStd)) {
                  _descCtrl.text = kDefaultDescriptionTemplates[ng] ?? '';
                }
                _game = ng;
              }),
            ),
          ),
        ),
        const SizedBox(height: 16),
        InfoLabel(
          label: 'Description (optionnel)',
          child: TextBox(
            controller: _descCtrl,
            placeholder: 'Petite phrase de pitch…',
            maxLines: 4,
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Button(
                onPressed: _insertStandardDesc,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(FluentIcons.lightbulb, size: 14),
                    SizedBox(width: 6),
                    Text('Modèle standard'),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Button(
                onPressed: _saveDescTemplate,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(FluentIcons.add_bookmark, size: 14),
                    SizedBox(width: 6),
                    Text('Enregistrer'),
                  ],
                ),
              ),
            ),
            if (savedCount > 0) ...[
              const SizedBox(width: 8),
              Expanded(
                child: Button(
                  onPressed: _openTemplateLibrary,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(FluentIcons.library, size: 14),
                      const SizedBox(width: 6),
                      Text('Mes modèles ($savedCount)'),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Insère le pitch standard de ${_game.label} (modifiable), ou '
          'enregistre le texte actuel comme modèle nommé pour le réutiliser.',
          style: const TextStyle(fontSize: 12, color: ArenaColors.silver),
        ),
        const SizedBox(height: 16),
        InfoLabel(
          label: 'Date de début',
          child: Row(
            children: [
              Expanded(
                child: DatePicker(
                  selected: _startDate,
                  onChanged: _onDateChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TimePicker(
                  selected: _startDate,
                  onChanged: _onTimeChanged,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const _SectionTitle('Liens stores du jeu (optionnel)'),
        InfoLabel(
          label: 'Play Store (Android)',
          child: TextBox(
            controller: _androidStoreUrlCtrl,
            placeholder: 'https://play.google.com/store/apps/details?id=…',
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 16),
        InfoLabel(
          label: 'App Store (iOS)',
          child: TextBox(
            controller: _iosStoreUrlCtrl,
            placeholder: 'https://apps.apple.com/app/id…',
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );
  }

  void _onDateChanged(DateTime date) {
    final prev = _startDate ?? DateTime.now();
    setState(() {
      _startDate =
          DateTime(date.year, date.month, date.day, prev.hour, prev.minute);
    });
  }

  void _onTimeChanged(DateTime time) {
    final prev = _startDate ?? DateTime.now();
    setState(() {
      _startDate =
          DateTime(prev.year, prev.month, prev.day, time.hour, time.minute);
    });
  }

  // ─── Étape 1 — Format ───────────────────────────────────────────────

  Widget _buildFormatStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle('Format et capacité'),
        if (_isEditing) ...[
          const InfoBar(
            title: Text('Champs verrouillés'),
            content: Text(
              'Format et capacité ne sont pas modifiables après création — '
              'ils conditionnent le bracket déjà calculé.',
            ),
            severity: InfoBarSeverity.info,
            isLong: true,
          ),
          const SizedBox(height: 16),
        ],
        InfoLabel(
          label: 'Format du tournoi',
          child: _lockable(
            ComboBox<TournamentFormat>(
              value: _format,
              isExpanded: true,
              items: [
                for (final f in TournamentFormat.values)
                  ComboBoxItem<TournamentFormat>(
                    value: f,
                    child: Text(competitionFormatLabel(f)),
                  ),
              ],
              onChanged: (v) => setState(() => _format = v ?? _format),
            ),
          ),
        ),
        const SizedBox(height: 16),
        InfoLabel(
          label: 'Nombre de joueurs max',
          child: _lockable(
            ComboBox<int>(
              value: _maxPlayers,
              isExpanded: true,
              items: [
                for (final n in _maxPlayersOptions)
                  ComboBoxItem<int>(value: n, child: Text('$n joueurs')),
              ],
              onChanged: (v) => setState(() => _maxPlayers = v ?? _maxPlayers),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const _SectionTitle('Gestion automatique'),
        Row(
          children: [
            ToggleSwitch(
              checked: _autoGenerateBracket,
              onChanged: (v) => setState(() => _autoGenerateBracket = v),
              content: const Text('Bracket auto au quota atteint'),
            ),
          ],
        ),
        if (_format != TournamentFormat.roundRobin) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              ToggleSwitch(
                checked: _thirdPlaceMatch,
                onChanged: (v) => setState(() => _thirdPlaceMatch = v),
                content: const Text(
                  'Match de classement (3e place) — petite finale',
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        InfoLabel(
          label: 'Intervalle entre rounds (défaut)',
          child: ComboBox<int>(
            value: _matchIntervalMinutes,
            isExpanded: true,
            items: [
              for (final m in _intervalOptions)
                ComboBoxItem<int>(value: m, child: Text(_intervalLabel(m))),
            ],
            onChanged: (v) =>
                setState(() => _matchIntervalMinutes = v ?? _matchIntervalMinutes),
          ),
        ),
        const SizedBox(height: 16),
        InfoLabel(
          label: 'Intervalles personnalisés par round (optionnel)',
          child: TextBox(
            controller: _roundIntervalsCtrl,
            placeholder: 'Ex. 30,60,120,1440 (vide = défaut)',
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[0-9, ]')),
            ],
            onChanged: (_) => setState(() {}),
          ),
        ),
        if (_format == TournamentFormat.groupsThenKnockout) ...[
          const SizedBox(height: 24),
          const _SectionTitle('Configuration des poules'),
          Row(
            children: [
              Expanded(
                child: InfoLabel(
                  label: 'Nombre de poules',
                  child: TextBox(
                    controller: _groupCountCtrl,
                    placeholder: '4',
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InfoLabel(
                  label: 'Qualifiés par poule',
                  child: TextBox(
                    controller: _qualifiersPerGroupCtrl,
                    placeholder: '2',
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ─── Étape 2 — Récompenses ──────────────────────────────────────────

  Widget _buildPrizesStep() {
    final topCount = _rewardedCount < 4 ? _rewardedCount : 4;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle('Répartition des récompenses'),
        InfoBar(
          title: Text('Montants en $_currency'),
          content: Text(
            'Saisissez le montant attribué à chaque place — en $_currency. '
            'La cagnotte est la somme de ces montants.',
          ),
          severity: InfoBarSeverity.info,
          isLong: true,
        ),
        const SizedBox(height: 16),
        InfoLabel(
          label: 'Nombre de récompensés',
          child: ComboBox<int>(
            value: _rewardedCount,
            isExpanded: true,
            items: [
              for (final n in kRewardedRankOptions)
                ComboBoxItem<int>(value: n, child: Text('$n place(s)')),
            ],
            onChanged: (v) => setState(
              () => _rewardedCount = (v ?? _rewardedCount).clamp(
                1,
                kMaxRewardedRanks,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < topCount; i++) ...[
          InfoLabel(
            label: '${prizeRankEmoji(i)} ${prizeRankLabel(i)} place',
            child: _amountBox(_topShareCtrls[i], 'Montant'),
          ),
          const SizedBox(height: 12),
        ],
        for (var b = 0; b < _prizeBlocks.length; b++)
          if (_rewardedCount >= _prizeBlocks[b].lastRank) ...[
            InfoLabel(
              label: '🏅 ${_prizeBlocks[b].label} — par place',
              child: _amountBox(_blockShareCtrls[b], 'Montant par place'),
            ),
            const SizedBox(height: 12),
          ],
        const SizedBox(height: 8),
        Card(
          backgroundColor: ArenaColors.statusOk.withValues(alpha: 0.08),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Cagnotte totale',
                  style: GoogleFonts.spaceGrotesk(
                    color: ArenaColors.bone,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${NumberFormat('#,###', 'fr').format(_shareTotal())} '
                '$_currency',
                style: GoogleFonts.jetBrainsMono(
                  color: ArenaColors.statusOk,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _amountBox(TextEditingController ctrl, String placeholder) {
    return TextBox(
      controller: ctrl,
      placeholder: placeholder,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp('[0-9]')),
        LengthLimitingTextInputFormatter(9),
      ],
      onChanged: (_) => setState(() {}),
    );
  }

  // ─── Étape 3 — Frais ────────────────────────────────────────────────

  Widget _buildFeesStep() {
    final fee = double.tryParse(_entryFeeCtrl.text) ?? 0;
    final isPaid = fee > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle("Frais d'inscription"),
        const InfoBar(
          title: Text('Compétition gratuite ou payante'),
          content: Text(
            'Frais = 0 → compétition GRATUITE (bypass paiement). Sinon le '
            'joueur paie en P2P sur les codes marchands, validés '
            'manuellement par le super-admin.',
          ),
          severity: InfoBarSeverity.info,
          isLong: true,
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              flex: 2,
              child: InfoLabel(
                label: "Frais d'inscription",
                child: _lockable(
                  TextBox(
                    controller: _entryFeeCtrl,
                    placeholder: '0',
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp('[0-9.]')),
                    ],
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InfoLabel(
                label: 'Devise',
                child: _lockable(
                  ComboBox<String>(
                    value: _currency,
                    isExpanded: true,
                    items: [
                      for (final c in _currencies)
                        ComboBoxItem<String>(value: c, child: Text(c)),
                    ],
                    onChanged: (v) =>
                        setState(() => _currency = v ?? _currency),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        InfoLabel(
          label: 'Commission ARENA ($_currency, jamais affichée au joueur)',
          child: TextBox(
            controller: _commissionXafCtrl,
            placeholder: '0',
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[0-9.]')),
            ],
            onChanged: (_) => setState(() {}),
          ),
        ),
        if (!isPaid) ...[
          const SizedBox(height: 24),
          const _SectionTitle('Parrainage requis (optionnel)'),
          InfoLabel(
            label: 'Nombre de parrainages requis avant inscription',
            child: TextBox(
              controller: _referralQuotaCtrl,
              placeholder: '0',
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
        if (isPaid) ...[
          const SizedBox(height: 24),
          const _SectionTitle('Codes marchands (requis)'),
          InfoLabel(
            label: 'Code marchand Orange Money',
            child: TextBox(
              controller: _orangeMomoCtrl,
              placeholder: 'ex. *126*1*001234#',
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 16),
          InfoLabel(
            label: 'Code marchand MTN MoMo',
            child: TextBox(
              controller: _mtnMomoCtrl,
              placeholder: 'ex. *126*7*009876#',
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
      ],
    );
  }

  // ─── Étape 4 — Récap ────────────────────────────────────────────────

  Widget _buildReviewStep() {
    final fee = double.tryParse(_entryFeeCtrl.text) ?? 0;
    final pool = _computedPool();
    final fmt = NumberFormat('#,###', 'fr');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle('Récapitulatif'),
        Card(
          backgroundColor: ArenaColors.carbon,
          child: Column(
            children: [
              _ReviewRow(label: 'Nom', value: _nameCtrl.text.trim()),
              _ReviewRow(label: 'Jeu', value: _game.label),
              _ReviewRow(
                label: 'Format',
                value: competitionFormatLabel(_format),
              ),
              _ReviewRow(label: 'Joueurs', value: '$_maxPlayers max'),
              _ReviewRow(
                label: 'Date',
                value: _startDate == null
                    ? '—'
                    : DateFormat('dd/MM/yyyy HH:mm', 'fr')
                        .format(_startDate!),
              ),
              _ReviewRow(
                label: 'Inscription',
                value: fee == 0
                    ? 'Gratuit'
                    : '${fmt.format(fee.round())} $_currency',
              ),
              _ReviewRow(
                label: 'Cagnotte',
                value: '${fmt.format(pool.round())} $_currency',
              ),
              _ReviewRow(
                label: 'Commission ARENA',
                value: '${fmt.format(_commissionXaf().round())} $_currency',
              ),
              _ReviewRow(
                label: 'Bracket auto',
                value: _autoGenerateBracket ? 'Oui' : 'Non — manuel',
              ),
              _ReviewRow(
                label: 'Intervalle rounds',
                value: _intervalLabel(_matchIntervalMinutes),
              ),
              if (_format != TournamentFormat.roundRobin)
                _ReviewRow(
                  label: 'Match 3e place',
                  value: _thirdPlaceMatch ? 'Oui' : 'Non',
                ),
              if (_referralQuota() > 0)
                _ReviewRow(
                  label: 'Parrainages requis',
                  value: '${_referralQuota()} ami(s)',
                ),
            ],
          ),
        ),
        if (!_isEditing) ...[
          const SizedBox(height: 16),
          ToggleSwitch(
            checked: _publishNow,
            onChanged: (v) => setState(() => _publishNow = v),
            content: Text(
              _publishNow
                  ? 'Publier maintenant — inscriptions ouvertes'
                  : 'Sauver en brouillon — invisible côté joueur',
            ),
          ),
        ],
      ],
    );
  }
}
