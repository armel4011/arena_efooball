import 'package:arena/core/services/game_detector_service.dart';
import 'package:arena/core/services/permissions_service.dart';
import 'package:arena/core/theme/arena_colors.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/target_game.dart';
import 'package:arena/features_shared/widgets/arena_button.dart';
import 'package:arena/features_shared/widgets/arena_card.dart';
import 'package:flutter/material.dart';

/// Internal debug screen for PHASE 8.2.
///
/// Lists target games installed on the device and live-streams the
/// foreground game detected by [GameDetectorService]. Should never be
/// reachable from a production navigation graph — surface it through a
/// debug-only entry (long-press on app version label, dev menu, etc.).
class GameDetectorDebugPage extends StatefulWidget {
  const GameDetectorDebugPage({
    GameDetectorService? detector,
    PermissionsService? permissions,
    super.key,
  })  : _detector = detector,
        _permissions = permissions;

  /// Injectable for tests; defaults to a fresh service in production.
  final GameDetectorService? _detector;
  final PermissionsService? _permissions;

  @override
  State<GameDetectorDebugPage> createState() => _GameDetectorDebugPageState();
}

class _GameDetectorDebugPageState extends State<GameDetectorDebugPage> {
  late final GameDetectorService _detector =
      widget._detector ?? GameDetectorService();
  late final PermissionsService _permissions =
      widget._permissions ?? PermissionsService();

  late Future<List<TargetGame>> _installedFuture;
  late Future<bool> _usageStatsFuture;
  late Stream<TargetGame?> _foregroundStream;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _installedFuture = _detector.checkInstalledTargetGames();
      _usageStatsFuture = _detector.hasUsageStatsAccess();
      _foregroundStream = _detector.foregroundGameStream();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArenaColors.bg,
      appBar: AppBar(
        title: const Text('Game detector — DEBUG'),
        backgroundColor: ArenaColors.bg,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(ArenaSpacing.md),
          children: [
            _UsageStatsCard(
              future: _usageStatsFuture,
              onOpenSettings: () async {
                await _permissions.requestUsageStats();
                _refresh();
              },
            ),
            const SizedBox(height: ArenaSpacing.md),
            _InstalledGamesCard(future: _installedFuture),
            const SizedBox(height: ArenaSpacing.md),
            _ForegroundGameCard(stream: _foregroundStream),
            const SizedBox(height: ArenaSpacing.lg),
            ArenaButton(
              label: 'Re-scan',
              variant: ArenaButtonVariant.secondary,
              onPressed: _refresh,
            ),
          ],
        ),
      ),
    );
  }
}

class _UsageStatsCard extends StatelessWidget {
  const _UsageStatsCard({
    required this.future,
    required this.onOpenSettings,
  });

  final Future<bool> future;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return ArenaCard(
      child: FutureBuilder<bool>(
        future: future,
        builder: (context, snap) {
          final granted = snap.data ?? false;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    granted ? Icons.check_circle : Icons.error_outline,
                    color: granted ? ArenaColors.success : ArenaColors.danger,
                  ),
                  const SizedBox(width: ArenaSpacing.sm),
                  Text(
                    'Usage stats access: ${granted ? "GRANTED" : "DENIED"}',
                    style: const TextStyle(
                      color: ArenaColors.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (!granted) ...[
                const SizedBox(height: ArenaSpacing.sm),
                const Text(
                  'Settings → Apps → Special access → Usage access → ARENA → ON',
                  style: TextStyle(color: ArenaColors.textMuted, fontSize: 12),
                ),
                const SizedBox(height: ArenaSpacing.sm),
                ArenaButton(
                  label: 'Open settings',
                  onPressed: onOpenSettings,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _InstalledGamesCard extends StatelessWidget {
  const _InstalledGamesCard({required this.future});

  final Future<List<TargetGame>> future;

  @override
  Widget build(BuildContext context) {
    return ArenaCard(
      child: FutureBuilder<List<TargetGame>>(
        future: future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final installed = snap.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Installed target games',
                style: TextStyle(
                  color: ArenaColors.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: ArenaSpacing.sm),
              for (final game in TargetGame.values)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Icon(
                        installed.contains(game)
                            ? Icons.check_circle
                            : Icons.cancel_outlined,
                        size: 16,
                        color: installed.contains(game)
                            ? ArenaColors.success
                            : ArenaColors.textFaint,
                      ),
                      const SizedBox(width: ArenaSpacing.sm),
                      Text(
                        game.displayName,
                        style: const TextStyle(color: ArenaColors.text),
                      ),
                      const SizedBox(width: ArenaSpacing.sm),
                      Text(
                        game.packageAndroid,
                        style: const TextStyle(
                          color: ArenaColors.textFaint,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ForegroundGameCard extends StatelessWidget {
  const _ForegroundGameCard({required this.stream});

  final Stream<TargetGame?> stream;

  @override
  Widget build(BuildContext context) {
    return ArenaCard(
      child: StreamBuilder<TargetGame?>(
        stream: stream,
        builder: (context, snap) {
          final game = snap.data;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Foreground (live, polled every 2s)',
                style: TextStyle(
                  color: ArenaColors.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: ArenaSpacing.sm),
              if (game == null)
                const Text(
                  '— no target game in foreground —',
                  style: TextStyle(color: ArenaColors.textMuted),
                )
              else
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: ArenaColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: ArenaSpacing.sm),
                    Text(
                      game.displayName,
                      style: const TextStyle(
                        color: ArenaColors.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}
