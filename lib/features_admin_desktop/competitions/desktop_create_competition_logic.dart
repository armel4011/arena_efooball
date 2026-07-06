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

    final fee = double.tryParse(_entryFeeCtrl.text) ?? 0;
    final pool = _computedPool();
    final commissionXaf = _commissionXaf();
    final derivedCommissionPct =
        pool > 0 ? (commissionXaf / pool * 100).clamp(0, 100) : 0;

    try {
      if (_isEditing) {
        await ref.read(adminCompetitionsRepositoryProvider).update(
              widget.editing!.id,
              {
                'name': _nameCtrl.text.trim(),
                'description': _descCtrl.text.trim().isEmpty
                    ? null
                    : _descCtrl.text.trim(),
                'start_date': _startDate!.toUtc().toIso8601String(),
                'country_code': _countryCode,
                'commission_xaf': commissionXaf,
                'commission_pct': derivedCommissionPct,
                'prize_pool_local': pool,
                'prize_distribution': _prizeDistribution(),
                'auto_generate_bracket': _autoGenerateBracket,
                'match_interval_minutes': _matchIntervalMinutes,
                'third_place_match': _thirdPlaceMatch,
                'referral_quota': _referralQuota(),
                'referral_activity_mode': 'any',
                'round_intervals': _roundIntervals(),
                'format_config': _formatConfig(),
                'android_store_url': _emptyToNull(_androidStoreUrlCtrl.text),
                'ios_store_url': _emptyToNull(_iosStoreUrlCtrl.text),
              },
            );
        await ref.read(adminCompetitionsRepositoryProvider).setPaymentOptions(
              widget.editing!.id,
              paymentOptionsFromDrafts(_paymentCountries),
            );
        await ref.read(adminAuditLogRepositoryProvider).record(
          adminId: adminId,
          action: 'competition_updated',
          targetType: 'competition',
          targetId: widget.editing!.id,
          afterState: {
            'name': _nameCtrl.text.trim(),
            'commission_xaf': commissionXaf,
          },
        );
      } else {
        final created =
            await ref.read(adminCompetitionsRepositoryProvider).create({
          'name': _nameCtrl.text.trim(),
          'game': _game.value,
          'format': _format.value,
          'status': _publishNow ? 'registration_open' : 'draft',
          'description':
              _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          'start_date': _startDate!.toUtc().toIso8601String(),
          'max_players': _maxPlayers,
          'registration_fee': fee,
          'registration_currency': _currency,
          'country_code': _countryCode,
          'commission_xaf': commissionXaf,
          'commission_pct': derivedCommissionPct,
          'prize_pool_local': pool,
          'prize_pool_currency': _currency,
          'prize_distribution': _prizeDistribution(),
          'created_by': adminId,
          'auto_generate_bracket': _autoGenerateBracket,
          'match_interval_minutes': _matchIntervalMinutes,
          'third_place_match': _thirdPlaceMatch,
          'referral_quota': _referralQuota(),
          'referral_activity_mode': 'any',
          'round_intervals': _roundIntervals(),
          'format_config': _formatConfig(),
          'android_store_url': _emptyToNull(_androidStoreUrlCtrl.text),
          'ios_store_url': _emptyToNull(_iosStoreUrlCtrl.text),
        });
        await ref.read(adminCompetitionsRepositoryProvider).setPaymentOptions(
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

  // ─── Calculs (identiques au wizard mobile) ──────────────────────────

  String? _emptyToNull(String s) => s.trim().isEmpty ? null : s.trim();

  List<int> _prizeDistribution() {
    final raw = <int>[];
    final topCount = _rewardedCount < 4 ? _rewardedCount : 4;
    for (var i = 0; i < topCount; i++) {
      raw.add(int.tryParse(_topShareCtrls[i].text) ?? 0);
    }
    for (var b = 0; b < _prizeBlocks.length; b++) {
      final block = _prizeBlocks[b];
      if (_rewardedCount < block.lastRank) break;
      final perPlace = int.tryParse(_blockShareCtrls[b].text) ?? 0;
      for (var k = 0; k < block.size; k++) {
        raw.add(perPlace);
      }
    }
    return raw;
  }

  int _shareTotal() {
    var total = 0;
    final topCount = _rewardedCount < 4 ? _rewardedCount : 4;
    for (var i = 0; i < topCount; i++) {
      total += int.tryParse(_topShareCtrls[i].text) ?? 0;
    }
    for (var b = 0; b < _prizeBlocks.length; b++) {
      final block = _prizeBlocks[b];
      if (_rewardedCount < block.lastRank) break;
      total += (int.tryParse(_blockShareCtrls[b].text) ?? 0) * block.size;
    }
    return total;
  }

  double _computedPool() => _shareTotal().toDouble();

  double _commissionXaf() =>
      double.tryParse(_commissionXafCtrl.text.trim()) ?? 0;

  int _referralQuota() => int.tryParse(_referralQuotaCtrl.text.trim()) ?? 0;

  List<int>? _roundIntervals() {
    final raw = _roundIntervalsCtrl.text.trim();
    if (raw.isEmpty) return null;
    final parts =
        raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
    final ints = <int>[];
    for (final p in parts) {
      final n = int.tryParse(p);
      if (n == null || n <= 0) return null;
      ints.add(n);
    }
    return ints.isEmpty ? null : ints;
  }

  Map<String, dynamic> _formatConfig() {
    if (_format != TournamentFormat.groupsThenKnockout) {
      return const <String, dynamic>{};
    }
    return <String, dynamic>{
      'group_count': int.tryParse(_groupCountCtrl.text.trim()) ?? 4,
      'qualifiers_per_group':
          int.tryParse(_qualifiersPerGroupCtrl.text.trim()) ?? 2,
    };
  }
}
