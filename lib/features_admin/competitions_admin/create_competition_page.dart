import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/data/repositories/admin/admin_audit_log_repository.dart';
import 'package:arena/data/repositories/admin/admin_competitions_repository.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_stepper.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// PHASE 11 · A8 — 5-step competition creation wizard.
///
/// Steps : Infos → Format → Prix (Top 4) → Frais → Review. Each step
/// validates its own slice of state. The final INSERT goes through
/// [AdminCompetitionsRepository.create], stamps a `competition_created`
/// audit log row and pops back to the list.
///
/// Paid competitions (`registration_fee > 0`) need the PHASE 11bis
/// payment stack to actually function — the form lets the admin set a
/// fee but warns them clearly.
///
/// Maps to screen A8 of `arena_v2.html`.
class CreateCompetitionPage extends ConsumerStatefulWidget {
  const CreateCompetitionPage({super.key});

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
  final _shareCtrls = [
    TextEditingController(text: '50'),
    TextEditingController(text: '25'),
    TextEditingController(text: '15'),
    TextEditingController(text: '10'),
  ];
  _PrizeMode _prizeMode = _PrizeMode.percentage;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _entryFeeCtrl.dispose();
    _orangeMomoCtrl.dispose();
    _mtnMomoCtrl.dispose();
    for (final c in _shareCtrls) {
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
        final total =
            _shareCtrls.map((c) => int.tryParse(c.text) ?? 0).reduce((a, b) => a + b);
        return _prizeMode == _PrizeMode.fixed || total == 100;
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
      appBar: const ArenaAppBar(title: 'Nouvelle compét.'),
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
                      label:
                          _step < _stepCount - 1 ? 'SUIVANT →' : '🚀 CRÉER',
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
        _GamePicker(
          current: _game,
          onChanged: (g) => setState(() => _game = g),
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
        Text('Format du tournoi', style: ArenaText.inputLabel),
        const SizedBox(height: ArenaSpacing.xs),
        _FormatPicker(
          current: _format,
          onChanged: (f) => setState(() => _format = f),
        ),
        const SizedBox(height: ArenaSpacing.md),
        Text('Nombre de joueurs max', style: ArenaText.inputLabel),
        const SizedBox(height: ArenaSpacing.xs),
        _MaxPlayersPicker(
          current: _maxPlayers,
          onChanged: (n) => setState(() => _maxPlayers = n),
        ),
      ];

  List<Widget> _buildPrizesStep() => [
        _PrizeModeCard(
          mode: _prizeMode,
          onChanged: (m) => setState(() => _prizeMode = m),
        ),
        const SizedBox(height: ArenaSpacing.lg),
        for (var i = 0; i < 4; i++) ...[
          _ShareRow(
            position: i,
            controller: _shareCtrls[i],
            mode: _prizeMode,
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: ArenaSpacing.sm),
        ],
        const SizedBox(height: ArenaSpacing.md),
        _ShareTotalCard(controllers: _shareCtrls, mode: _prizeMode),
      ];

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
            child: ArenaTextField(
              controller: _entryFeeCtrl,
              hint: '0',
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: ArenaSpacing.xs),
          Expanded(child: _CurrencyPicker(
            current: _currency,
            onChanged: (c) => setState(() => _currency = c),
          )),
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
              min: 0,
              max: 30,
              divisions: 30,
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
    final pool = fee * _maxPlayers * (1 - _commissionPct / 100);
    final fmt = NumberFormat('#,###', 'fr_FR');

    return [
      Text('Récap', style: ArenaText.h3),
      const SizedBox(height: ArenaSpacing.md),
      _ReviewRow(label: 'Nom', value: _nameCtrl.text.trim()),
      _ReviewRow(label: 'Jeu', value: _game.label),
      _ReviewRow(
        label: 'Format',
        value: _formatLabel(_format),
      ),
      _ReviewRow(label: 'Joueurs', value: '$_maxPlayers max'),
      _ReviewRow(
        label: 'Date',
        value: _startDate == null
            ? '—'
            : DateFormat('dd/MM/yyyy HH:mm').format(_startDate!),
      ),
      _ReviewRow(
        label: 'Inscription',
        value: fee == 0 ? 'Gratuit' : '${fmt.format(fee.round())} $_currency',
      ),
      if (fee > 0)
        _ReviewRow(
          label: 'Cagnotte estimée',
          value: '${fmt.format(pool.round())} $_currency '
              '(commission ${_commissionPct.round()}%)',
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
    if (adminId == null || _startDate == null) return;

    final fee = double.tryParse(_entryFeeCtrl.text) ?? 0;
    final pool = fee * _maxPlayers * (1 - _commissionPct / 100);

    try {
      final created = await ref
          .read(adminCompetitionsRepositoryProvider)
          .create({
        'name': _nameCtrl.text.trim(),
        'game': _game.value,
        'format': _format.value,
        'status': 'draft',
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
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compétition créée.')),
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

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
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
        return 'Prix (Top 4)';
      case 3:
        return 'Frais';
      case 4:
        return 'Récap';
      default:
        return '';
    }
  }

  static String _formatLabel(TournamentFormat f) {
    switch (f) {
      case TournamentFormat.singleElimination:
        return 'Élimination directe';
      case TournamentFormat.groupsThenKnockout:
        return 'Poules puis KO';
      case TournamentFormat.roundRobin:
        return 'Round robin';
    }
  }
}

enum _PrizeMode { percentage, fixed }

class _GamePicker extends StatelessWidget {
  const _GamePicker({required this.current, required this.onChanged});
  final GameType current;
  final ValueChanged<GameType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: ArenaSpacing.xs,
      runSpacing: ArenaSpacing.xs,
      children: [
        for (final g in GameType.values)
          _OptionChip(
            label: g.label,
            active: g == current,
            onTap: () => onChanged(g),
          ),
      ],
    );
  }
}

class _FormatPicker extends StatelessWidget {
  const _FormatPicker({required this.current, required this.onChanged});
  final TournamentFormat current;
  final ValueChanged<TournamentFormat> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final f in TournamentFormat.values)
          Padding(
            padding: const EdgeInsets.only(bottom: ArenaSpacing.xs),
            child: ArenaButton(
              label: _CreateCompetitionPageState._formatLabel(f).toUpperCase(),
              variant: f == current
                  ? ArenaButtonVariant.primary
                  : ArenaButtonVariant.secondary,
              fullWidth: true,
              onPressed: () => onChanged(f),
            ),
          ),
      ],
    );
  }
}

