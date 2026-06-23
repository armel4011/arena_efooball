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
import 'package:arena/features_shared/competition_description_templates.dart';
import 'package:arena/features_shared/prize_ranks.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

part 'desktop_create_competition_widgets.dart';
part 'desktop_create_competition_steps.dart';
part 'desktop_create_competition_logic.dart';

/// Blocs de récompenses au-delà du top 4 : (libellé, taille, dernier
/// rang). Identique au wizard mobile.
const List<({String label, int size, int lastRank})> _prizeBlocks = [
  (label: '5ème – 8ème', size: 4, lastRank: 8),
  (label: '9ème – 16ème', size: 8, lastRank: 16),
  (label: '17ème – 32ème', size: 16, lastRank: 32),
  (label: '33ème – 64ème', size: 32, lastRank: 64),
  (label: '65ème – 128ème', size: 64, lastRank: 128),
];

// V1.0 : paiement d'inscription disponible UNIQUEMENT au Cameroun (XAF).
// XOF / USD (autres pays) reviendront dans une version ultérieure.
const List<String> _currencies = ['XAF'];
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
    extends ConsumerState<DesktopCreateCompetitionPage>
    with _SubmitAndCompute, _StepBuilders {
  static const _stepCount = 5;
  int _step = 0;
  @override
  bool _submitting = false;
  @override
  String? _error;

  // Form state ──────────────────────────────────────────────────────
  @override
  final _nameCtrl = TextEditingController();
  @override
  final _descCtrl = TextEditingController();
  @override
  GameType _game = GameType.efootball;
  @override
  TournamentFormat _format = TournamentFormat.singleElimination;
  @override
  int _maxPlayers = 16;
  @override
  DateTime? _startDate;
  @override
  final _entryFeeCtrl = TextEditingController(text: '0');
  @override
  final _orangeMomoCtrl = TextEditingController();
  @override
  final _mtnMomoCtrl = TextEditingController();
  @override
  String _currency = 'XAF';
  @override
  final _commissionXafCtrl = TextEditingController(text: '0');
  @override
  final List<TextEditingController> _topShareCtrls = [
    TextEditingController(text: '50'),
    TextEditingController(text: '25'),
    TextEditingController(text: '15'),
    TextEditingController(text: '10'),
  ];
  // Dimensionné sur `_prizeBlocks` pour suivre l'ajout d'un palier (65-128).
  @override
  final List<TextEditingController> _blockShareCtrls = List.generate(
    _prizeBlocks.length,
    (_) => TextEditingController(text: '0'),
  );
  @override
  int _rewardedCount = 4;
  @override
  bool _publishNow = true;
  @override
  bool _autoGenerateBracket = true;
  @override
  int _matchIntervalMinutes = 60;
  @override
  bool _customIntervalMode = false;
  @override
  final _customIntervalCtrl = TextEditingController();
  @override
  bool _thirdPlaceMatch = false;
  @override
  final _referralQuotaCtrl = TextEditingController(text: '0');
  @override
  final _roundIntervalsCtrl = TextEditingController();
  @override
  final _groupCountCtrl = TextEditingController(text: '4');
  @override
  final _qualifiersPerGroupCtrl = TextEditingController(text: '2');
  @override
  final _androidStoreUrlCtrl = TextEditingController();
  @override
  final _iosStoreUrlCtrl = TextEditingController();

  @override
  bool get _isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final c = widget.editing;
    if (c == null) {
      // Création : pré-remplit la description avec le pitch standard du jeu
      // par défaut (modifiable). Parité avec le wizard mobile.
      _descCtrl.text = kDefaultDescriptionTemplates[_game] ?? '';
      return;
    }
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
    _customIntervalMode = !_intervalOptions.contains(c.matchIntervalMinutes);
    if (_customIntervalMode) {
      _customIntervalCtrl.text = c.matchIntervalMinutes.toString();
    }
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
    _customIntervalCtrl.dispose();
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

}
