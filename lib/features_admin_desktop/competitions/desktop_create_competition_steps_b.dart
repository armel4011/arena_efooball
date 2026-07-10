part of 'desktop_create_competition_page.dart';

// Suite des étapes du wizard (récompenses, frais, pays, review), extraite de
// desktop_create_competition_steps.dart pour repasser sous le seuil god-file
// (1047 l). Mixin `on _StepBuilders` → accès aux membres abstraits du State et
// aux helpers partagés (_lockable). Aucun changement de comportement.

mixin _StepBuildersB
    on ConsumerState<DesktopCreateCompetitionPage>, _StepBuilders {
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
        for (var b = 0; b < prizeBlocks.length; b++)
          if (_rewardedCount >= prizeBlocks[b].lastRank) ...[
            InfoLabel(
              label: '🏅 ${prizeBlocks[b].label} — par place',
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
            'joueur paie en P2P : les codes marchands par pays/opérateur se '
            "configurent à l'étape « Pays ».",
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
          const SizedBox(height: 16),
          const InfoBar(
            title: Text('Codes marchands déplacés'),
            content: Text(
              'Les codes de transfert par pays et opérateur se configurent '
              "désormais à l'étape « Pays ».",
            ),
            severity: InfoBarSeverity.warning,
            isLong: true,
          ),
        ],
      ],
    );
  }

  // ─── Étape 4 — Pays + options de paiement ───────────────────────────

  Widget _buildCountryStep() {
    final isPaid = (double.tryParse(_entryFeeCtrl.text) ?? 0) > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle('Pays organisateur'),
        InfoLabel(
          label: 'Pays organisateur (périmètre admin)',
          child: ComboBox<String>(
            value: _countryCode,
            isExpanded: true,
            items: [
              for (final c in kSupportedCountries)
                ComboBoxItem<String>(
                  value: c.code,
                  child: Text('${c.flag}  ${c.name}'),
                ),
            ],
            onChanged: (v) => setState(() => _countryCode = v ?? _countryCode),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          "Sert au scoping admin par pays. N'affecte pas les pays autorisés "
          'au paiement ci-dessous.',
          style: TextStyle(fontSize: 12, color: ArenaColors.silver),
        ),
        const SizedBox(height: 24),
        if (!isPaid)
          const InfoBar(
            title: Text('Compétition gratuite'),
            content: Text(
              'Aucune configuration de paiement nécessaire. Seul le pays '
              'organisateur est requis.',
            ),
            severity: InfoBarSeverity.info,
            isLong: true,
          )
        else if (_paymentOptionsLoading)
          const Center(child: ProgressRing())
        else
          _buildPaymentEditor(),
      ],
    );
  }

  Widget _buildPaymentEditor() {
    final templateCount =
        ref.watch(paymentOperatorTemplatesProvider).valueOrNull?.saved.length ??
            0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle('Options de paiement par pays'),
        const InfoBar(
          title: Text('Opérateurs libres par pays'),
          content: Text(
            'Pour chaque pays autorisé, ajoute un ou plusieurs opérateurs '
            '(Orange Money, MTN MoMo, Wave…) avec leur code de transfert. Le '
            'joueur choisit son pays puis un opérateur au moment de payer.',
          ),
          severity: InfoBarSeverity.info,
          isLong: true,
        ),
        const SizedBox(height: 16),
        for (var ci = 0; ci < _paymentCountries.length; ci++) ...[
          _buildCountryCard(ci, templateCount),
          const SizedBox(height: 12),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: Button(
            onPressed: _addPaymentCountry,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(FluentIcons.add, size: 14),
                SizedBox(width: 6),
                Text('Ajouter un pays'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCountryCard(int ci, int templateCount) {
    final country = _paymentCountries[ci];
    return Card(
      backgroundColor: ArenaColors.carbon,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: ComboBox<String>(
                  value: country.countryCode,
                  isExpanded: true,
                  items: [
                    for (final c in kSupportedCountries)
                      ComboBoxItem<String>(
                        value: c.code,
                        child: Text('${c.flag}  ${c.name}'),
                      ),
                  ],
                  onChanged: (v) => setState(
                    () => country.countryCode = v ?? country.countryCode,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon:
                    const Icon(FluentIcons.delete, color: ArenaColors.neonRed),
                onPressed: () => setState(
                  () => _paymentCountries.removeAt(ci).dispose(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var oi = 0; oi < country.operators.length; oi++) ...[
            _buildOperatorRow(ci, oi),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Button(
                onPressed: () => setState(
                  () => country.operators.add(PaymentDraftOperator()),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(FluentIcons.add, size: 14),
                    SizedBox(width: 6),
                    Text('Opérateur'),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Button(
                onPressed:
                    templateCount > 0 ? () => _openOperatorTemplates(ci) : null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(FluentIcons.library, size: 14),
                    const SizedBox(width: 6),
                    Text('Mes opérateurs ($templateCount)'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOperatorRow(int ci, int oi) {
    final country = _paymentCountries[ci];
    final op = country.operators[oi];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: InfoLabel(
            label: "Nom de l'opérateur",
            child: TextBox(
              controller: op.labelCtrl,
              placeholder: 'ex. Orange Money',
              onChanged: (_) => setState(() {}),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: InfoLabel(
            label: 'Code de transfert',
            child: TextBox(
              controller: op.codeCtrl,
              placeholder: 'ex. *126*1*001234#',
              onChanged: (_) => setState(() {}),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: InfoLabel(
            label: 'Numéro à payer (CEMAC)',
            child: TextBox(
              controller: op.numberCtrl,
              placeholder: 'optionnel',
              onChanged: (_) => setState(() {}),
            ),
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(FluentIcons.save, size: 16),
          onPressed: () => _savePaymentOperatorTemplate(ci, oi),
        ),
        if (country.operators.length > 1)
          IconButton(
            icon: const Icon(FluentIcons.cancel, color: ArenaColors.neonRed),
            onPressed: () => setState(
              () => country.operators.removeAt(oi).dispose(),
            ),
          ),
      ],
    );
  }

  void _addPaymentCountry() {
    setState(() {
      _paymentCountries.add(
        PaymentDraftCountry(countryCode: firstUnusedCountry(_paymentCountries)),
      );
    });
  }

  Future<void> _savePaymentOperatorTemplate(int ci, int oi) async {
    final country = _paymentCountries[ci];
    final op = country.operators[oi];
    final label = op.labelCtrl.text.trim();
    final code = op.codeCtrl.text.trim();
    if (label.isEmpty || code.isEmpty) return;
    await ref.read(paymentOperatorTemplatesProvider.notifier).saveTemplate(
          PaymentOperatorTemplate(
            countryCode: country.countryCode,
            operatorLabel: label,
            transferCode: code,
          ),
        );
  }

  Future<void> _openOperatorTemplates(int ci) async {
    final saved =
        ref.read(paymentOperatorTemplatesProvider).valueOrNull?.saved ??
            const [];
    if (saved.isEmpty) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => ContentDialog(
        title: const Text('Mes opérateurs'),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final tpl in saved)
                ListTile(
                  title: Text(tpl.operatorLabel),
                  subtitle: Text('${tpl.countryCode} · ${tpl.transferCode}'),
                  onPressed: () {
                    setState(
                      () => _paymentCountries[ci].operators.add(
                            PaymentDraftOperator(
                              label: tpl.operatorLabel,
                              code: tpl.transferCode,
                            ),
                          ),
                    );
                    Navigator.of(ctx).pop();
                  },
                  trailing: IconButton(
                    icon: const Icon(FluentIcons.delete),
                    onPressed: () {
                      ref
                          .read(paymentOperatorTemplatesProvider.notifier)
                          .deleteTemplate(tpl);
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

  // ─── Étape 5 — Récap ────────────────────────────────────────────────

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
                    : DateFormat('dd/MM/yyyy HH:mm', 'fr').format(_startDate!),
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
