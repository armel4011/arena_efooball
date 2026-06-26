part of 'create_competition_page.dart';

/// Logique de persistance du wizard (création + édition), extraite du State
/// pour garder `create_competition_page.dart` sous le seuil god-file. L'extension
/// vit dans la même librairie (`part of`) → accès complet aux champs privés du
/// State, à `ref`, `setState`, `context`, `mounted`.
extension _CreateCompetitionSubmit on _CreateCompetitionPageState {
  Future<void> _submit() async {
    if (_submitting) return;
    _setSubmitting(true);
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null || _startDate == null) {
      _setSubmitting(false);
      return;
    }

    final fee = double.tryParse(_entryFeeCtrl.text) ?? 0;
    final pool = _computedPool();
    final commissionXaf = _commissionXaf();
    // commission_pct dérivée pour compat de la colonne legacy
    final derivedCommissionPct =
        pool > 0 ? (commissionXaf / pool * 100).clamp(0, 100) : 0;

    if (_isEditing) {
      await _submitEdit(
        adminId,
        pool,
        commissionXaf,
        derivedCommissionPct.toDouble(),
      );
      return;
    }

    try {
      final created = await traceAsync(
        'admin.competition.create',
        _isEditing ? 'edit existing' : 'new from wizard',
        () => ref.read(adminCompetitionsRepositoryProvider).create({
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
          if (fee > 0) 'orange_money_code': _orangeMomoCtrl.text.trim(),
          if (fee > 0) 'mtn_momo_code': _mtnMomoCtrl.text.trim(),
          'android_store_url': _androidStoreUrlCtrl.text.trim().isEmpty
              ? null
              : _androidStoreUrlCtrl.text.trim(),
          'ios_store_url': _iosStoreUrlCtrl.text.trim().isEmpty
              ? null
              : _iosStoreUrlCtrl.text.trim(),
        }),
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _publishNow
                ? 'Compétition publiée — inscriptions ouvertes.'
                : 'Compétition sauvée en brouillon.',
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      _setSubmitting(false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec : $e')),
      );
    }
  }

  /// Branche édition : ne pousse que les champs « sûrs ». Jeu, format,
  /// capacité, frais et devise restent ceux d'origine.
  Future<void> _submitEdit(
    String adminId,
    double pool,
    double commissionXaf,
    double derivedCommissionPct,
  ) async {
    final id = widget.editing!.id;
    final fee = double.tryParse(_entryFeeCtrl.text) ?? 0;
    try {
      await ref.read(adminCompetitionsRepositoryProvider).update(id, {
        'name': _nameCtrl.text.trim(),
        'description':
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'start_date': _startDate!.toUtc().toIso8601String(),
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
        if (fee > 0) 'orange_money_code': _orangeMomoCtrl.text.trim(),
        if (fee > 0) 'mtn_momo_code': _mtnMomoCtrl.text.trim(),
        'android_store_url': _androidStoreUrlCtrl.text.trim().isEmpty
            ? null
            : _androidStoreUrlCtrl.text.trim(),
        'ios_store_url': _iosStoreUrlCtrl.text.trim().isEmpty
            ? null
            : _iosStoreUrlCtrl.text.trim(),
      });
      await ref.read(adminAuditLogRepositoryProvider).record(
        adminId: adminId,
        action: 'competition_updated',
        targetType: 'competition',
        targetId: id,
        afterState: {
          'name': _nameCtrl.text.trim(),
          'commission_xaf': commissionXaf,
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compétition mise à jour.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      _setSubmitting(false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec : $e')),
      );
    }
  }
}
