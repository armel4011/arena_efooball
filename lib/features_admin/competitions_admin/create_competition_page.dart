import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/competition.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/data/repositories/admin/admin_audit_log_repository.dart';
import 'package:arena/data/repositories/admin/admin_competitions_repository.dart';
import 'package:arena/features_shared/prize_ranks.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_stepper.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:arena/features_admin/competitions_admin/widgets/competition_form_widgets.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
];

class CreateCompetitionPage extends ConsumerStatefulWidget {
  const CreateCompetitionPage({this.editing, super.key});

  /// Compétition à modifier — `null` en mode création.
  final Competition? editing;

  @override
  ConsumerState<CreateCompetitionPage> createState() =>
      _CreateCompetitionPageState();
}

class _CreateCompetitionPageState
    extends ConsumerState<CreateCompetitionPage> {
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
  double _commissionPct = 15;
  // Places 1 à 4 : une part individuelle modifiable chacune.
  final List<TextEditingController> _topShareCtrls = [
    TextEditingController(text: '50'),
    TextEditingController(text: '25'),
    TextEditingController(text: '15'),
    TextEditingController(text: '10'),
  ];
  // Blocs 5-8 / 9-16 / 17-32 / 33-64 : un % « par place » saisi par bloc.
  final List<TextEditingController> _blockShareCtrls = [
    TextEditingController(text: '0'),
    TextEditingController(text: '0'),
    TextEditingController(text: '0'),
    TextEditingController(text: '0'),
  ];
  // Nombre de récompensés : 1 / 2 / 4 (places individuelles seules) puis
  // 8 / 16 / 32 / 64 qui activent les blocs successifs.
  int _rewardedCount = 4;
  bool _publishNow = true;

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
    _commissionPct = c.commissionPct.clamp(10, 100).toDouble();
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
        title: _isEditing ? 'Modifier la compét.' : 'Nouvelle compét.',
      ),
      body: SafeArea(
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
                  if (_step == 0) ..._buildInfosStep(),
                  if (_step == 1) ..._buildFormatStep(),
                  if (_step == 2) ..._buildPrizesStep(),
                  if (_step == 3) ..._buildFeesStep(),
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
                      onPressed: _step > 0
                          ? () => setState(() => _step--)
                          : null,
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
    );
  }

  // ─── Steps ────────────────────────────────────────────────────────

  /// En mode édition, grise et désactive un champ verrouillé (jeu,
  /// format, capacité, frais). En création, renvoie [child] tel quel.
  Widget _lockable(Widget child) {
    if (!_isEditing) return child;
    return IgnorePointer(
      child: Opacity(opacity: 0.45, child: child),
    );
  }

  List<Widget> _buildInfosStep() => [
        Text('Nom de la compétition', style: ArenaText.inputLabel),
        const SizedBox(height: ArenaSpacing.xs),
        ArenaTextField(
          controller: _nameCtrl,
          hint: 'Cameroon eFootball Cup',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: ArenaSpacing.md),
        Text('Jeu', style: ArenaText.inputLabel),
        const SizedBox(height: ArenaSpacing.xs),
        _lockable(
          GamePicker(
            current: _game,
            onChanged: (g) => setState(() => _game = g),
          ),
        ),
        const SizedBox(height: ArenaSpacing.md),
        Text('Description (optionnel)', style: ArenaText.inputLabel),
        const SizedBox(height: ArenaSpacing.xs),
        ArenaTextField(
          controller: _descCtrl,
          hint: 'Petite phrase de pitch…',
          minLines: 2,
          maxLines: 4,
        ),
        const SizedBox(height: ArenaSpacing.md),
        Text('Date de début', style: ArenaText.inputLabel),
        const SizedBox(height: ArenaSpacing.xs),
        InkWell(
          onTap: _pickStartDate,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: ArenaSpacing.md,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: ArenaColors.carbon,
              borderRadius: BorderRadius.circular(ArenaRadius.md),
              border: Border.all(color: ArenaColors.border),
            ),
            child: Text(
              _startDate == null
                  ? 'Choisir une date'
                  : DateFormat('EEEE dd/MM/yyyy HH:mm', 'fr_FR')
                      .format(_startDate!),
              style: ArenaText.body,
            ),
          ),
        ),
      ];

  List<Widget> _buildFormatStep() => [
        if (_isEditing) ...[
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
              'ℹ Format et capacité ne sont pas modifiables après '
              'création — ils conditionnent le bracket déjà calculé.',
              style: ArenaText.body,
            ),
          ),
          const SizedBox(height: ArenaSpacing.md),
        ],
        Text('Format du tournoi', style: ArenaText.inputLabel),
        const SizedBox(height: ArenaSpacing.xs),
        _lockable(
          FormatPicker(
            current: _format,
            onChanged: (f) => setState(() => _format = f),
          ),
        ),
        const SizedBox(height: ArenaSpacing.md),
        Text('Nombre de joueurs max', style: ArenaText.inputLabel),
        const SizedBox(height: ArenaSpacing.xs),
        _lockable(
          MaxPlayersPicker(
            current: _maxPlayers,
            onChanged: (n) => setState(() => _maxPlayers = n),
          ),
        ),
      ];

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

  List<Widget> _buildFeesStep() {
    final fee = double.tryParse(_entryFeeCtrl.text) ?? 0;
    final isPaid = fee > 0;
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
          'ℹ Frais d\'inscription = 0 → compétition GRATUITE (badge sur la '
          'carte + bypass paiement). Sinon le joueur paie en P2P sur les '
          'codes marchands ci-dessous, et le super-admin valide manuellement.',
          style: ArenaText.body,
        ),
      ),
      const SizedBox(height: ArenaSpacing.md),
      Text('Frais d\'inscription', style: ArenaText.inputLabel),
      const SizedBox(height: ArenaSpacing.xs),
      Row(
        children: [
          Expanded(
            flex: 2,
            child: _lockable(
              ArenaTextField(
                controller: _entryFeeCtrl,
                hint: '0',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
          const SizedBox(width: ArenaSpacing.xs),
          Expanded(
            child: _lockable(
              CurrencyPicker(
                current: _currency,
                onChanged: (c) => setState(() => _currency = c),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: ArenaSpacing.md),
      Text('Commission ARENA', style: ArenaText.inputLabel),
      const SizedBox(height: ArenaSpacing.xs),
      Row(
        children: [
          Expanded(
            child: Slider(
              value: _commissionPct,
              min: 10,
              max: 100,
              divisions: 90,
              label: '${_commissionPct.round()}%',
              onChanged: (v) => setState(() => _commissionPct = v),
              activeColor: ArenaColors.signalBlue,
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              '${_commissionPct.round()}%',
              style: ArenaText.mono,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
      if (isPaid) ...[
        const SizedBox(height: ArenaSpacing.lg),
        Container(
          padding: const EdgeInsets.all(ArenaSpacing.md),
          decoration: arenaWarningCardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '📱 Codes marchands (requis pour comp. payante)',
                style: ArenaText.h3,
              ),
              const SizedBox(height: ArenaSpacing.xs),
              Text(
                'Affichés au joueur sur P2 quand il paie. Le super-admin '
                'valide ensuite manuellement chaque transaction reçue.',
                style: ArenaText.small,
              ),
            ],
          ),
        ),
        const SizedBox(height: ArenaSpacing.md),
        Text('Code marchand Orange Money', style: ArenaText.inputLabel),
        const SizedBox(height: ArenaSpacing.xs),
        ArenaTextField(
          controller: _orangeMomoCtrl,
          hint: 'ex. *126*1*001234#',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: ArenaSpacing.md),
        Text('Code marchand MTN MoMo', style: ArenaText.inputLabel),
        const SizedBox(height: ArenaSpacing.xs),
        ArenaTextField(
          controller: _mtnMomoCtrl,
          hint: 'ex. *126*7*009876#',
          onChanged: (_) => setState(() {}),
        ),
      ],
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
      const SizedBox(height: ArenaSpacing.lg),
      if (!_isEditing)
        PublishToggleCard(
          publishNow: _publishNow,
          onChanged: (v) => setState(() => _publishNow = v),
        ),
      const SizedBox(height: ArenaSpacing.md),
      if (_submitting)
        const Center(child: CircularProgressIndicator()),
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

    if (_isEditing) {
      await _submitEdit(adminId, pool);
      return;
    }

    try {
      final created = await ref
          .read(adminCompetitionsRepositoryProvider)
          .create({
        'name': _nameCtrl.text.trim(),
        'game': _game.value,
        'format': _format.value,
        'status': _publishNow ? 'registration_open' : 'draft',
        'description': _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        'start_date': _startDate!.toUtc().toIso8601String(),
        'max_players': _maxPlayers,
        'registration_fee': fee,
        'registration_currency': _currency,
        'commission_pct': _commissionPct,
        'prize_pool_local': pool,
        'prize_pool_currency': _currency,
        'prize_distribution': _prizeDistribution(),
        'created_by': adminId,
        if (fee > 0) 'orange_money_code': _orangeMomoCtrl.text.trim(),
        if (fee > 0) 'mtn_momo_code': _mtnMomoCtrl.text.trim(),
      });
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
  Future<void> _submitEdit(String adminId, double pool) async {
    final id = widget.editing!.id;
    final fee = double.tryParse(_entryFeeCtrl.text) ?? 0;
    try {
      await ref.read(adminCompetitionsRepositoryProvider).update(id, {
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        'start_date': _startDate!.toUtc().toIso8601String(),
        'commission_pct': _commissionPct,
        'prize_pool_local': pool,
        'prize_distribution': _prizeDistribution(),
        if (fee > 0) 'orange_money_code': _orangeMomoCtrl.text.trim(),
        if (fee > 0) 'mtn_momo_code': _mtnMomoCtrl.text.trim(),
      });
      await ref.read(adminAuditLogRepositoryProvider).record(
        adminId: adminId,
        action: 'competition_updated',
        targetType: 'competition',
        targetId: id,
        afterState: {
          'name': _nameCtrl.text.trim(),
          'commission_pct': _commissionPct,
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

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    // En édition, la date d'origine peut être passée : on autorise alors
    // de remonter jusqu'à elle plutôt que de planter le date picker.
    final earliest = _startDate != null && _startDate!.isBefore(now)
        ? _startDate!
        : now;
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

