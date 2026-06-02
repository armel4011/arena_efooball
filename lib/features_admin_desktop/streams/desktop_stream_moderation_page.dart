import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:arena/core/services/agora_multi_streaming_service.dart';
import 'package:arena/core/theme/arena_fluent_theme.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/match_stream.dart';
import 'package:arena/data/repositories/admin/admin_audit_log_repository.dart';
import 'package:arena/data/repositories/match_stream_repository.dart';
import 'package:arena/features_admin/streams_admin/admin_multi_stream_controller.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

/// VAGUE 5 · Modération des streams live (desktop).
///
/// Porte `AdminStreamModerationPage` (mobile) vers Fluent UI. Réutilise
/// tels quels les providers mobiles : [activePublicStreamsProvider] pour
/// la liste des streams publics actifs et [adminMultiStreamStatesProvider]
/// pour joindre en parallèle chaque canal Agora en audience et émettre
/// l'uid distant.
///
/// La logique Agora (service [AgoraMultiStreamingService] + token client)
/// est strictement audience : aucune publication caméra/micro, donc aucune
/// permission Android/iOS n'est requise et le code fonctionne tel quel sur
/// Windows. Le widget [AgoraVideoView] de `agora_rtc_engine` rend la vidéo
/// distante sur Windows avec la même API que mobile.
///
/// Chaque tuile : aperçu vidéo (ou placeholder), identifiant du match,
/// streamer, bouton « Regarder » → `/streams/watch/<matchId>` et bouton
/// « Couper le stream » (modération `is_public = false` + audit log).
class DesktopStreamModerationPage extends ConsumerWidget {
  const DesktopStreamModerationPage({super.key});

  /// Construit l'URL `/streams/watch/<matchId>`.
  ///
  /// Le pattern de route correspondant (`/streams/watch/:matchId`) sera
  /// branché côté router lorsque la Vague 5 sera intégrée ; ce helper
  /// reste local pour ne pas modifier `AdminDesktopRoutes`.
  static String watchPath(String matchId) => '/streams/watch/$matchId';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streamsAsync = ref.watch(activePublicStreamsProvider);
    // Souscrit aux états multi-tuiles : déclenche les joins Agora en
    // audience pour chaque stream public actif (sync via ref.listen
    // interne au provider).
    final tiles = ref.watch(adminMultiStreamStatesProvider).value ?? const {};

