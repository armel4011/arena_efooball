import 'package:arena/core/theme/arena_fluent_theme.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/repositories/app_update_repository.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

/// Écran super-admin desktop : publie la config de MAJ in-app
/// (`app_release_config`). Équivalent Fluent de SuperAdminAppUpdate.
class DesktopAppUpdatePage extends ConsumerStatefulWidget {
  const DesktopAppUpdatePage({super.key});

  @override
  ConsumerState<DesktopAppUpdatePage> createState() =>
      _DesktopAppUpdatePageState();
}

class _DesktopAppUpdatePageState extends ConsumerState<DesktopAppUpdatePage> {
  final _version = TextEditingController();
  final _build = TextEditingController();
  final _apkUrl = TextEditingController();
  final _changelog = TextEditingController();
  final _minSupported = TextEditingController();
  bool _mandatory = false;

  String? _rowId;
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
    _version.dispose();
    _build.dispose();
    _apkUrl.dispose();
    _changelog.dispose();
    _minSupported.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final row =
          await ref.read(appUpdateRepositoryProvider).fetchAndroidConfigRow();
      if (row != null) {
        _rowId = row['id'] as String?;
        _version.text = (row['latest_version'] as String?) ?? '';
        _build.text = ((row['latest_build'] as int?) ?? 0).toString();
        _apkUrl.text = (row['apk_url'] as String?) ?? '';
        _changelog.text = (row['changelog'] as String?) ?? '';
        _minSupported.text = (row['min_supported_version'] as String?) ?? '';
        _mandatory = (row['mandatory'] as bool?) ?? false;
      }
    } catch (e) {
      _error = '$e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_version.text.trim().isEmpty || _apkUrl.text.trim().isEmpty) {
      setState(() => _error = "Version et URL de l'APK sont obligatoires.");
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
      _success = null;
    });
    try {
      await ref.read(appUpdateRepositoryProvider).upsertAndroidConfig(
            id: _rowId,
            latestVersion: _version.text,
            latestBuild: int.tryParse(_build.text.trim()) ?? 0,
            apkUrl: _apkUrl.text,
            changelog: _changelog.text,
            mandatory: _mandatory,
            minSupportedVersion: _minSupported.text.trim().isEmpty
                ? null
                : _minSupported.text,
          );
      if (mounted) setState(() => _success = 'Config publiée.');
    } catch (e) {
      if (mounted) setState(() => _error = 'Échec : $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: const PageHeader(title: Text('MISE À JOUR APP')),
      content: _loading
          ? const Center(child: ProgressRing())
          : Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ArenaDesktop.pagePadding,
              ),
              child: ListView(
                children: [
                  Text(
                    'Publie la dernière version proposée aux utilisateurs '
                    '(distribution APK hors Play Store).',
                    style: GoogleFonts.spaceGrotesk(color: ArenaColors.silver),
                  ),
                  const SizedBox(height: 16),
                  _field('Version publiée (ex 1.1.0)', _version, '1.1.0'),
                  _field('Build (versionCode, informatif)', _build, '11'),
                  _field(
                    "URL de l'APK",
                    _apkUrl,
                    'https://arena237.com/downloads/arena-android-universel.apk',
                  ),
                  _field(
                    'Notes de version',
                    _changelog,
                    'Nouveautés…',
                    maxLines: 6,
                  ),
                  const SizedBox(height: 8),
                  ToggleSwitch(
                    checked: _mandatory,
                    onChanged: (v) => setState(() => _mandatory = v),
                    content: const Text('Mise à jour obligatoire'),
                  ),
                  if (_mandatory)
                    _field(
                      'Version minimale supportée (ex 1.0.5)',
                      _minSupported,
                      '1.0.5',
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 12,
                      ),
                      child: Text(_saving ? 'Publication…' : 'Publier'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl,
    String placeholder, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              color: ArenaColors.silver,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          TextBox(
            controller: ctrl,
            placeholder: placeholder,
            maxLines: maxLines,
            minLines: 1,
          ),
        ],
      ),
    );
  }
}
