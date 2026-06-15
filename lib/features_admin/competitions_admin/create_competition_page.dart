import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/utils/sentry_trace.dart';
import 'package:arena/data/models/competition.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/data/repositories/admin/admin_audit_log_repository.dart';
import 'package:arena/data/repositories/admin/admin_competitions_repository.dart';
import 'package:arena/features_admin/competitions_admin/widgets/competition_form_widgets.dart';
import 'package:arena/features_admin/competitions_admin/widgets/wizard_step_fees.dart';
import 'package:arena/features_admin/competitions_admin/widgets/wizard_step_format.dart';
import 'package:arena/features_admin/competitions_admin/widgets/wizard_step_infos.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:arena/features_shared/prize_ranks.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/features_shared/widgets/arena_stepper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// PHASE 11 · A8 — 5-step competition creation wizard.
///
/// Steps : Infos → Format → Prix (1 à 64 rangs) → Frais → Review. Each
/// step validates its own slice of state. The final INSERT goes through
/// [AdminCompetitionsRepository.create], stamps a `competition_created`
/// audit log row and pops back to the list.
///
/// Paid competitions (`registration_fee > 0`) need the PHASE 11bis
/// payment stack to actually function — the form lets the admin set a
/// fee but warns them clearly.
///
/// En mode édition (`editing` non nul), le wizard pré-remplit tous les
/// champs et n'autorise que les modifications « sûres » : nom,
/// description, date, commission, distribution des prix, codes
/// marchands. Jeu / format / capacité / frais d'inscription restent
/// verrouillés (ils impactent bracket et paiements).
///
/// Maps to screen A8 of `arena_v2.html`.

/// Blocs de récompenses au-delà du top 4 : (libellé, taille, dernier
/// rang). Le bloc d'index `i` est actif dès que le nombre de
/// récompensés atteint son `lastRank`. La valeur saisie pour un bloc
/// est le % attribué à *chaque* place du bloc.
const List<({String label, int size, int lastRank})> _prizeBlocks = [
  (label: '5ème – 8ème', size: 4, lastRank: 8),
  (label: '9ème – 16ème', size: 8, lastRank: 16),
  (label: '17ème – 32ème', size: 16, lastRank: 32),
  (label: '33ème – 64ème', size: 32, lastRank: 64),
  (label: '65ème – 128ème', size: 64, lastRank: 128),
];

class CreateCompetitionPage extends ConsumerStatefulWidget {
  const CreateCompetitionPage({this.editing, super.key});

  /// Compétition à modifier — `null` en mode création.
  final Competition? editing;

  @override
  ConsumerState<CreateCompetitionPage> createState() =>
      _CreateCompetitionPageState();
}

class _CreateCompetitionPageState extends ConsumerState<CreateCompetitionPage> {
  static const _stepCount = 5;
  int _step = 0;
  bool _submitting = false;

  // Form state ──────────────────────────────────────────────────────
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  GameType _game = GameType.efootball;
  TournamentFormat _format = TournamentFormat.singleElimination;
  int _maxPlayers = 16;
  DateTime? _startDate;
  final _entryFeeCtrl = TextEditingController(text: '0');
  final _orangeMomoCtrl = TextEditingController();
  final _mtnMomoCtrl = TextEditingController();
  String _currency = 'XAF';
  // Commission ARENA en montant absolu (Lot B). `commission_pct` reste
  // calculé en dérivé pour cohérence avec la colonne legacy.
  final _commissionXafCtrl = TextEditingController(text: '0');
  // Places 1 à 4 : une part individuelle modifiable chacune.
  final List<TextEditingController> _topShareCtrls = [
    TextEditingController(text: '50'),
    TextEditingController(text: '25'),
    TextEditingController(text: '15'),
    TextEditingController(text: '10'),
  ];
  // Blocs 5-8 / 9-16 / 17-32 / 33-64 / 65-128 : un % « par place » saisi par
  // bloc. Dimensionné sur `_prizeBlocks` pour rester aligné si on ajoute un
  // palier.
  final List<TextEditingController> _blockShareCtrls = List.generate(
    _prizeBlocks.length,
    (_) => TextEditingController(text: '0'),
  );
  // Nombre de récompensés : 1 / 2 / 4 (places individuelles seules) puis
  // 8 / 16 / 32 / 64 qui activent les blocs successifs.
  int _rewardedCount = 4;
  bool _publishNow = true;