    return ScaffoldPage(
      header: PageHeader(
        title: const Text('STREAMS LIVE'),
        commandBar: CommandBar(
          mainAxisAlignment: MainAxisAlignment.end,
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.refresh),
              label: const Text('Actualiser'),
              onPressed: () =>
                  ref.invalidate(activePublicStreamsProvider),
            ),
          ],
        ),
      ),
      content: streamsAsync.when(
        loading: () => const Center(child: ProgressRing()),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(ArenaDesktop.pagePadding),
          child: InfoBar(
            title: const Text('Impossible de charger les streams'),
            content: Text('$e'),
            severity: InfoBarSeverity.error,
          ),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const _EmptyState();
          }
          return ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: ArenaDesktop.pagePadding,
            ),
            children: [
              _ModerationNotice(count: list.length),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  // 3 à 4 colonnes selon la largeur disponible.
                  final columns = constraints.maxWidth >= 1500
                      ? 4
                      : constraints.maxWidth >= 1100
                          ? 3
                          : 2;
                  final tileWidth = (constraints.maxWidth -
                          (columns - 1) * ArenaDesktop.cardGap) /
                      columns;
                  return Wrap(
                    spacing: ArenaDesktop.cardGap,
                    runSpacing: ArenaDesktop.cardGap,
                    children: [
                      for (final stream in list)
                        SizedBox(
                          width: tileWidth,
                          child: _StreamTile(
                            stream: stream,
                            tileState: tiles[stream.matchId],
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Widgets privés
// ─────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            FluentIcons.video_off,
            size: 48,
            color: ArenaColors.silverDim,
          ),
          const SizedBox(height: 12),
          Text(
            'Aucun stream en cours',
            style: GoogleFonts.bebasNeue(
              color: ArenaColors.silver,
              fontSize: 22,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Les streams publics des matchs en cours apparaîtront ici.',
            style: GoogleFonts.spaceGrotesk(
              color: ArenaColors.silverDim,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModerationNotice extends StatelessWidget {
  const _ModerationNotice({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return InfoBar(
      title: Text(
        '$count stream${count > 1 ? 's' : ''} '
        'public${count > 1 ? 's' : ''} actif${count > 1 ? 's' : ''}',
      ),
      content: const Text(
        'Couper un stream est journalisé dans admin_audit_log avec votre '
        'identifiant admin.',
      ),
      severity: InfoBarSeverity.warning,
    );
  }
}

class _StreamTile extends ConsumerWidget {
  const _StreamTile({required this.stream, required this.tileState});

  final MatchStream stream;
  final MultiTileState? tileState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      backgroundColor: ArenaColors.carbon,
      borderRadius: BorderRadius.circular(10),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Aperçu vidéo ──────────────────────────────────────────
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _TilePreview(state: tileState),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _LiveBadge(),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: _MatchTag(matchId: stream.matchId),
                  ),
                ],
              ),
            ),
          ),
          // ─── Infos + actions ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Match ${_short(stream.matchId)}',
                  style: GoogleFonts.spaceGrotesk(
                    color: ArenaColors.bone,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Streamer ${_short(stream.playerId)}',
                  style: GoogleFonts.spaceGrotesk(
                    color: ArenaColors.silver,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () => context.go(
                          DesktopStreamModerationPage.watchPath(stream.matchId),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(FluentIcons.play, size: 12),
                            SizedBox(width: 6),
                            Text('Regarder'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: 'Couper le stream',
                      child: Button(
                        style: ButtonStyle(
                          foregroundColor:
                              WidgetStateProperty.all(ArenaColors.neonRed),
                        ),
                        onPressed: () => _confirmCut(context, ref),
                        child: const Icon(FluentIcons.blocked2, size: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _short(String id) =>
      id.length <= 8 ? id : id.substring(0, 8);

  Future<void> _confirmCut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => ContentDialog(
        title: const Text('Couper ce stream ?'),
        content: const Text(
          'Le stream sera retiré de la liste publique et les viewers '
          'seront déconnectés. Cette action est journalisée.',
        ),
        actions: [
          Button(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(ArenaColors.neonRed),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Couper'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await _cut(context, ref);
  }

  Future<void> _cut(BuildContext context, WidgetRef ref) async {
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null) return;
    try {
      await ref.read(matchStreamRepositoryProvider).setStreamingPublic(
            streamId: stream.id,
            isPublic: false,
          );
      await ref.read(adminAuditLogRepositoryProvider).record(
        adminId: adminId,
        action: 'stream_cut',
        targetType: 'stream',
        targetId: stream.id,
        afterState: {'match_id': stream.matchId, 'from': 'desktop_grid'},
      );
      if (!context.mounted) return;
      await displayInfoBar(
        context,
        builder: (context, close) => InfoBar(
          title: const Text('Stream coupé'),
          severity: InfoBarSeverity.success,
          onClose: close,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      await displayInfoBar(
        context,
        builder: (context, close) => InfoBar(
          title: const Text('Échec de la coupure'),
          content: Text('$e'),
          severity: InfoBarSeverity.error,
          onClose: close,
        ),
      );
    }
  }
}

/// Aperçu de la tuile : `AgoraVideoView` si le flux distant est arrivé,
/// sinon un placeholder (chargement ou échec).
class _TilePreview extends ConsumerWidget {
  const _TilePreview({required this.state});

  final MultiTileState? state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = state;
    if (s is MultiTileJoined && s.remoteUid != null) {
      final engine = ref.watch(agoraMultiStreamingServiceProvider).engine;
      if (engine != null) {
        return AgoraVideoView(
          controller: VideoViewController.remote(
            rtcEngine: engine,
            canvas: VideoCanvas(uid: s.remoteUid),
            connection: s.connection,
          ),
        );
      }
    }
    return ColoredBox(
      color: ArenaColors.blackPure,
      child: Center(
        child: switch (s) {
          MultiTileFailed() => const Icon(
              FluentIcons.error_badge,
              size: 22,
              color: ArenaColors.silverDim,
            ),
          MultiTileJoined() => Text(
              'Attente du flux…',
              style: GoogleFonts.spaceGrotesk(
                color: ArenaColors.silverDim,
                fontSize: 12,
              ),
            ),
          _ => const SizedBox(
              width: 20,
              height: 20,
              child: ProgressRing(strokeWidth: 2),
            ),
        },
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: ArenaColors.neonRed,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'LIVE',
        style: GoogleFonts.spaceGrotesk(
          color: ArenaColors.bone,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _MatchTag extends StatelessWidget {
  const _MatchTag({required this.matchId});

  final String matchId;

  @override
  Widget build(BuildContext context) {
    final short = matchId.length <= 6 ? matchId : matchId.substring(0, 6);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: ArenaColors.blackPure.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'M-$short',
        style: GoogleFonts.spaceGrotesk(
          color: ArenaColors.bone,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
