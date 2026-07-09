import 'package:arena/core/services/anticheat/anticheat_config_service.dart';
import 'package:arena/core/services/anticheat/anticheat_provider.dart';
import 'package:arena/core/services/anticheat/anticheat_tiering_service.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/utils/arena_error_message.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_card.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Écran super-admin : choisir le provider anti-triche ACTIF
/// (`app_config.anticheat_provider`).
///
/// Système DUAL en coexistence — le recorder natif (filet de sécurité) n'est
/// jamais supprimé. Le changement n'est PAS rétroactif : les matchs déjà
/// enregistrés gardent leur provider d'origine.
class SuperAdminAntiCheat extends ConsumerStatefulWidget {
  const SuperAdminAntiCheat({super.key});

  @override
  ConsumerState<SuperAdminAntiCheat> createState() =>
      _SuperAdminAntiCheatState();
}

class _SuperAdminAntiCheatState extends ConsumerState<SuperAdminAntiCheat> {
  AntiCheatProviderKind? _selected;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final kind = await ref.read(antiCheatConfigServiceProvider).fetch();
      _selected = kind;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final kind = _selected;
    if (kind == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(antiCheatConfigServiceProvider).setActive(kind);
      // Rafraîchit les lecteurs du provider actif (cycle de vie du match).
      ref.invalidate(activeAntiCheatProviderProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Provider anti-triche enregistré.')),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Échec : $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ArenaAppBar(title: 'ANTI-TRICHE'),
      body: ArenaScreenBackground(
        accent: ArenaColors.neonRed,
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(ArenaSpacing.lg),
                  children: [
                    Text(
                      'Choisis le système qui enregistre le gameplay des '
                      'joueurs comme preuve. Les deux coexistent ; le recorder '
                      'natif reste le filet de sécurité. Le changement ne '
                      "s'applique qu'aux NOUVEAUX matchs.",
                      style: ArenaText.bodyMuted,
                    ),
                    const SizedBox(height: ArenaSpacing.lg),
                    _ProviderTile(
                      title: 'LiveKit Track Egress (recommandé)',
                      subtitle:
                          'Capture cloud publish-only + enregistrement serveur '
                          '(1 piste vidéo / joueur). Robuste, ne dépend pas du '
                          'téléphone après le démarrage.',
                      selected:
                          _selected == AntiCheatProviderKind.livekitTrackEgress,
                      onTap: () => setState(
                        () => _selected =
                            AntiCheatProviderKind.livekitTrackEgress,
                      ),
                    ),
                    const SizedBox(height: ArenaSpacing.md),
                    _ProviderTile(
                      title: 'Enregistrement natif (écran)',
                      subtitle:
                          'Recorder MediaProjection embarqué (overlay, pause, '
                          'forfait, export galerie). Filet de sécurité '
                          'historique, Android uniquement.',
                      selected:
                          _selected == AntiCheatProviderKind.nativeRecorder,
                      onTap: () => setState(
                        () => _selected = AntiCheatProviderKind.nativeRecorder,
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: ArenaSpacing.md),
                      Text(
                        _error!,
                        style: ArenaText.small
                            .copyWith(color: ArenaColors.neonRed),
                      ),
                    ],
                    const SizedBox(height: ArenaSpacing.lg),
                    ArenaButton(
                      label: _saving ? 'ENREGISTREMENT…' : 'ENREGISTRER',
                      onPressed: _saving ? null : _save,
                      isLoading: _saving,
                    ),
                    const SizedBox(height: ArenaSpacing.xl),
                    const _TieringThresholdsCard(),
                    const SizedBox(height: ArenaSpacing.xl),
                    const _CostObservabilityCard(),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Réglage des seuils de tiering anti-triche (P4) : pilote la fraction de
/// matchs egressés en LiveKit (= egress concurrents = capacité de matchs
/// simultanés). N'a d'effet que sous le provider `livekit_track_egress`.
class _TieringThresholdsCard extends ConsumerStatefulWidget {
  const _TieringThresholdsCard();

  @override
  ConsumerState<_TieringThresholdsCard> createState() =>
      _TieringThresholdsCardState();
}

class _TieringThresholdsCardState
    extends ConsumerState<_TieringThresholdsCard> {
  final _prizeCtrl = TextEditingController();
  final _strikeCtrl = TextEditingController();
  final _sampleCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _prizeCtrl.dispose();
    _strikeCtrl.dispose();
    _sampleCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final cfg = await ref.read(antiCheatTieringServiceProvider).fetch();
    if (!mounted) return;
    setState(() {
      _prizeCtrl.text = _trim(cfg.prizeThreshold);
      _strikeCtrl.text = cfg.strikeThreshold.toString();
      _sampleCtrl.text = _trim(cfg.sampleRate);
      _loading = false;
    });
  }

  static String _trim(num v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  Future<void> _save() async {
    final prize = num.tryParse(_prizeCtrl.text.trim());
    final strike = int.tryParse(_strikeCtrl.text.trim());
    final sample = double.tryParse(_sampleCtrl.text.trim());
    if (prize == null || prize < 0 ||
        strike == null || strike < 1 ||
        sample == null || sample < 0 || sample > 1) {
      setState(() {
        _error =
            'Valeurs invalides : cagnotte ≥ 0, strikes ≥ 1, taux entre 0 et 1.';
      });
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(antiCheatTieringServiceProvider).save(
            AntiCheatTieringConfig(
              prizeThreshold: prize,
              strikeThreshold: strike,
              sampleRate: sample,
            ),
          );
      ref.invalidate(antiCheatTieringConfigProvider);
      messenger.showSnackBar(
        const SnackBar(content: Text('Seuils de tiering enregistrés.')),
      );
    } catch (e) {
      if (mounted) setState(() => _error = 'Échec : ${arenaErrorMessage(e)}');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ArenaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SEUILS DE TIERING (egress LiveKit)',
            style: ArenaText.body.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Décide quels matchs reçoivent un egress LiveKit (1 joueur tiré au '
            'hasard) plutôt que le seul commitment hash. Plus les seuils sont '
            "hauts / le taux bas, moins d'egress concurrents → plus de matchs "
            'simultanés. Sans effet sous le provider natif.',
            style: ArenaText.small.copyWith(color: ArenaColors.silver),
          ),
          const SizedBox(height: ArenaSpacing.md),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else ...[
            ArenaTextField(
              label: 'Cagnotte minimale (devise locale)',
              helper: 'Match dont la cagnotte ≥ ce seuil → egressé.',
              controller: _prizeCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[0-9.]')),
              ],
            ),
            const SizedBox(height: ArenaSpacing.md),
            ArenaTextField(
              label: 'Verdicts coupables (surveillance)',
              helper: 'Joueur ayant ≥ ce nombre de verdicts → ses matchs '
                  'egressés.',
              controller: _strikeCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: ArenaSpacing.md),
            ArenaTextField(
              label: "Taux d'échantillon aléatoire (0–1)",
              helper: '0.1 = 10 % des autres matchs egressés au hasard.',
              controller: _sampleCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[0-9.]')),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: ArenaSpacing.sm),
              Text(
                _error!,
                style: ArenaText.small.copyWith(color: ArenaColors.neonRed),
              ),
            ],
            const SizedBox(height: ArenaSpacing.md),
            ArenaButton(
              label: _saving ? 'ENREGISTREMENT…' : 'ENREGISTRER LES SEUILS',
              variant: ArenaButtonVariant.secondary,
              onPressed: _saving ? null : _save,
              isLoading: _saving,
            ),
          ],
        ],
      ),
    );
  }
}

/// Observabilité coût egress (P4 volet B) : chiffre le coût du tiering à partir
/// des décisions réelles (`match_anticheat_plans`) plutôt que d'une projection.
/// Vide tant que le provider natif est actif (aucun plan livekit créé).
class _CostObservabilityCard extends ConsumerStatefulWidget {
  const _CostObservabilityCard();

  @override
  ConsumerState<_CostObservabilityCard> createState() =>
      _CostObservabilityCardState();
}

class _CostObservabilityCardState
    extends ConsumerState<_CostObservabilityCard> {
  AnticheatCostWindow _window = AnticheatCostWindow.last30d;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(antiCheatCostSummaryProvider(_window));
    return ArenaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'COÛT EGRESS MESURÉ',
            style: ArenaText.body.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Chiffré depuis les décisions réelles de tiering. « Économie » = '
            "ce qu'aurait coûté l'egress des 2 pistes de chaque match sans "
            'le tiering + egress unique. Vide tant que le provider natif est '
            'actif (aucun egress).',
            style: ArenaText.small.copyWith(color: ArenaColors.silver),
          ),
          const SizedBox(height: ArenaSpacing.md),
          Row(
            children: [
              _WindowChip(
                label: '30 jours',
                selected: _window == AnticheatCostWindow.last30d,
                onTap: () =>
                    setState(() => _window = AnticheatCostWindow.last30d),
              ),
              const SizedBox(width: ArenaSpacing.sm),
              _WindowChip(
                label: 'Tout',
                selected: _window == AnticheatCostWindow.allTime,
                onTap: () =>
                    setState(() => _window = AnticheatCostWindow.allTime),
              ),
            ],
          ),
          const SizedBox(height: ArenaSpacing.md),
          async.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: ArenaSpacing.md),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text(
              'Chargement impossible.',
              style: ArenaText.small.copyWith(color: ArenaColors.neonRed),
            ),
            data: (s) => _CostSummaryBody(summary: s),
          ),
        ],
      ),
    );
  }
}

