part of 'desktop_create_competition_page.dart';

// ─────────────────────────────────────────────────────────────────────
// Soumission et calculs du wizard (identiques au wizard mobile).
//
// Mixin appliqué à [_DesktopCreateCompetitionPageState] : il accède aux
// champs/controllers privés du State via des membres abstraits que le
// State implémente. Fournit aussi `_lockable` + calculs requis par
// _StepBuilders. Aucun changement de comportement.
// ─────────────────────────────────────────────────────────────────────

/// Formatter décimal : chiffres avec AU PLUS un point (rejette « 1.2.3 »).
final _singleDecimalFormatter = TextInputFormatter.withFunction((old, neu) {
  if (neu.text.isEmpty) return neu;
  return RegExp(r'^\d*\.?\d*$').hasMatch(neu.text) ? neu : old;
});

/// Libellé lisible d'un intervalle en minutes (min / h / jours).
String _intervalLabel(int minutes) {
  if (minutes < 60) return '$minutes min';
  if (minutes < 1440) return '${minutes ~/ 60} h';
  final d = minutes ~/ 1440;
  return d == 1 ? '1 jour' : '$d jours';
}

mixin _SubmitAndCompute on ConsumerState<DesktopCreateCompetitionPage> {
  // Membres fournis par le State hôte.
  bool get _isEditing;
  bool get _submitting;
  set _submitting(bool value);
  set _error(String? value);
  String? get _createdId;
  set _createdId(String? value);
  bool get _noReward;
  GameType get _game;
  TournamentFormat get _format;
  int get _maxPlayers;
  DateTime? get _startDate;
  String get _currency;
  int get _rewardedCount;
  bool get _publishNow;
  bool get _autoGenerateBracket;
  int get _matchIntervalMinutes;
  bool get _thirdPlaceMatch;
  String get _countryCode;
  List<PaymentDraftCountry> get _paymentCountries;

  TextEditingController get _nameCtrl;
  TextEditingController get _descCtrl;
  TextEditingController get _entryFeeCtrl;
  TextEditingController get _commissionXafCtrl;
  List<TextEditingController> get _topShareCtrls;
  List<TextEditingController> get _blockShareCtrls;
  TextEditingController get _referralQuotaCtrl;
  TextEditingController get _roundIntervalsCtrl;
  TextEditingController get _groupCountCtrl;
  TextEditingController get _qualifiersPerGroupCtrl;
  TextEditingController get _androidStoreUrlCtrl;
  TextEditingController get _iosStoreUrlCtrl;

  // ─── Submit ─────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (_submitting) return;
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null) {
      setState(() => _error = 'Session expirée — reconnecte-toi.');
      return;
    }
    // Re-validation COMPLÈTE (le rail cliquable pouvait mener au Récap sans
    // renseigner les étapes) : nom, capacité, frais, ET options de paiement si
    // la compétition est payante.
    final invalid = _firstInvalidStepMessage();
    if (invalid != null) {
      setState(() => _error = invalid);
      return;
    }
    // Date de début : doit être dans le futur (sauf édition d'une comp dont la
    // date est déjà passée).
    final start = _startDate!;
    if (!_isEditing && !start.isAfter(DateTime.now())) {
      setState(() => _error = 'La date de début doit être dans le futur.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    final draft = _buildDraft();
    final repo = ref.read(adminCompetitionsRepositoryProvider);

    try {
      if (_isEditing) {
        final id = widget.editing!.id;
        await repo.update(id, buildUpdateCompetitionPayload(draft));
        await repo.setPaymentOptions(
          id,
          paymentOptionsFromDrafts(_paymentCountries),
        );
        await ref.read(adminAuditLogRepositoryProvider).record(
          adminId: adminId,
          action: 'competition_updated',
          targetType: 'competition',
          targetId: id,
          afterState: {
            'name': draft.name,
            'commission_xaf': draft.commissionXaf,
          },
        );
      } else {
        // Anti-duplication : si un create précédent a réussi mais qu'une étape
        // suivante a échoué, le retry NE recrée PAS — il met à jour la comp déjà
        // créée puis (re)pose les options (setPaymentOptions = remplace-tout).
        if (_createdId == null) {
          final created = await repo
              .create(buildCreateCompetitionPayload(draft, createdBy: adminId));
          _createdId = created.id;
        } else {
          await repo.update(
            _createdId!,
            buildUpdateCompetitionPayload(draft),
          );
        }
        await repo.setPaymentOptions(
          _createdId!,
          paymentOptionsFromDrafts(_paymentCountries),
        );
        await ref.read(adminAuditLogRepositoryProvider).record(
          adminId: adminId,
          action: 'competition_created',
          targetType: 'competition',
          targetId: _createdId!,
          afterState: {
            'name': draft.name,
            'game': _game.value,
            'format': _format.value,
            'published_immediately': _publishNow,
          },
        );
      }
      if (!mounted) return;
      context.go(AdminDesktopRoutes.competitions);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = arenaErrorMessage(e);
      });
    }
  }

  /// Message de la 1re étape invalide (ou cagnotte manquante sur comp payante),
  /// ou `null` si tout est valide. Sert de backstop au submit.
  String? _firstInvalidStepMessage() {
    bool stepOk(int s) => canAdvanceCompetitionStep(
          step: s,
          name: _nameCtrl.text,
          startDate: _startDate,
          maxPlayers: _maxPlayers,
          entryFeeText: _entryFeeCtrl.text,
          paymentCountries: _paymentCountries,
        );
    if (!stepOk(0)) return 'Renseigne le nom (≥ 3 caractères) et la date.';
    if (!stepOk(1)) return 'Choisis une capacité (≥ 2 joueurs).';
    if (!stepOk(3)) return 'Renseigne des frais valides (≥ 0).';
    if (!stepOk(4)) {
      return 'Compétition payante : renseigne au moins un opérateur '
          '(nom + code) par pays.';
    }
    final fee = double.tryParse(_entryFeeCtrl.text) ?? 0;
    if (fee > 0 && !_noReward && _computedPool() <= 0) {
      return 'Compétition payante : définis une cagnotte (> 0) ou coche '
          '« sans récompense ».';
    }
    return null;
  }

  /// Assemble le [CompetitionDraft] depuis les controllers/state du wizard
  /// desktop. Les payloads (create/update) sont factorisés dans
  /// `competition_draft.dart` (partagés avec le wizard mobile).
  CompetitionDraft _buildDraft() {
    final fee = double.tryParse(_entryFeeCtrl.text) ?? 0;
    final pool = _computedPool();
    final commissionXaf = _commissionXaf();
    final derivedCommissionPct =
        pool > 0 ? (commissionXaf / pool * 100).clamp(0, 100) : 0;
    return CompetitionDraft(
      name: _nameCtrl.text.trim(),
      game: _game,
      format: _format,
      publishNow: _publishNow,
      description: _emptyToNull(_descCtrl.text),
      startDate: _startDate!,
      maxPlayers: _maxPlayers,
      fee: fee,
      currency: _currency,
      countryCode: _countryCode,
      commissionXaf: commissionXaf,
      commissionPct: derivedCommissionPct.toDouble(),
      pool: pool,
      prizeDistribution: _prizeDistribution(),
      autoGenerateBracket: _autoGenerateBracket,
      matchIntervalMinutes: _matchIntervalMinutes,
      thirdPlaceMatch: _thirdPlaceMatch,
      referralQuota: _referralQuota(),
      roundIntervals: _roundIntervals(),
      formatConfig: _formatConfig(),
      androidStoreUrl: _emptyToNull(_androidStoreUrlCtrl.text),
      iosStoreUrl: _emptyToNull(_iosStoreUrlCtrl.text),
    );
  }

  // ─── Calculs (identiques au wizard mobile) ──────────────────────────

  String? _emptyToNull(String s) => s.trim().isEmpty ? null : s.trim();

  List<int> _prizeDistribution() => computePrizeDistribution(
        noReward: _noReward,
        rewardedCount: _rewardedCount,
        topShareTexts: _topShareCtrls.map((c) => c.text).toList(),
        blockShareTexts: _blockShareCtrls.map((c) => c.text).toList(),
      );

  int _shareTotal() => computeShareTotal(
        noReward: _noReward,
        rewardedCount: _rewardedCount,
        topShareTexts: _topShareCtrls.map((c) => c.text).toList(),
        blockShareTexts: _blockShareCtrls.map((c) => c.text).toList(),
      );

  double _computedPool() => _shareTotal().toDouble();

  double _commissionXaf() =>
      double.tryParse(_commissionXafCtrl.text.trim()) ?? 0;

  int _referralQuota() => int.tryParse(_referralQuotaCtrl.text.trim()) ?? 0;

  List<int>? _roundIntervals() => parseRoundIntervals(_roundIntervalsCtrl.text);

  Map<String, dynamic> _formatConfig() => buildFormatConfig(
        format: _format,
        groupCountText: _groupCountCtrl.text,
        qualifiersText: _qualifiersPerGroupCtrl.text,
      );
}
