part of 'desktop_create_competition_page.dart';

// ─────────────────────────────────────────────────────────────────────
// Soumission et calculs du wizard (identiques au wizard mobile).
//
// Mixin appliqué à [_DesktopCreateCompetitionPageState] : il accède aux
// champs/controllers privés du State via des membres abstraits que le
// State implémente. Fournit aussi `_lockable` + calculs requis par
// _StepBuilders. Aucun changement de comportement.
// ─────────────────────────────────────────────────────────────────────

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
    setState(() {
      _submitting = true;
      _error = null;
    });
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null || _startDate == null) {
      setState(() => _submitting = false);
      return;
    }

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
        final created = await repo
            .create(buildCreateCompetitionPayload(draft, createdBy: adminId));
        await repo.setPaymentOptions(
          created.id,
          paymentOptionsFromDrafts(_paymentCountries),
        );
        await ref.read(adminAuditLogRepositoryProvider).record(
          adminId: adminId,
          action: 'competition_created',
          targetType: 'competition',
          targetId: created.id,
          afterState: {
            'name': created.name,
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

  // Le desktop n'a pas de toggle « sans récompense » → noReward: false.
  List<int> _prizeDistribution() => computePrizeDistribution(
        noReward: false,
        rewardedCount: _rewardedCount,
        topShareTexts: _topShareCtrls.map((c) => c.text).toList(),
        blockShareTexts: _blockShareCtrls.map((c) => c.text).toList(),
      );

  int _shareTotal() => computeShareTotal(
        noReward: false,
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
