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

    final draft = _buildDraft();

    if (_isEditing) {
      await _submitEdit(adminId, draft);
      return;
    }

    try {
      final created = await traceAsync(
        'admin.competition.create',
        'new from wizard',
        () => ref
            .read(adminCompetitionsRepositoryProvider)
            .create(buildCreateCompetitionPayload(draft, createdBy: adminId)),
      );
      // Options de paiement (pays × opérateur × code) — écrites séparément via
      // la RPC dédiée APRÈS l'INSERT (non-atomique avec, acceptable). Vide si
      // gratuite ou si l'admin n'a rien saisi.
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

  /// Assemble le [CompetitionDraft] depuis les controllers/state du wizard.
  /// La construction des payloads (create/update) est ensuite factorisée dans
  /// `competition_draft.dart` (partagée avec le wizard desktop).
  CompetitionDraft _buildDraft() {
    final fee = double.tryParse(_entryFeeCtrl.text) ?? 0;
    final pool = _computedPool();
    final commissionXaf = _commissionXaf();
    // commission_pct dérivée pour compat de la colonne legacy.
    final derivedCommissionPct =
        pool > 0 ? (commissionXaf / pool * 100).clamp(0, 100) : 0;
    return CompetitionDraft(
      name: _nameCtrl.text.trim(),
      game: _game,
      format: _format,
      publishNow: _publishNow,
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
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
      androidStoreUrl: _androidStoreUrlCtrl.text.trim().isEmpty
          ? null
          : _androidStoreUrlCtrl.text.trim(),
      iosStoreUrl: _iosStoreUrlCtrl.text.trim().isEmpty
          ? null
          : _iosStoreUrlCtrl.text.trim(),
    );
  }

  /// Branche édition : ne pousse que les champs « sûrs ». Jeu, format,
  /// capacité, frais et devise restent ceux d'origine.
  Future<void> _submitEdit(String adminId, CompetitionDraft draft) async {
    final id = widget.editing!.id;
    try {
      await ref
          .read(adminCompetitionsRepositoryProvider)
          .update(id, buildUpdateCompetitionPayload(draft));
      // Remplace-tout transactionnel des options de paiement.
      await ref.read(adminCompetitionsRepositoryProvider).setPaymentOptions(
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
