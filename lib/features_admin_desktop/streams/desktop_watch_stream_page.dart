import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:arena/core/router/admin_desktop_router.dart';
import 'package:arena/core/services/agora_multi_streaming_service.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/repositories/admin/admin_audit_log_repository.dart';
import 'package:arena/data/repositories/match_stream_repository.dart';
import 'package:arena/features_admin/streams_admin/admin_multi_stream_controller.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

/// VAGUE 5 · Visionnage plein-écran d'un stream live (desktop).
///
/// Porte `AdminWatchStreamPage` (mobile) vers Fluent UI. Réutilise le
/// service partagé [AgoraMultiStreamingService] : si la grille de
/// modération est encore dans la pile, la `RtcConnection` déjà jointe est
/// récupérée ; sinon on déclenche `joinAudience` au montage (ouverture
/// directe via deep link).
///
/// Le service est strictement audience (pas de publication caméra/micro),
/// donc aucune permission n'est requise et il fonctionne tel quel sur
/// Windows. `AgoraVideoView` rend la vidéo distante avec la même API que
/// mobile.
///
/// Contrôles de modération :
/// - 🔊 / 🔇 bascule de l'abonnement audio (`focusAudio`) ;
/// - 🛑 Couper (kill switch : `is_public = false` + audit log).
class DesktopWatchStreamPage extends ConsumerStatefulWidget {
  const DesktopWatchStreamPage({required this.matchId, super.key});

  final String matchId;

  @override
  ConsumerState<DesktopWatchStreamPage> createState() =>
      _DesktopWatchStreamPageState();
}

class _DesktopWatchStreamPageState
    extends ConsumerState<DesktopWatchStreamPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Force la souscription au provider de sync (joins/leaves).
      ref.read(adminMultiStreamStatesProvider);
      final svc = ref.read(agoraMultiStreamingServiceProvider);
      if (!svc.states.containsKey(widget.matchId)) {
        svc.joinAudience(widget.matchId);
      }
      // Audio actif par défaut en plein écran.
      svc.focusAudio(widget.matchId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tiles = ref.watch(adminMultiStreamStatesProvider).value ??
        const <String, MultiTileState>{};
    final tile = tiles[widget.matchId];
    final engine = ref.watch(agoraMultiStreamingServiceProvider).engine;
    final isAudioFocused = tile is MultiTileJoined && tile.audioFocused;

    return ScaffoldPage(
      padding: EdgeInsets.zero,
      content: ColoredBox(
        color: ArenaColors.blackPure,
        child: Stack(
          children: [
            Positioned.fill(
              child: _Video(tile: tile, engine: engine),
            ),
            // Bandeau supérieur — retour + LIVE + match ID.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _TopBar(
                matchId: widget.matchId,
                onBack: () => context.go(AdminDesktopRoutes.streams),
              ),
            ),
            // Bandeau inférieur — actions modération.
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _BottomActions(
                isAudioFocused: isAudioFocused,
                onToggleAudio: () => ref
                    .read(agoraMultiStreamingServiceProvider)
                    .focusAudio(widget.matchId),
                onCut: () => _confirmCut(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmCut(BuildContext context) async {
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
    await _cut(context);
  }

  Future<void> _cut(BuildContext context) async {
    final adminId = ref.read(currentSessionProvider)?.user.id;
    if (adminId == null) return;
    final repo = ref.read(matchStreamRepositoryProvider);
    try {
      // Résout l'id du row `streams` à partir du matchId.
      final active = await repo.listActivePublic();
      final stream = active.where((s) => s.matchId == widget.matchId);
      if (stream.isEmpty) {
        throw StateError('Stream introuvable pour ${widget.matchId}');
      }
      final target = stream.first;
      await repo.setStreamingPublic(streamId: target.id, isPublic: false);
      await ref.read(adminAuditLogRepositoryProvider).record(
        adminId: adminId,
        action: 'stream_cut',
        targetType: 'stream',
        targetId: target.id,
        afterState: {'match_id': target.matchId, 'from': 'desktop_fullscreen'},
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
      if (!context.mounted) return;
      context.go(AdminDesktopRoutes.streams);
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

// ─────────────────────────────────────────────────────────────────────
// Widgets privés
// ─────────────────────────────────────────────────────────────────────

class _Video extends StatelessWidget {
  const _Video({required this.tile, required this.engine});

  final MultiTileState? tile;
  final RtcEngineEx? engine;

  @override
  Widget build(BuildContext context) {
    final t = tile;
    if (t is MultiTileJoined && t.remoteUid != null && engine != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: engine!,
          canvas: VideoCanvas(uid: t.remoteUid),
          connection: t.connection,
        ),
      );
    }
    return Center(
      child: switch (t) {
        MultiTileFailed(reason: final r) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                FluentIcons.error_badge,
                size: 48,
                color: ArenaColors.neonRed,
              ),
              const SizedBox(height: 12),
              Text(
                'Échec de connexion au stream',
                style: GoogleFonts.spaceGrotesk(
                  color: ArenaColors.bone,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                r,
                style: GoogleFonts.spaceGrotesk(
                  color: ArenaColors.silver,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        _ => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ProgressRing(),
              const SizedBox(height: 16),
              Text(
                t is MultiTileJoined
                    ? 'Attente du broadcaster…'
                    : 'Connexion au stream…',
                style: GoogleFonts.spaceGrotesk(
                  color: ArenaColors.silver,
                  fontSize: 13,
                ),
              ),
            ],
          ),
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.matchId, required this.onBack});

  final String matchId;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final short = matchId.length <= 8 ? matchId : matchId.substring(0, 8);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ArenaColors.blackPure.withValues(alpha: 0.85),
            ArenaColors.blackPure.withValues(alpha: 0),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(
                FluentIcons.back,
                color: ArenaColors.bone,
                size: 18,
              ),
              onPressed: onBack,
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: ArenaColors.neonRed,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'LIVE',
                style: GoogleFonts.spaceGrotesk(
                  color: ArenaColors.bone,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'M-$short',
              style: GoogleFonts.spaceGrotesk(
                color: ArenaColors.bone,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.isAudioFocused,
    required this.onToggleAudio,
    required this.onCut,
  });

  final bool isAudioFocused;
  final VoidCallback onToggleAudio;
  final VoidCallback onCut;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            ArenaColors.blackPure.withValues(alpha: 0.85),
            ArenaColors.blackPure.withValues(alpha: 0),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ActionButton(
              icon: isAudioFocused ? FluentIcons.volume3 : FluentIcons.volume0,
              label: isAudioFocused ? 'Audio activé' : 'Audio coupé',
              accent: isAudioFocused
                  ? ArenaColors.signalBlue
                  : ArenaColors.silver,
              onTap: onToggleAudio,
            ),
            const SizedBox(width: 16),
            _ActionButton(
              icon: FluentIcons.blocked2,
              label: 'Couper le stream',
              accent: ArenaColors.neonRed,
              onTap: onCut,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: onTap,
      style: ButtonStyle(
        backgroundColor:
            WidgetStateProperty.all(ArenaColors.carbon.withValues(alpha: 0.9)),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: accent, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              color: accent,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