  // Lot A — auto-management.
  bool _autoGenerateBracket = true;
  int _matchIntervalMinutes = 60;

  // Match de classement (petite finale / 3e place) — opt-in admin.
  bool _thirdPlaceMatch = false;

  // Lot D — Quota parrainages requis pour s'inscrire (item 8).
  // 0 = pas de gating. Activable seulement pour comp. gratuites.
  final _referralQuotaCtrl = TextEditingController(text: '0');

  // Lot D.2 — mode parrainage. Décision user 2026-05-19 : règle unique
  // 'any' (tout invité actif compte). L'option 'engaged' du wizard est
  // retirée mais la colonne `competitions.referral_activity_mode` reste
  // pour compat — toujours forcée à 'any' au submit.

  // Lot A.2 — Override intervalles par round (saisi en CSV, parsé en
  // List<int>). Optionnel. Si vide → fallback `matchIntervalMinutes`.
  final _roundIntervalsCtrl = TextEditingController();

  // Lot F.1 — Config groupes (visible si format = groups_then_knockout).
  final _groupCountCtrl = TextEditingController(text: '4');
  final _qualifiersPerGroupCtrl = TextEditingController(text: '2');

  // Item 1 prompt 2026-05-19 — URLs des stores du jeu (optionnels).
  final _androidStoreUrlCtrl = TextEditingController();
  final _iosStoreUrlCtrl = TextEditingController();

