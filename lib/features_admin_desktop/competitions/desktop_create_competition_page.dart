import 'package:arena/core/router/admin_desktop_router.dart';
import 'package:arena/core/theme/arena_fluent_theme.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/utils/arena_error_message.dart';
import 'package:arena/data/models/competition.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/data/repositories/admin/admin_audit_log_repository.dart';
import 'package:arena/data/repositories/admin/admin_competitions_repository.dart';
import 'package:arena/features_admin_desktop/competitions/desktop_competition_visuals.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:arena/features_shared/prize_ranks.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// Blocs de récompenses au-delà du top 4 : (libellé, taille, dernier
/// rang). Identique au wizard mobile.
const List<({String label, int size, int lastRank})> _prizeBlocks = [
  (label: '5ème – 8ème', size: 4, lastRank: 8),
  (label: '9ème – 16ème', size: 8, lastRank: 16),
  (label: '17ème – 32ème', size: 16, lastRank: 32),
  (label: '33ème – 64ème', size: 32, lastRank: 64),
  (label: '65ème – 128ème', size: 64, lastRank: 128),
];

const List<String> _currencies = ['XAF', 'XOF', 'USD'];
const List<int> _maxPlayersOptions = [2, 4, 8, 16, 32, 64, 128, 256, 512];
const List<int> _intervalOptions = [30, 60, 120, 240, 1440];

/// Wizard desktop de création / édition de compétition — layout 2
/// colonnes : liste verticale d'étapes cliquables à gauche, formulaire
/// de l'étape courante à droite.
///
/// Réutilise [AdminCompetitionsRepository] (create / update) et
/// [adminAuditLogRepositoryProvider]. Même logique de soumission que le
/// wizard mobile (`CreateCompetitionPage`).
class DesktopCreateCompetitionPage extends ConsumerStatefulWidget {
  const DesktopCreateCompetitionPage({this.editing, super.key});

  /// Compétition à modifier — `null` en mode création.
  final Competition? editing;

  @override
  ConsumerState<DesktopCreateCompetitionPage> createState() =>
      _DesktopCreateCompetitionPageState();
}

