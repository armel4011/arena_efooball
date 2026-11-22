import 'package:arena/core/theme/arena_fluent_theme.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/utils/arena_error_message.dart';
import 'package:arena/data/repositories/game_settings_repository.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Écran super-admin desktop : activer / désactiver les jeux. Équivalent
/// Fluent de SuperAdminGames.
class DesktopGamesPage extends ConsumerStatefulWidget {
  const DesktopGamesPage({super.key});

  @override
  ConsumerState<DesktopGamesPage> createState() => _DesktopGamesPageState();
}

class _DesktopGamesPageState extends ConsumerState<DesktopGamesPage> {
  List<GameSetting> _settings = const [];
  bool _loading = true;
  String? _busyGame;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _settings =
          await ref.read(gameSettingsRepositoryProvider).fetchAdminSettings();
      _error = null;
    } catch (e) {
      _error = arenaErrorMessage(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle(GameSetting s, bool enabled) async {
    setState(() {
      _busyGame = s.game.value;
      _error = null;
      _success = null;
    });
    try {
      await ref
          .read(gameSettingsRepositoryProvider)
          .setEnabled(s.game, enabled: enabled);
      ref.invalidate(disabledGamesProvider);
      await _load();
      if (mounted) {
        setState(
          () => _success =
              enabled ? '${s.game.label} activé.' : '${s.game.label} désactivé.',
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = arenaErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busyGame = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: const PageHeader(title: Text('JEUX')),
      content: _loading
          ? const Center(child: ProgressRing())
          : Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ArenaDesktop.pagePadding,
              ),
              child: ListView(
                children: [
                  const Text(
                    'Un jeu désactivé ne peut plus accueillir de nouvelle '
                    'compétition et n’apparaît plus côté joueurs (onglets, jeux '
                    'd’intérêt). Les compétitions déjà créées continuent '
                    'normalement. Au moins un jeu reste actif.',
                    style: TextStyle(color: ArenaColors.silver),
                  ),
                  const SizedBox(height: 16),
                  for (final s in _settings)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Card(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.game.label,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${s.isEnabled ? 'Actif' : 'Désactivé'} · '
                                    '${s.activeCompetitions} compétition(s) en '
                                    'cours',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: s.isEnabled
                                          ? ArenaColors.success
                                          : ArenaColors.silver,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ToggleSwitch(
                              checked: s.isEnabled,
                              onChanged: _busyGame != null
                                  ? null
                                  : (v) => _toggle(s, v),
                            ),
                          ],
                        ),
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
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