/// Corps chiffré du résumé de coût, partagé (contenu neutre plateforme).
class _CostSummaryBody extends StatelessWidget {
  const _CostSummaryBody({required this.summary});

  final AnticheatCostSummary summary;

  static String _usd(num v) => '\$${v.toStringAsFixed(v < 10 ? 3 : 2)}';

  @override
  Widget build(BuildContext context) {
    final s = summary;
    if (s.decided == 0) {
      return Text(
        "Aucun plan de tiering figé sur la période — système d'egress "
        'dormant.',
        style: ArenaText.small.copyWith(color: ArenaColors.silver),
      );
    }
    final pct = (s.livekitFraction * 100).toStringAsFixed(1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CostRow(label: 'Matchs décidés', value: '${s.decided}'),
        _CostRow(
          label: 'Egressés (LiveKit)',
          value: '${s.livekit}  ($pct %)',
        ),
        _CostRow(label: 'Natif seul (hash)', value: '${s.nativeOnly}'),
        const Divider(height: ArenaSpacing.lg),
        _CostRow(
          label: 'Coût egress réel estimé',
          value: _usd(s.actualCostUsd),
          strong: true,
        ),
        _CostRow(
          label: 'Sans tiering (2 pistes/match)',
          value: _usd(s.baselineCostUsd),
        ),
        _CostRow(
          label: 'Économie',
          value:
              '${_usd(s.savingsUsd)}  (−${s.savingsPct.toStringAsFixed(0)} %)',
          strong: true,
          highlight: true,
        ),
        if (s.livekit > 0) ...[
          const SizedBox(height: ArenaSpacing.md),
          Text(
            'RAISONS DES EGRESS',
            style: ArenaText.small.copyWith(
              color: ArenaColors.silver,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          _CostRow(label: 'Cagnotte élevée', value: '${s.prize}'),
          _CostRow(label: 'Sous surveillance', value: '${s.surveillance}'),
          _CostRow(label: 'Litige sur le match', value: '${s.dispute}'),
          _CostRow(label: 'Échantillon aléatoire', value: '${s.random}'),
        ],
        const SizedBox(height: ArenaSpacing.sm),
        Text(
          'Coût unitaire modélisé : ${_usd(s.costPerEgressUsd)} / egress '
          '(≈ 12 min, 1 piste).',
          style: ArenaText.small.copyWith(color: ArenaColors.silver),
        ),
      ],
    );
  }
}

class _CostRow extends StatelessWidget {
  const _CostRow({
    required this.label,
    required this.value,
    this.strong = false,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool strong;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final color = highlight ? ArenaColors.iceCyan : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: ArenaText.small.copyWith(
                color: ArenaColors.silver,
              ),
            ),
          ),
          const SizedBox(width: ArenaSpacing.md),
          Text(
            value,
            style: (strong ? ArenaText.body : ArenaText.small).copyWith(
              fontWeight: strong ? FontWeight.w700 : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _WindowChip extends StatelessWidget {
  const _WindowChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ArenaSpacing.md,
          vertical: ArenaSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected
              ? ArenaColors.iceCyan.withValues(alpha: 0.15)
              : Colors.transparent,
          border: Border.all(
            color: selected ? ArenaColors.iceCyan : ArenaColors.silver,
          ),
          borderRadius: BorderRadius.circular(ArenaRadius.sm),
        ),
        child: Text(
          label,
          style: ArenaText.small.copyWith(
            color: selected ? ArenaColors.iceCyan : ArenaColors.silver,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ProviderTile extends StatelessWidget {
  const _ProviderTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ArenaCard(
      onTap: onTap,
      borderColor: selected ? ArenaColors.iceCyan : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            selected
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color: selected ? ArenaColors.iceCyan : ArenaColors.silver,
          ),
          const SizedBox(width: ArenaSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: ArenaText.body.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: ArenaText.small.copyWith(color: ArenaColors.silver),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
