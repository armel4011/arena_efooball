import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/utils/arena_error_message.dart';
import 'package:arena/data/repositories/game_settings_repository.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:arena/features_shared/widgets/arena_card.dart';
import 'package:arena/features_shared/widgets/arena_screen_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Écran super-admin : activer / désactiver les jeux de la plateforme.
/// Un jeu désactivé ne permet plus de créer de compétition et disparaît des
/// choix côté joueur ; les compétitions déjà créées continuent.
class SuperAdminGames extends ConsumerStatefulWidget {
  const SuperAdminGames({super.key});

  @override
  ConsumerState<SuperAdminGames> createState() => _SuperAdminGamesState();
}

class _SuperAdminGamesState extends ConsumerState<SuperAdminGames> {
  List<GameSetting> _settings = const [];
  bool _loading = true;
  String? _busyGame;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final s =
          await ref.read(gameSettingsRepositoryProvider).fetchAdminSettings();
      _settings = s;
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
    });
    try {
      await ref
          .read(gameSettingsRepositoryProvider)
          .setEnabled(s.game, enabled: enabled);
      ref.invalidate(disabledGamesProvider);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enabled
                  ? '${s.game.label} activé.'
                  : '${s.game.label} désactivé.',
            ),
          ),
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
    return Scaffold(
      appBar: const ArenaAppBar(title: 'JEUX'),
      body: ArenaScreenBackground(
        accent: ArenaColors.neonRed,
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(ArenaSpacing.lg),
                  children: [
                    Text(
                      'Un jeu désactivé ne peut plus accueillir de nouvelle '
                      'compétition et n’apparaît plus côté joueurs (onglets, '
                      'jeux d’intérêt). Les compétitions déjà créées '
                      'continuent normalement. Au moins un jeu reste actif.',
                      style: ArenaText.bodyMuted,
                    ),
                    const SizedBox(height: ArenaSpacing.lg),
                    for (final s in _settings) ...[
                      ArenaCard(
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: s.isEnabled,
                          onChanged: _busyGame != null
                              ? null
                              : (v) => _toggle(s, v),
                          title: Text(
                            s.game.label,
                            style: ArenaText.body
                                .copyWith(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            '${s.isEnabled ? 'Actif' : 'Désactivé'} · '
                            '${s.activeCompetitions} compétition(s) en cours',
                            style: ArenaText.small.copyWith(
                              color: s.isEnabled
                                  ? ArenaColors.success
                                  : ArenaColors.silver,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: ArenaSpacing.sm),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: ArenaSpacing.sm),
                      Text(
                        _error!,
                        style: ArenaText.small
                            .copyWith(color: ArenaColors.neonRed),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
