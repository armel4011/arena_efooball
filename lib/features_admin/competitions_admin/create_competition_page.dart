import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/utils/sentry_trace.dart';
import 'package:arena/data/models/competition.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/data/repositories/admin/admin_audit_log_repository.dart';
import 'package:arena/data/repositories/admin/admin_competitions_repository.dart';
import 'package:arena/features_admin/competitions_admin/widgets/wizard_step_country.dart';
import 'package:arena/features_admin/competitions_admin/widgets/wizard_step_fees.dart';
import 'package:arena/features_admin/competitions_admin/widgets/wizard_step_format.dart';
import 'package:arena/features_admin/competitions_admin/widgets/wizard_step_infos.dart';
import 'package:arena/features_admin/competitions_admin/widgets/wizard_step_prizes.dart';
import 'package:arena/features_admin/competitions_admin/widgets/wizard_step_review.dart';
import 'package:arena/features_shared/admin/competition_draft.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:arena/features_shared/competition_description_templates.dart';
import 'package:arena/features_shared/payment_operator_templates.dart';
import 'package:arena/features_shared/payment_option_draft.dart';
import 'package:arena/features_shared/prize_ranks.dart';
import 'package:arena/features_shared/prize_templates.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/features_shared/widgets/arena_stepper.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'create_competition_dialogs.dart';
part 'create_competition_submit.dart';
part 'create_competition_widgets.dart';

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
  static const _stepCount = 6;
  int _step = 0;
  bool _submitting = false;

  // Étape « Pays » ───────────────────────────────────────────────────
  // Pays organisateur (scoping admin) — `competitions.country_code`.
  String _countryCode = 'CM';
  // Options de paiement en cours d'édition, groupées par pays. Chaque
  // opérateur porte ses propres controllers (disposés dans dispose()).
  final List<PaymentDraftCountry> _paymentCountries = [];
  // Vrai tant que le préremplissage async des options (mode édition) est en
  // vol → l'étape Pays affiche un spinner.
  bool _paymentOptionsLoading = false;

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
  // Compétition sans aucune récompense (amicale) : prize_distribution vide,
  // cagnotte 0. Masque le barème dans le wizard.
  bool _noReward = false;
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
    _countryCode = c.countryCode;
    _entryFeeCtrl.text = c.registrationFee == c.registrationFee.roundToDouble()
        ? c.registrationFee.round().toString()
        : c.registrationFee.toString();
    _currency = c.registrationCurrency;
    // Préremplit l'éditeur d'options de paiement depuis le serveur (async).
    _loadPaymentOptions(c.id);
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
    // Distribution vide → compétition sans récompense (amicale).
    _noReward = dist.isEmpty;
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

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _entryFeeCtrl.dispose();
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
    for (final country in _paymentCountries) {
      country.dispose();
    }
    super.dispose();
  }

  /// Charge les options de paiement existantes (mode édition) et reconstruit
  /// les brouillons groupés par pays. Best-effort : en cas d'échec on laisse
  /// l'éditeur vide plutôt que de bloquer le wizard.
  Future<void> _loadPaymentOptions(String competitionId) async {
    setState(() => _paymentOptionsLoading = true);
    try {
      final options = await ref
          .read(adminCompetitionsRepositoryProvider)
          .fetchPaymentOptions(competitionId);
      if (!mounted) return;
      final drafts = paymentDraftsFromOptions(options);
      setState(() {
        _paymentCountries
          ..clear()
          ..addAll(drafts);
        _paymentOptionsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _paymentOptionsLoading = false);
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
                        noReward: _noReward,
                        onNoRewardChanged: (v) =>
                            setState(() => _noReward = v),
                        savedTemplateCount: ref
                                .watch(prizeTemplatesProvider)
                                .valueOrNull
                                ?.saved
                                .length ??
                            0,
                        onRewardedCountChanged: _setRewardedCount,
                        onChanged: () => setState(() {}),
                        onSaveTemplate: _savePrizeTemplate,
                        onOpenLibrary: _openPrizeLibrary,
                      ),
                    if (_step == 3)
                      WizardStepFees(
                        entryFeeCtrl: _entryFeeCtrl,
                        currency: _currency,
                        commissionXafCtrl: _commissionXafCtrl,
                        referralQuotaCtrl: _referralQuotaCtrl,
                        isEditing: _isEditing,
                        onChanged: () => setState(() {}),
                        onCurrencyChanged: (c) => setState(() => _currency = c),
                      ),
                    if (_step == 4)
                      WizardStepCountry(
                        organizerCountry: _countryCode,
                        onOrganizerChanged: (c) =>
                            setState(() => _countryCode = c),
                        isPaid: (double.tryParse(_entryFeeCtrl.text) ?? 0) > 0,
                        loading: _paymentOptionsLoading,
                        countries: _paymentCountries,
                        operatorTemplateCount: ref
                                .watch(paymentOperatorTemplatesProvider)
                                .valueOrNull
                                ?.saved
                                .length ??
                            0,
                        onAddCountry: _addPaymentCountry,
                        onRemoveCountry: _removePaymentCountry,
                        onCountryCodeChanged: _setPaymentCountryCode,
                        onAddOperator: _addPaymentOperator,
                        onRemoveOperator: _removePaymentOperator,
                        onSaveOperator: _savePaymentOperatorTemplate,
                        onOpenOperatorTemplates: _openPaymentOperatorTemplates,
                        onChanged: () => setState(() {}),
                      ),
                    if (_step == 5)
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

  // ─── Étape « Pays » — édition des options de paiement ─────────────
  void _addPaymentCountry() {
    setState(() {
      _paymentCountries.add(
        PaymentDraftCountry(
          countryCode: firstUnusedCountry(_paymentCountries),
        ),
      );
    });
  }

  void _removePaymentCountry(int countryIndex) {
    setState(() {
      _paymentCountries.removeAt(countryIndex).dispose();
    });
  }

  void _setPaymentCountryCode(int countryIndex, String code) {
    setState(() => _paymentCountries[countryIndex].countryCode = code);
  }

  void _addPaymentOperator(int countryIndex) {
    setState(() {
      _paymentCountries[countryIndex].operators.add(PaymentDraftOperator());
    });
  }

  void _removePaymentOperator(int countryIndex, int operatorIndex) {
    setState(() {
      _paymentCountries[countryIndex]
          .operators
          .removeAt(operatorIndex)
          .dispose();
    });
  }

  // ─── Modèles d'opérateurs réutilisables ───────────────────────────
  Future<void> _savePaymentOperatorTemplate(
    int countryIndex,
    int operatorIndex,
  ) async {
    final country = _paymentCountries[countryIndex];
    final op = country.operators[operatorIndex];
    final label = op.labelCtrl.text.trim();
    final code = op.codeCtrl.text.trim();
    final l10n = AppLocalizations.of(context);
    if (label.isEmpty || code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.countryOperatorEmptyToast)),
      );
      return;
    }
    await ref.read(paymentOperatorTemplatesProvider.notifier).saveTemplate(
          PaymentOperatorTemplate(
            countryCode: country.countryCode,
            operatorLabel: label,
            transferCode: code,
          ),
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.countryOperatorSavedToast)),
    );
  }

  Future<void> _openPaymentOperatorTemplates(int countryIndex) async {
    final saved =
        ref.read(paymentOperatorTemplatesProvider).valueOrNull?.saved ??
            const [];
    if (saved.isEmpty) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: ArenaColors.surface,
      isScrollControlled: true,
      builder: (ctx) => _NamedTemplateSheet(
        title: 'Mes opérateurs',
        subtitle: "Touche un opérateur pour l'ajouter à ce pays.",
        items: [
          for (final t in saved)
            (name: t.operatorLabel, preview: '${t.countryCode} · ${t.transferCode}'),
        ],
        onInsert: (i) {
          Navigator.of(ctx).pop();
          setState(() {
            _paymentCountries[countryIndex].operators.add(
              PaymentDraftOperator(
                label: saved[i].operatorLabel,
                code: saved[i].transferCode,
              ),
            );
          });
        },
        onDelete: (i) => ref
            .read(paymentOperatorTemplatesProvider.notifier)
            .deleteTemplate(saved[i]),
      ),
    );
  }

  // ─── Modèles de barème de récompenses ─────────────────────────────
  Future<void> _savePrizeTemplate() async {
    final name = await _promptTemplateName();
    if (name == null || name.trim().isEmpty) return;
    try {
      await ref.read(prizeTemplatesProvider.notifier).saveTemplate(
            name.trim(),
            _rewardedCount,
            [for (final c in _topShareCtrls) c.text.trim()],
            [for (final c in _blockShareCtrls) c.text.trim()],
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
      SnackBar(content: Text('Barème « ${name.trim()} » enregistré.')),
    );
  }

  Future<void> _openPrizeLibrary() async {
    final saved =
        ref.read(prizeTemplatesProvider).valueOrNull?.saved ?? const [];
    if (saved.isEmpty) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: ArenaColors.surface,
      isScrollControlled: true,
      builder: (ctx) => _NamedTemplateSheet(
        title: 'Mes barèmes de récompenses',
        subtitle: 'Touche un barème pour réappliquer le nombre de récompensés '
            'et les parts.',
        items: [for (final t in saved) (name: t.name, preview: t.preview)],
        onInsert: (i) {
          Navigator.of(ctx).pop();
          _applyPrizeTemplate(saved[i]);
        },
        onDelete: (i) => ref
            .read(prizeTemplatesProvider.notifier)
            .deleteTemplate(saved[i].name),
      ),
    );
  }

  void _applyPrizeTemplate(PrizeTemplate tpl) {
    setState(() {
      _rewardedCount = tpl.rewardedCount.clamp(1, kMaxRewardedRanks);
      for (var i = 0; i < _topShareCtrls.length; i++) {
        _topShareCtrls[i].text =
            i < tpl.topShares.length ? tpl.topShares[i] : '0';
      }
      for (var i = 0; i < _blockShareCtrls.length; i++) {
        _blockShareCtrls[i].text =
            i < tpl.blockShares.length ? tpl.blockShares[i] : '0';
      }
    });
  }

  /// Change le nombre de récompensés (1, 2, 4, 8, 16, 32, 64). Les
  /// contrôleurs sont fixes — seul [_rewardedCount] pilote ce qui
  /// s'affiche et entre dans le calcul.
  void _setRewardedCount(int count) {
    setState(() => _rewardedCount = count.clamp(1, kMaxRewardedRanks));
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
}