class _MaxPlayersPicker extends StatelessWidget {
  const _MaxPlayersPicker({required this.current, required this.onChanged});
  final int current;
  final ValueChanged<int> onChanged;

  static const _options = [8, 16, 32, 64];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: ArenaSpacing.xs,
      runSpacing: ArenaSpacing.xs,
      children: [
        for (final n in _options)
          _OptionChip(
            label: '$n',
            active: n == current,
            onTap: () => onChanged(n),
          ),
      ],
    );
  }
}

class _CurrencyPicker extends StatelessWidget {
  const _CurrencyPicker({required this.current, required this.onChanged});
  final String current;
  final ValueChanged<String> onChanged;

  static const _options = ['XAF', 'XOF', 'USD'];

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: current,
      decoration: InputDecoration(
        filled: true,
        fillColor: ArenaColors.carbon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ArenaRadius.md),
          borderSide: const BorderSide(color: ArenaColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ArenaRadius.md),
          borderSide: const BorderSide(color: ArenaColors.border),
        ),
      ),
      dropdownColor: ArenaColors.carbon,
      style: ArenaText.body,
      items: [
        for (final c in _options)
          DropdownMenuItem(value: c, child: Text(c, style: ArenaText.body)),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

class _OptionChip extends StatelessWidget {
  const _OptionChip({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ArenaRadius.round),
      child: AnimatedContainer(
        duration: ArenaDurations.short,
        padding: const EdgeInsets.symmetric(
          horizontal: ArenaSpacing.md,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: active
              ? ArenaColors.signalBlue.withValues(alpha: 0.15)
              : ArenaColors.carbon,
          borderRadius: BorderRadius.circular(ArenaRadius.round),
          border: Border.all(
            color: active ? ArenaColors.signalBlue : ArenaColors.border,
          ),
        ),
        child: Text(
          label,
          style: ArenaText.body.copyWith(
            color: active ? ArenaColors.signalBlue : ArenaColors.silver,
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _PrizeModeCard extends StatelessWidget {
  const _PrizeModeCard({required this.mode, required this.onChanged});

  final _PrizeMode mode;
  final ValueChanged<_PrizeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: BoxDecoration(
        color: ArenaColors.carbon,
        borderRadius: BorderRadius.circular(ArenaRadius.lg),
        border: Border.all(color: ArenaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MODE DE DISTRIBUTION', style: ArenaText.inputLabel),
          const SizedBox(height: ArenaSpacing.sm),
          Row(
            children: [
              Expanded(
                child: ArenaButton(
                  label: '% POURCENTAGE',
                  variant: mode == _PrizeMode.percentage
                      ? ArenaButtonVariant.primary
                      : ArenaButtonVariant.secondary,
                  fullWidth: true,
                  onPressed: () => onChanged(_PrizeMode.percentage),
                ),
              ),
              const SizedBox(width: ArenaSpacing.xs),
              Expanded(
                child: ArenaButton(
                  label: '💰 MONTANTS FIXES',
                  variant: mode == _PrizeMode.fixed
                      ? ArenaButtonVariant.primary
                      : ArenaButtonVariant.secondary,
                  fullWidth: true,
                  onPressed: () => onChanged(_PrizeMode.fixed),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShareRow extends StatelessWidget {
  const _ShareRow({
    required this.position,
    required this.controller,
    required this.mode,
    required this.onChanged,
  });

  final int position;
  final TextEditingController controller;
  final _PrizeMode mode;
  final VoidCallback onChanged;

  static const _emojis = ['🥇', '🥈', '🥉', '4️⃣'];
  static const _labels = ['1ère', '2e', '3e', '4e'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_emojis[position]} ${_labels[position]} place',
          style: ArenaText.inputLabel,
        ),
        const SizedBox(height: ArenaSpacing.xs),
        ArenaTextField(
          controller: controller,
          hint: mode == _PrizeMode.percentage ? '%' : 'Montant',
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
            LengthLimitingTextInputFormatter(7),
          ],
          onChanged: (_) => onChanged(),
        ),
      ],
    );
  }
}

class _ShareTotalCard extends StatelessWidget {
  const _ShareTotalCard({
    required this.controllers,
    required this.mode,
  });
  final List<TextEditingController> controllers;
  final _PrizeMode mode;

  @override
  Widget build(BuildContext context) {
    final total =
        controllers.map((c) => int.tryParse(c.text) ?? 0).reduce((a, b) => a + b);

    final isPct = mode == _PrizeMode.percentage;
    final valid = !isPct || total == 100;

    return Container(
      padding: const EdgeInsets.all(ArenaSpacing.md),
      decoration: valid
          ? arenaSuccessCardDecoration()
          : arenaDangerCardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: Text(
              valid ? '✓ Total' : '⚠ Total invalide',
              style: ArenaText.body.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            isPct ? '$total%' : '$total',
            style: ArenaText.mono.copyWith(
              color: valid ? ArenaColors.statusOk : ArenaColors.neonRed,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: ArenaText.bodyMuted)),
          Text(value, style: ArenaText.body),
        ],
      ),
    );
  }
}
