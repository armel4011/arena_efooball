import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/repositories/app_update_repository.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_card.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:arena/features_shared/widgets/arena_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Écran super-admin : publier la version proposée en MAJ in-app
/// (table `app_release_config`). L'app user lit cette config au démarrage.
class SuperAdminAppUpdate extends ConsumerStatefulWidget {
  const SuperAdminAppUpdate({super.key});

  @override
  ConsumerState<SuperAdminAppUpdate> createState() =>
      _SuperAdminAppUpdateState();
}

class _SuperAdminAppUpdateState extends ConsumerState<SuperAdminAppUpdate> {
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
      _error = e.toString();
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Config de mise à jour publiée.')),
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
      appBar: const ArenaAppBar(title: 'MISE À JOUR APP'),
      body: ArenaScreenBackground(
        accent: ArenaColors.neonRed,
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(ArenaSpacing.lg),
                  children: [
                    Text(
                      'Publie la dernière version proposée aux utilisateurs '
                      '(distribution APK hors Play Store). '
                      "L'app compare son nom de version à « Version publiée ».",
                      style: ArenaText.bodyMuted,
                    ),
                    const SizedBox(height: ArenaSpacing.lg),
                    ArenaCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Version publiée (ex 1.1.0)'),
                          ArenaTextField(
                            controller: _version,
                            hint: '1.1.0',
                          ),
                          const SizedBox(height: ArenaSpacing.md),
                          _label('Build (versionCode, informatif)'),
                          ArenaTextField(
                            controller: _build,
                            hint: '11',
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: ArenaSpacing.md),
                          _label("URL de l'APK"),
                          ArenaTextField(
                            controller: _apkUrl,
                            hint: 'https://arena237.com/downloads/'
                                'arena-android-universel.apk',
                          ),
                          const SizedBox(height: ArenaSpacing.md),
                          _label('Notes de version'),
                          ArenaTextField(
                            controller: _changelog,
                            hint: 'Nouveautés de cette version…',
                            minLines: 3,
                            maxLines: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: ArenaSpacing.md),
                    ArenaCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _mandatory,
                            onChanged: (v) => setState(() => _mandatory = v),
                            title: Text(
                              'Mise à jour obligatoire',
                              style: ArenaText.body,
                            ),
                            subtitle: Text(
                              'Bloque les versions sous le « build minimum » '
                              'ci-dessous. Laisser OFF = simple suggestion.',
                              style: ArenaText.small
                                  .copyWith(color: ArenaColors.silver),
                            ),
                          ),
                          if (_mandatory) ...[
                            const SizedBox(height: ArenaSpacing.sm),
                            _label('Version minimale supportée (ex 1.0.5)'),
                            ArenaTextField(
                              controller: _minSupported,
                              hint: '1.0.5',
                            ),
                          ],
                        ],
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
                      label: _saving ? 'PUBLICATION…' : 'PUBLIER',
                      onPressed: _saving ? null : _save,
                      isLoading: _saving,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: ArenaText.small.copyWith(
            color: ArenaColors.silver,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}