  bool get _isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final c = widget.editing;
    if (c == null) return;
    // Mode édition : pré-remplit tous les champs depuis la compétition.
    _nameCtrl.text = c.name;
    _descCtrl.text = c.description ?? '';
    _game = c.game;
    _format = c.format;
    _maxPlayers = c.maxPlayers;
    _startDate = c.startDate;
    _entryFeeCtrl.text = c.registrationFee == c.registrationFee.roundToDouble()
        ? c.registrationFee.round().toString()
        : c.registrationFee.toString();
    _orangeMomoCtrl.text = c.orangeMoneyCode ?? '';
    _mtnMomoCtrl.text = c.mtnMomoCode ?? '';
    _currency = c.registrationCurrency;
    final commissionXaf = c.commissionXaf;
    _commissionXafCtrl.text = commissionXaf == commissionXaf.roundToDouble()
        ? commissionXaf.round().toString()
        : commissionXaf.toString();
    _autoGenerateBracket = c.autoGenerateBracket;
    _matchIntervalMinutes = c.matchIntervalMinutes;
    _thirdPlaceMatch = c.thirdPlaceMatch;
    _referralQuotaCtrl.text = c.referralQuota.toString();
    // referral_activity_mode toujours 'any' depuis le wizard — pas de UI.
    if (c.roundIntervals != null && c.roundIntervals!.isNotEmpty) {
      _roundIntervalsCtrl.text = c.roundIntervals!.join(',');
    }
    _groupCountCtrl.text =
        (c.formatConfig['group_count'] as num?)?.toInt().toString() ?? '4';
    _qualifiersPerGroupCtrl.text =
        (c.formatConfig['qualifiers_per_group'] as num?)?.toInt().toString() ??
            '2';
    _androidStoreUrlCtrl.text = c.androidStoreUrl ?? '';
    _iosStoreUrlCtrl.text = c.iosStoreUrl ?? '';
    // Reconstruit places individuelles + blocs depuis la liste plate
    // stockée (best-effort : un bloc relit le % de sa 1ère place).
    final dist = c.prizeDistribution;
    _rewardedCount = _snapRewardedCount(dist.length);
    final topCount = _rewardedCount < 4 ? _rewardedCount : 4;
    for (var i = 0; i < topCount && i < dist.length; i++) {
      _topShareCtrls[i].text = dist[i].toString();
    }
    for (var b = 0; b < _prizeBlocks.length; b++) {
      final block = _prizeBlocks[b];
      if (_rewardedCount < block.lastRank) break;
      final firstIndex = block.lastRank - block.size;
      if (firstIndex < dist.length) {
        _blockShareCtrls[b].text = dist[firstIndex].toString();
      }
    }
  }

  /// Ramène une longueur de distribution arbitraire au palier valide
  /// le plus proche par défaut (1, 2, 4, 8, 16, 32, 64).
  static int _snapRewardedCount(int length) {
    var snapped = kRewardedRankOptions.first;
    for (final opt in kRewardedRankOptions) {
      if (opt <= length) snapped = opt;
    }
    return snapped;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _entryFeeCtrl.dispose();
    _orangeMomoCtrl.dispose();
    _mtnMomoCtrl.dispose();
    _commissionXafCtrl.dispose();
    _referralQuotaCtrl.dispose();
    _roundIntervalsCtrl.dispose();
    _groupCountCtrl.dispose();
    _qualifiersPerGroupCtrl.dispose();
    _androidStoreUrlCtrl.dispose();
    _iosStoreUrlCtrl.dispose();
    for (final c in _topShareCtrls) {
      c.dispose();
    }
    for (final c in _blockShareCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _canAdvance {
    switch (_step) {
      case 0:
        return _nameCtrl.text.trim().length >= 3 && _startDate != null;
      case 1:
        return _maxPlayers >= 2;
      case 2:
        // Les montants des récompenses sont libres (y compris 0).
        return true;
      case 3:
        final fee = double.tryParse(_entryFeeCtrl.text) ?? -1;
        if (fee < 0) return false;
        // Compétition payante : on exige les 2 codes marchands (sinon le
        // joueur tombe sur un P2 vide).
        if (fee > 0) {
          if (_orangeMomoCtrl.text.trim().isEmpty) return false;
          if (_mtnMomoCtrl.text.trim().isEmpty) return false;
        }
        return true;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ArenaAppBar(
        title: _isEditing ? 'MODIFIER' : 'CRÉER',
      ),
      body: ArenaScreenBackground(
        accent: ArenaColors.neonRed,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  ArenaSpacing.lg,
                  ArenaSpacing.lg,
                  ArenaSpacing.lg,
                  ArenaSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ArenaStepper(
                      totalSteps: _stepCount,
                      currentStep: _step,
                    ),
                    const SizedBox(height: ArenaSpacing.sm),
                    Text(
                      'Étape ${_step + 1} / $_stepCount — ${_stepTitle(_step)}',
                      style: ArenaText.bodyMuted,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(ArenaSpacing.lg),
                  children: [
                    if (_step == 0)
                      WizardStepInfos(
                        nameCtrl: _nameCtrl,
                        descCtrl: _descCtrl,
                        androidStoreUrlCtrl: _androidStoreUrlCtrl,
                        iosStoreUrlCtrl: _iosStoreUrlCtrl,
                        game: _game,
                        startDate: _startDate,
                        isEditing: _isEditing,
                        onChanged: () => setState(() {}),
                        onGameChanged: (g) => setState(() => _game = g),
                        onPickStartDate: _pickStartDate,
                      ),
                    if (_step == 1)
                      WizardStepFormat(
                        format: _format,
                        maxPlayers: _maxPlayers,
                        autoGenerateBracket: _autoGenerateBracket,
                        matchIntervalMinutes: _matchIntervalMinutes,
                        thirdPlaceMatch: _thirdPlaceMatch,
                        roundIntervalsCtrl: _roundIntervalsCtrl,
                        groupCountCtrl: _groupCountCtrl,
                        qualifiersPerGroupCtrl: _qualifiersPerGroupCtrl,
                        isEditing: _isEditing,
                        onFormatChanged: (f) => setState(() => _format = f),
                        onMaxPlayersChanged: (n) =>
                            setState(() => _maxPlayers = n),
                        onAutoGenerateChanged: (v) =>
                            setState(() => _autoGenerateBracket = v),
                        onMatchIntervalChanged: (m) =>
                            setState(() => _matchIntervalMinutes = m),
                        onThirdPlaceChanged: (v) =>
                            setState(() => _thirdPlaceMatch = v),
                        onChanged: () => setState(() {}),
                      ),
                    if (_step == 2) ..._buildPrizesStep(),
                    if (_step == 3)
                      WizardStepFees(
                        entryFeeCtrl: _entryFeeCtrl,
                        currency: _currency,
                        commissionXafCtrl: _commissionXafCtrl,
                        orangeMomoCtrl: _orangeMomoCtrl,
                        mtnMomoCtrl: _mtnMomoCtrl,
                        referralQuotaCtrl: _referralQuotaCtrl,
                        isEditing: _isEditing,
                        onChanged: () => setState(() {}),
                        onCurrencyChanged: (c) => setState(() => _currency = c),
                      ),
                    if (_step == 4) ..._buildReviewStep(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(ArenaSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: ArenaButton(
                        label: '← RETOUR',
                        variant: ArenaButtonVariant.secondary,
                        fullWidth: true,
                        onPressed:
                            _step > 0 ? () => setState(() => _step--) : null,
                      ),
                    ),
                    const SizedBox(width: ArenaSpacing.xs),
                    Expanded(
                      child: ArenaButton(
                        label: _step < _stepCount - 1
                            ? 'SUIVANT →'
                            : (_isEditing
                                ? '💾 ENREGISTRER'
                                : (_publishNow
                                    ? '🚀 CRÉER & PUBLIER'
                                    : '💾 SAUVER EN BROUILLON')),
                        fullWidth: true,
                        onPressed: !_canAdvance || _submitting
                            ? null
                            : (_step < _stepCount - 1
                                ? () => setState(() => _step++)
                                : _submit),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Steps ────────────────────────────────────────────────────────

  List<Widget> _buildPrizesStep() {
    final topCount = _rewardedCount < 4 ? _rewardedCount : 4;
    return [
      Container(
        padding: const EdgeInsets.all(ArenaSpacing.md),
        decoration: BoxDecoration(
          color: ArenaColors.signalBlue.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(ArenaRadius.md),
          border: Border.all(
            color: ArenaColors.signalBlue.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          'ℹ Saisis le montant attribué à chaque place — en $_currency. '
          'La cagnotte de la compétition est la somme de ces montants.',
          style: ArenaText.body,
        ),
      ),
      const SizedBox(height: ArenaSpacing.lg),
      Text('Nombre de récompensés', style: ArenaText.inputLabel),
      const SizedBox(height: ArenaSpacing.xs),
      RewardedCountPicker(
        current: _rewardedCount,
        onChanged: _setRewardedCount,
      ),
      const SizedBox(height: ArenaSpacing.lg),
      // Places 1 à 4 : une ligne individuelle modifiable chacune.
      for (var i = 0; i < topCount; i++) ...[
        ShareRow(
          position: i,
          controller: _topShareCtrls[i],
          onChanged: () => setState(() {}),
        ),
        const SizedBox(height: ArenaSpacing.sm),
      ],
      // Blocs 5-8 / 9-16 / 17-32 / 33-64 : un montant par place, saisi une fois.
      for (var b = 0; b < _prizeBlocks.length; b++)
        if (_rewardedCount >= _prizeBlocks[b].lastRank) ...[
          BlockShareRow(
            block: _prizeBlocks[b],
            controller: _blockShareCtrls[b],
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: ArenaSpacing.sm),
        ],
      const SizedBox(height: ArenaSpacing.md),
      ShareTotalCard(total: _shareTotal(), currency: _currency),
    ];
  }

  List<Widget> _buildReviewStep() {
    final fee = double.tryParse(_entryFeeCtrl.text) ?? 0;
    final pool = _computedPool();
    final fmt = NumberFormat('#,###', 'fr_FR');

    return [
      Text('Récap', style: ArenaText.h3),
      const SizedBox(height: ArenaSpacing.md),
      ReviewRow(label: 'Nom', value: _nameCtrl.text.trim()),
      ReviewRow(label: 'Jeu', value: _game.label),
      ReviewRow(
        label: 'Format',
        value: formatLabel(_format),
      ),
      ReviewRow(label: 'Joueurs', value: '$_maxPlayers max'),
      ReviewRow(
        label: 'Date',
        value: _startDate == null
            ? '—'
            : DateFormat('dd/MM/yyyy HH:mm').format(_startDate!),
      ),
      ReviewRow(
        label: 'Inscription',
        value: fee == 0 ? 'Gratuit' : '${fmt.format(fee.round())} $_currency',
      ),
      ReviewRow(
        label: 'Cagnotte (somme des récompenses)',
        value: '${fmt.format(pool.round())} $_currency',
      ),
      ReviewRow(
        label: 'Commission ARENA',
        value: '${fmt.format(_commissionXaf().round())} $_currency',
      ),
      ReviewRow(
        label: 'Bracket auto',
        value: _autoGenerateBracket ? 'Oui — au quota atteint' : 'Non — manuel',
      ),
      ReviewRow(
        label: 'Intervalle entre rounds',
        value: _matchIntervalLabel(_matchIntervalMinutes),
      ),
      if (_format != TournamentFormat.roundRobin)
        ReviewRow(
          label: 'Match de classement (3e place)',
          value: _thirdPlaceMatch ? 'Oui' : 'Non',
        ),
      if (_referralQuota() > 0)
        ReviewRow(
          label: 'Parrainages requis',
          value: '${_referralQuota()} ami(s) via code ARN-XXXX',
        ),
      const SizedBox(height: ArenaSpacing.lg),
      if (!_isEditing)
        PublishToggleCard(
          publishNow: _publishNow,
          onChanged: (v) => setState(() => _publishNow = v),
        ),
      const SizedBox(height: ArenaSpacing.md),
      if (_submitting) const Center(child: CircularProgressIndicator()),
    ];
  }

  // ─── Submit ───────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null || _startDate == null) {
      setState(() => _submitting = false);
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
      setState(() => _submitting = false);
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
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec : $e')),
      );
    }
  }

  /// Change le nombre de récompensés (1, 2, 4, 8, 16, 32, 64). Les
  /// contrôleurs sont fixes — seul [_rewardedCount] pilote ce qui
  /// s'affiche et entre dans le calcul.
  void _setRewardedCount(int count) {
    setState(() => _rewardedCount = count.clamp(1, kMaxRewardedRanks));
  }

  /// Construit la liste plate des **montants** par place : places
  /// individuelles 1-4 puis chaque bloc actif déplié (même montant
  /// répété sur toutes ses places).
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

  /// Somme des montants : places individuelles + (montant de bloc × sa
  /// taille). C'est la cagnotte totale distribuée.
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

  /// Cagnotte à persister dans `prize_pool_local` : la somme des
  /// montants de récompense saisis.
  double _computedPool() => _shareTotal().toDouble();

  /// Commission ARENA en montant XAF (Lot B). Parse l'input numérique.
  double _commissionXaf() =>
      double.tryParse(_commissionXafCtrl.text.trim()) ?? 0;

  /// Quota parrainages requis (Lot D). 0 = pas de gating.
  int _referralQuota() => int.tryParse(_referralQuotaCtrl.text.trim()) ?? 0;

  /// Lot A.2 — Parse `_roundIntervalsCtrl` CSV → `List<int>?`. Vide ou
  /// malformé → null (utilise l'intervalle global).
  List<int>? _roundIntervals() {
    final raw = _roundIntervalsCtrl.text.trim();
    if (raw.isEmpty) return null;
    final parts =
        raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
    final ints = <int>[];
    for (final p in parts) {
      final n = int.tryParse(p);
      if (n == null || n <= 0) return null; // invalid → fallback
      ints.add(n);
    }
    return ints.isEmpty ? null : ints;
  }

  /// Lot F.1 — Config groupes pour groups_then_knockout.
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

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    // En édition, la date d'origine peut être passée : on autorise alors
    // de remonter jusqu'à elle plutôt que de planter le date picker.
    final earliest =
        _startDate != null && _startDate!.isBefore(now) ? _startDate! : now;
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now.add(const Duration(days: 1)),
      firstDate: earliest,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startDate ?? now),
    );
    if (time == null) return;
    setState(() {
      _startDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  /// Format humain pour l'intervalle entre rounds (Lot A).
  static String _matchIntervalLabel(int minutes) {
    if (minutes < 60) return '$minutes min';
    if (minutes < 1440) {
      final h = minutes ~/ 60;
      return '${h}h';
    }
    final d = minutes ~/ 1440;
    return d == 1 ? '1 jour' : '$d jours';
  }

  static String _stepTitle(int step) {
    switch (step) {
      case 0:
        return 'Infos';
      case 1:
        return 'Format';
      case 2:
        return 'Récompenses';
      case 3:
        return 'Frais';
      case 4:
        return 'Récap';
      default:
        return '';
    }
  }
}
