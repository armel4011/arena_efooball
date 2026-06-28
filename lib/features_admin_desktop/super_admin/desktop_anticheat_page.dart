import 'package:arena/core/services/anticheat/anticheat_config_service.dart';
import 'package:arena/core/services/anticheat/anticheat_provider.dart';
import 'package:arena/core/theme/arena_fluent_theme.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:fluent_ui/fluent_ui.dart';
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
                ],
              ),
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