class _DesktopCreateCompetitionPageState
    extends ConsumerState<DesktopCreateCompetitionPage> {
  static const _stepCount = 5;
  int _step = 0;
  bool _submitting = false;
  String? _error;

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
  final _commissionXafCtrl = TextEditingController(text: '0');
  final List<TextEditingController> _topShareCtrls = [
    TextEditingController(text: '50'),
    TextEditingController(text: '25'),
    TextEditingController(text: '15'),
    TextEditingController(text: '10'),
  ];
  // Dimensionné sur `_prizeBlocks` pour suivre l'ajout d'un palier (65-128).
  final List<TextEditingController> _blockShareCtrls = List.generate(
    _prizeBlocks.length,
    (_) => TextEditingController(text: '0'),
  );
  int _rewardedCount = 4;
  bool _publishNow = true;
  bool _autoGenerateBracket = true;
  int _matchIntervalMinutes = 60;
  bool _thirdPlaceMatch = false;
  final _referralQuotaCtrl = TextEditingController(text: '0');
  final _roundIntervalsCtrl = TextEditingController();
  final _groupCountCtrl = TextEditingController(text: '4');
  final _qualifiersPerGroupCtrl = TextEditingController(text: '2');
  final _androidStoreUrlCtrl = TextEditingController();
  final _iosStoreUrlCtrl = TextEditingController();

  bool get _isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final c = widget.editing;
    if (c == null) return;
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
        return true;
      case 3:
        final fee = double.tryParse(_entryFeeCtrl.text) ?? -1;
        if (fee < 0) return false;
        if (fee > 0) {
          if (_orangeMomoCtrl.text.trim().isEmpty) return false;
          if (_mtnMomoCtrl.text.trim().isEmpty) return false;
        }
        return true;
      default:
        return true;
    }
  }

  static const _stepTitles = ['Infos', 'Format', 'Récompenses', 'Frais', 'Récap'];

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(
        title: Text(
          _isEditing ? 'MODIFIER LA COMPÉTITION' : 'NOUVELLE COMPÉTITION',
        ),
      ),
      content: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ArenaDesktop.pagePadding,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 240,
              child: _StepsRail(
                steps: _stepTitles,
                current: _step,
                onTap: (i) => setState(() => _step = i),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(child: _buildRightPanel()),
          ],
        ),
      ),
    );
  }

  Widget _buildRightPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(right: 8, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null) ...[
                  InfoBar(
                    title: const Text('Échec de la soumission'),
                    content: Text(_error!),
                    severity: InfoBarSeverity.error,
                    onClose: () => setState(() => _error = null),
                  ),
                  const SizedBox(height: 16),
                ],
                _stepContent(),
              ],
            ),
          ),
        ),
        const Divider(),
        const SizedBox(height: 12),
        Row(
          children: [
            Button(
              onPressed: _step > 0 ? () => setState(() => _step--) : null,
              child: const Text('← Retour'),
            ),
            const Spacer(),
            if (_submitting)
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: ProgressRing(strokeWidth: 2.5),
                ),
              ),
            FilledButton(
              onPressed: !_canAdvance || _submitting
                  ? null
                  : (_step < _stepCount - 1
                      ? () => setState(() => _step++)
                      : _submit),
              child: Text(_nextLabel()),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  String _nextLabel() {
    if (_step < _stepCount - 1) return 'Suivant →';
    if (_isEditing) return 'Enregistrer';
    return _publishNow ? 'Créer et publier' : 'Sauver en brouillon';
  }

  Widget _stepContent() {
    switch (_step) {
      case 0:
        return _buildInfosStep();
      case 1:
        return _buildFormatStep();
      case 2:
        return _buildPrizesStep();
      case 3:
        return _buildFeesStep();
      default:
        return _buildReviewStep();
    }
  }

  // ─── Étape 0 — Infos ────────────────────────────────────────────────

  Widget _buildInfosStep() {
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
              onChanged: (v) => setState(() => _game = v ?? _game),
            ),
          ),
        ),
        const SizedBox(height: 16),
        InfoLabel(
          label: 'Description (optionnel)',
          child: TextBox(
            controller: _descCtrl,
            placeholder: 'Petite phrase de pitch…',
            maxLines: 3,
          ),
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
                'android_store_url': _emptyToNull(_androidStoreUrlCtrl.text),
                'ios_store_url': _emptyToNull(_iosStoreUrlCtrl.text),
              },
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
          'android_store_url': _emptyToNull(_androidStoreUrlCtrl.text),
          'ios_store_url': _emptyToNull(_iosStoreUrlCtrl.text),
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

  static String _intervalLabel(int minutes) {
    if (minutes < 60) return '$minutes min';
    if (minutes < 1440) return '${minutes ~/ 60} h';
    final d = minutes ~/ 1440;
    return d == 1 ? '1 jour' : '$d jours';
  }

  /// Grise + désactive un champ verrouillé en mode édition.
  Widget _lockable(Widget child) {
    if (!_isEditing) return child;
    return IgnorePointer(child: Opacity(opacity: 0.45, child: child));
  }
}

// ─────────────────────────────────────────────────────────────────────
// Widgets privés
// ─────────────────────────────────────────────────────────────────────

class _StepsRail extends StatelessWidget {
  const _StepsRail({
    required this.steps,
    required this.current,
    required this.onTap,
  });

  final List<String> steps;
  final int current;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      backgroundColor: ArenaColors.carbon,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < steps.length; i++)
            _StepTile(
              index: i,
              label: steps[i],
              active: i == current,
              done: i < current,
              onTap: () => onTap(i),
            ),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.index,
    required this.label,
    required this.active,
    required this.done,
    required this.onTap,
  });

  final int index;
  final String label;
  final bool active;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = active ? ArenaColors.neonRed : ArenaColors.silver;
    return HoverButton(
      onPressed: onTap,
      builder: (context, states) {
        final hovered = states.isHovered;
        return Container(
          color: active
              ? ArenaColors.neonRed.withValues(alpha: 0.10)
              : hovered
                  ? ArenaColors.carbon2
                  : ArenaColors.carbon,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done
                      ? ArenaColors.statusOk
                      : (active
                          ? ArenaColors.neonRed
                          : ArenaColors.carbon2),
                ),
                child: done
                    ? const Icon(
                        FluentIcons.accept,
                        size: 12,
                        color: ArenaColors.bone,
                      )
                    : Text(
                        '${index + 1}',
                        style: GoogleFonts.spaceGrotesk(
                          color: ArenaColors.bone,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  color: active ? ArenaColors.bone : accent,
                  fontSize: 14,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.bebasNeue(
          color: ArenaColors.bone,
          fontSize: 20,
          letterSpacing: 1,
        ),
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: ArenaColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                color: ArenaColors.silver,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              color: ArenaColors.bone,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
