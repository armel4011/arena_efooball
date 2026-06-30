import 'package:arena/core/services/anticheat/anticheat_config_service.dart';
import 'package:arena/core/services/anticheat/anticheat_provider.dart';
import 'package:arena/core/services/anticheat/anticheat_tiering_service.dart';
import 'package:arena/core/theme/arena_fluent_theme.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/utils/arena_error_message.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

/// Écran super-admin desktop : choisir le provider anti-triche actif
/// (`app_config.anticheat_provider`). Équivalent Fluent de SuperAdminAntiCheat.
class DesktopAntiCheatPage extends ConsumerStatefulWidget {
  const DesktopAntiCheatPage({super.key});

  @override
  ConsumerState<DesktopAntiCheatPage> createState() =>
      _DesktopAntiCheatPageState();
}

class _DesktopAntiCheatPageState extends ConsumerState<DesktopAntiCheatPage> {
  AntiCheatProviderKind? _selected;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _selected = await ref.read(antiCheatConfigServiceProvider).fetch();
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
      _success = null;
    });
    try {
      await ref.read(antiCheatConfigServiceProvider).setActive(kind);
      ref.invalidate(activeAntiCheatProviderProvider);
      if (mounted) setState(() => _success = 'Provider enregistré.');
    } catch (e) {
      if (mounted) setState(() => _error = 'Échec : $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: const PageHeader(title: Text('ANTI-TRICHE')),
      content: _loading
          ? const Center(child: ProgressRing())
          : Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ArenaDesktop.pagePadding,
              ),
              child: ListView(
                children: [
                  Text(
                    'Choisis le système qui enregistre le gameplay des joueurs '
                    'comme preuve. Les deux coexistent ; le recorder natif reste '
                    "le filet de sécurité. Le changement ne s'applique qu'aux "
                    'NOUVEAUX matchs.',
                    style: GoogleFonts.spaceGrotesk(color: ArenaColors.silver),
                  ),
                  const SizedBox(height: 16),
                  _OptionRow(
                    label: 'LiveKit Track Egress (recommandé)',
                    subtitle: 'Capture cloud publish-only + enregistrement '
                        'serveur (1 piste vidéo / joueur).',
                    selected:
                        _selected == AntiCheatProviderKind.livekitTrackEgress,
                    onTap: () => setState(
                      () =>
                          _selected = AntiCheatProviderKind.livekitTrackEgress,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _OptionRow(
                    label: 'Enregistrement natif (écran)',
                    subtitle: 'Recorder MediaProjection embarqué. Filet de '
                        'sécurité historique, Android uniquement.',
                    selected: _selected == AntiCheatProviderKind.nativeRecorder,
                    onTap: () => setState(
                      () => _selected = AntiCheatProviderKind.nativeRecorder,
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    InfoBar(
                      title: const Text('Erreur'),
                      content: Text(_error!),
                      severity: InfoBarSeverity.error,
                    ),
                  ],
                  if (_success != null) ...[
                    const SizedBox(height: 12),
                    InfoBar(
                      title: const Text('OK'),
                      content: Text(_success!),
                      severity: InfoBarSeverity.success,
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? 'ENREGISTREMENT…' : 'ENREGISTRER'),
                  ),
                  const SizedBox(height: 28),
                  const _TieringThresholdsCard(),
                ],
              ),
            ),
    );
  }
}

/// Réglage des seuils de tiering anti-triche (P4, équivalent Fluent du mobile).
/// Pilote la fraction de matchs egressés en LiveKit = egress concurrents =
/// capacité de matchs simultanés. Sans effet sous le provider natif.
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
  String? _success;

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
        _success = null;
        _error =
            'Valeurs invalides : cagnotte ≥ 0, strikes ≥ 1, taux entre 0 et 1.';
      });
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
      _success = null;
    });
    try {
      await ref.read(antiCheatTieringServiceProvider).save(
            AntiCheatTieringConfig(
              prizeThreshold: prize,
              strikeThreshold: strike,
              sampleRate: sample,
            ),
          );
      ref.invalidate(antiCheatTieringConfigProvider);
      if (mounted) setState(() => _success = 'Seuils de tiering enregistrés.');
    } catch (e) {
      if (mounted) setState(() => _error = 'Échec : ${arenaErrorMessage(e)}');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: ProgressRing());
    }
    return Card(
      backgroundColor: ArenaColors.carbon,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SEUILS DE TIERING (egress LiveKit)',
            style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Décide quels matchs reçoivent un egress LiveKit (1 joueur tiré au '
            'hasard) plutôt que le seul commitment hash. Seuils hauts / taux bas '
            "→ moins d'egress concurrents → plus de matchs simultanés. Sans "
            'effet sous le provider natif.',
            style: GoogleFonts.spaceGrotesk(
              color: ArenaColors.silver,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          InfoLabel(
            label: 'Cagnotte minimale (devise locale)',
            child: TextBox(
              controller: _prizeCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[0-9.]')),
              ],
            ),
          ),
          const SizedBox(height: 12),
          InfoLabel(
            label: 'Verdicts coupables (surveillance)',
            child: TextBox(
              controller: _strikeCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ),
          const SizedBox(height: 12),
          InfoLabel(
            label: "Taux d'échantillon aléatoire (0–1)",
            child: TextBox(
              controller: _sampleCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[0-9.]')),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            InfoBar(
              title: const Text('Erreur'),
              content: Text(_error!),
              severity: InfoBarSeverity.error,
            ),
          ],
          if (_success != null) ...[
            const SizedBox(height: 12),
            InfoBar(
              title: const Text('OK'),
              content: Text(_success!),
              severity: InfoBarSeverity.success,
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'ENREGISTREMENT…' : 'ENREGISTRER LES SEUILS'),
          ),
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: onTap,
      style: ButtonStyle(
        backgroundColor: selected
            ? WidgetStatePropertyAll(ArenaColors.iceCyan.withValues(alpha: 0.12))
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected
                  ? FluentIcons.radio_btn_on
                  : FluentIcons.radio_btn_off,
              color: selected ? ArenaColors.iceCyan : ArenaColors.silver,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.spaceGrotesk(
                      color: ArenaColors.silver,
                      fontSize: 12,
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
}
