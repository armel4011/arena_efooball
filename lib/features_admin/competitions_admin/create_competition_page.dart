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
import 'package:arena/features_admin/competitions_admin/widgets/wizard_step_prizes.dart';
import 'package:arena/features_admin/competitions_admin/widgets/wizard_step_review.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:arena/features_shared/competition_description_templates.dart';
import 'package:arena/features_shared/payment_code_templates.dart';
import 'package:arena/features_shared/prize_ranks.dart';
import 'package:arena/features_shared/reward_config_templates.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/features_shared/widgets/arena_stepper.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'create_competition_dialogs.dart';
part 'create_competition_submit.dart';

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
  // Dernier modèle de description appliqué automatiquement. Sert à savoir
  // si l'admin a personnalisé le texte : on ne ré-écrase la description au
  // changement de jeu QUE si elle est encore strictement égale à ce modèle
  // (ou vide). Tout texte tapé à la main est préservé.
  String _appliedDescTemplate = '';
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
  // bloc. Dimensionné sur `prizeBlocks` pour rester aligné si on ajoute un
  // palier.
  final List<TextEditingController> _blockShareCtrls = List.generate(
    prizeBlocks.length,
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
    if (c == null) {
      // Mode création : pré-remplit la description avec le pitch standard
      // du jeu par défaut (le champ est vide au démarrage).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _descCtrl.text.trim().isNotEmpty) return;
        setState(() {
          _appliedDescTemplate = kDefaultDescriptionTemplates[_game] ?? '';
          _descCtrl.text = _appliedDescTemplate;
        });
      });
      return;
    }
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
    for (var b = 0; b < prizeBlocks.length; b++) {
      final block = prizeBlocks[b];
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
                        savedCount: ref
                                .watch(competitionDescTemplatesProvider)
                                .valueOrNull
                                ?.saved
                                .length ??
                            0,
                        onChanged: () => setState(() {}),
                        onGameChanged: _onGameChanged,
                        onPickStartDate: _pickStartDate,
                        onInsertStandard: _insertStandardDesc,
                        onSaveTemplate: _saveDescTemplate,
                        onOpenLibrary: _openTemplateLibrary,
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
                    if (_step == 2)
                      WizardStepPrizes(
                        rewardedCount: _rewardedCount,
                        currency: _currency,
                        topShareCtrls: _topShareCtrls,
                        blockShareCtrls: _blockShareCtrls,
                        shareTotal: _shareTotal(),
                        onRewardedCountChanged: _setRewardedCount,
                        onChanged: () => setState(() {}),
                        savedConfigCount: ref
                                .watch(rewardConfigTemplatesProvider)
                                .valueOrNull
                                ?.saved
                                .length ??
                            0,
                        onSaveConfig: _saveRewardConfig,
                        onOpenConfigLibrary: _openRewardLibrary,
                      ),
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
                        savedCodeCount: ref
                                .watch(paymentCodeTemplatesProvider)
                                .valueOrNull
                                ?.saved
                                .length ??
                            0,
                        onSaveCodes: _savePaymentCodes,
                        onOpenCodeLibrary: _openPaymentCodeLibrary,
                      ),
                    if (_step == 4)
                      WizardStepReview(
                        name: _nameCtrl.text.trim(),
                        gameLabel: _game.label,
                        format: _format,
                        maxPlayers: _maxPlayers,
                        startDate: _startDate,
                        fee: double.tryParse(_entryFeeCtrl.text) ?? 0,
                        currency: _currency,
                        pool: _computedPool(),
                        commissionXaf: _commissionXaf(),
                        autoGenerateBracket: _autoGenerateBracket,
                        matchIntervalMinutes: _matchIntervalMinutes,
                        thirdPlaceMatch: _thirdPlaceMatch,
                        referralQuota: _referralQuota(),
                        isEditing: _isEditing,
                        publishNow: _publishNow,
                        submitting: _submitting,
                        onPublishChanged: (v) =>
                            setState(() => _publishNow = v),
                      ),
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

  // ─── Submit ───────────────────────────────────────────────────────
  // `_submit` / `_submitEdit` vivent dans l'extension de
  // `create_competition_submit.dart` (part of cette librairie). `setState`
  // étant @protected (réservé aux sous-classes de State, pas aux extensions),
  // l'extension passe par ce helper pour basculer l'état de soumission.
  void _setSubmitting(bool value) => setState(() => _submitting = value);

  /// Changement de jeu (mode création seulement). En plus de mettre à jour
  /// `_game`, on bascule la description sur le pitch standard du nouveau jeu —
  /// mais uniquement si l'admin n'a pas personnalisé le texte (champ vide ou
  /// encore égal au modèle précédemment appliqué).
  void _onGameChanged(GameType g) {
    setState(() {
      final current = _descCtrl.text.trim();
      _game = g;
      if (current.isEmpty || _descCtrl.text == _appliedDescTemplate) {
        _appliedDescTemplate = kDefaultDescriptionTemplates[g] ?? '';
        _descCtrl.text = _appliedDescTemplate;
      }
    });
  }

  /// Insère le pitch standard du jeu courant dans la description.
  void _insertStandardDesc() {
    setState(() {
      _appliedDescTemplate = kDefaultDescriptionTemplates[_game] ?? '';
      _descCtrl.text = _appliedDescTemplate;
    });
  }

  /// Enregistre la description courante comme nouveau modèle nommé. Demande
  /// d'abord un nom à l'admin via une boîte de dialogue.
  Future<void> _saveDescTemplate() async {
    final text = _descCtrl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La description est vide.')),
      );
      return;
    }
    final name = await _promptTemplateName();
    if (name == null || name.trim().isEmpty) return;
    try {
      await ref
          .read(competitionDescTemplatesProvider.notifier)
          .saveTemplate(name.trim(), text);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Échec de l'enregistrement du modèle : $e")),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _appliedDescTemplate = text);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Modèle « ${name.trim()} » enregistré.')),
    );
  }

  /// Boîte de dialogue qui demande le nom d'un nouveau modèle. Déléguée à un
  /// StatefulWidget qui possède son controller (disposé au bon moment) — sinon
  /// disposer le controller à la fermeture casse l'arbre (`_dependents`).
  Future<String?> _promptTemplateName() => showDialog<String>(
        context: context,
        builder: (_) => const _TemplateNameDialog(),
      );

  /// Ouvre la bibliothèque de modèles enregistrés : choisir pour insérer,
  /// ou supprimer. Présentée en bottom sheet.
  Future<void> _openTemplateLibrary() async {
    final templates = ref.read(competitionDescTemplatesProvider).valueOrNull;
    if (templates == null || templates.saved.isEmpty) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: ArenaColors.surface,
      isScrollControlled: true,
      builder: (ctx) => _TemplateLibrarySheet(
        initial: templates.saved,
        onInsert: (tpl) {
          Navigator.of(ctx).pop();
          setState(() {
            _appliedDescTemplate = tpl.text;
            _descCtrl.text = tpl.text;
          });
        },
        onDelete: (tpl) => ref
            .read(competitionDescTemplatesProvider.notifier)
            .deleteTemplate(tpl.name),
      ),
    );
  }

  /// Enregistre la répartition de prix courante comme config nommée réutilisable.
  Future<void> _saveRewardConfig() async {
    final name = await _promptTemplateName();
    if (name == null || name.trim().isEmpty) return;
    final tpl = RewardConfigTemplate(
      name: name.trim(),
      rewardedCount: _rewardedCount,
      topShares: [for (final c in _topShareCtrls) int.tryParse(c.text) ?? 0],
      blockShares: [for (final c in _blockShareCtrls) int.tryParse(c.text) ?? 0],
    );
    try {
      await ref.read(rewardConfigTemplatesProvider.notifier).saveTemplate(tpl);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Échec de l'enregistrement : $e")),
      );
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Config « ${name.trim()} » enregistrée.')),
    );
  }

  /// Ouvre la bibliothèque de configs de récompense : appliquer ou supprimer.
  Future<void> _openRewardLibrary() async {
    final templates = ref.read(rewardConfigTemplatesProvider).valueOrNull;
    if (templates == null || templates.saved.isEmpty) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: ArenaColors.surface,
      isScrollControlled: true,
      builder: (ctx) => _RewardLibrarySheet(
        initial: templates.saved,
        currency: _currency,
        onApply: (tpl) {
          Navigator.of(ctx).pop();
          setState(() {
            _rewardedCount = tpl.rewardedCount.clamp(1, kMaxRewardedRanks);
            for (var i = 0; i < _topShareCtrls.length; i++) {
              _topShareCtrls[i].text =
                  (i < tpl.topShares.length ? tpl.topShares[i] : 0).toString();
            }
            for (var b = 0; b < _blockShareCtrls.length; b++) {
              _blockShareCtrls[b].text =
                  (b < tpl.blockShares.length ? tpl.blockShares[b] : 0)
                      .toString();
            }
          });
        },
        onDelete: (tpl) => ref
            .read(rewardConfigTemplatesProvider.notifier)
            .deleteTemplate(tpl.name),
      ),
    );
  }

  /// Enregistre la paire de codes marchands courante comme jeu nommé.
  Future<void> _savePaymentCodes() async {
    final orange = _orangeMomoCtrl.text.trim();
    final mtn = _mtnMomoCtrl.text.trim();
    if (orange.isEmpty && mtn.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saisis au moins un code à enregistrer.')),
      );
      return;
    }
    final name = await _promptTemplateName();
    if (name == null || name.trim().isEmpty) return;
    try {
      await ref.read(paymentCodeTemplatesProvider.notifier).saveTemplate(
            PaymentCodeTemplate(
              name: name.trim(),
              orangeCode: orange,
              mtnCode: mtn,
            ),
          );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Échec de l'enregistrement : $e")),
      );
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Codes « ${name.trim()} » enregistrés.')),
    );
  }

  /// Ouvre la bibliothèque de jeux de codes marchands : appliquer ou supprimer.
  Future<void> _openPaymentCodeLibrary() async {
    final templates = ref.read(paymentCodeTemplatesProvider).valueOrNull;
    if (templates == null || templates.saved.isEmpty) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: ArenaColors.surface,
      isScrollControlled: true,
      builder: (ctx) => _PaymentCodeLibrarySheet(
        initial: templates.saved,
        onApply: (tpl) {
          Navigator.of(ctx).pop();
          setState(() {
            _orangeMomoCtrl.text = tpl.orangeCode;
            _mtnMomoCtrl.text = tpl.mtnCode;
          });
        },
        onDelete: (tpl) => ref
            .read(paymentCodeTemplatesProvider.notifier)
            .deleteTemplate(tpl.name),
      ),
    );
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
    for (var b = 0; b < prizeBlocks.length; b++) {
      final block = prizeBlocks[b];
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
    for (var b = 0; b < prizeBlocks.length; b++) {
      final block = prizeBlocks[b];
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
