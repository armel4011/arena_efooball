import 'dart:async';

import 'package:arena/core/services/agora_streaming_service.dart';
import 'package:arena/core/services/gallery_exporter.dart';
import 'package:arena/core/services/match_recording_coordinator.dart';
import 'package:arena/core/services/native_lifecycle_events.dart';
import 'package:arena/core/services/permissions_service.dart';
import 'package:arena/core/services/recording_overlay_controller.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/models/match_status.dart';
import 'package:arena/data/models/match_stream.dart';
import 'package:arena/data/repositories/match_repository.dart';
import 'package:arena/data/repositories/match_stream_repository.dart';
import 'package:arena/features_user/match_room/widgets/match_recording_actions_sheet.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// True only on a real Android device. False on web (where `dart:io` is
/// unsupported) and on every other platform — recording is Android-only.
bool get _isAndroidNative =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

/// Glue between `MatchRoomPage` and PHASE 8's anti-cheat coordinator.
///
/// Listens to the match's status and:
///   * starts [MatchRecordingCoordinator] when the seated player enters
///     `in_progress` for the first time,
///   * lets it run while the player navigates back to the bracket and
///     re-enters the room (the coordinator state is owned at the
///     provider scope, so a remount doesn't restart anything),
///   * cleanly stops on terminal status transitions (`completed`,
///     `cancelled`, `forfeited`) — `disputed` is left running because
///     the dispute admin still wants the live recording footage.
///
/// Renders a slim "Recording…" banner so the user can see we're
/// actively recording. The banner stays empty for observers and on
/// non-Android platforms (recording is Android-only by design).
class MatchRecordingLifecycle extends ConsumerStatefulWidget {
  const MatchRecordingLifecycle({
    required this.match,
    required this.selfId,
    super.key,
  });

  final ArenaMatch match;

  /// Current Supabase user id, or null if logged out / observer.
  final String? selfId;

  @override
  ConsumerState<MatchRecordingLifecycle> createState() =>
      _MatchRecordingLifecycleState();
}

class _MatchRecordingLifecycleState
    extends ConsumerState<MatchRecordingLifecycle> {
  bool _startAttempted = false;
  String? _startError;

  bool get _isPlayer =>
      widget.selfId != null &&
      (widget.selfId == widget.match.player1Id ||
          widget.selfId == widget.match.player2Id);

  String? get _opponentId {
    if (widget.selfId == widget.match.player1Id) return widget.match.player2Id;
    if (widget.selfId == widget.match.player2Id) return widget.match.player1Id;
    return null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeReact());
  }

  @override
  void didUpdateWidget(MatchRecordingLifecycle old) {
    super.didUpdateWidget(old);
    if (old.match.status != widget.match.status) {
      _maybeReact();
    }
  }

  Future<void> _maybeReact() async {
    if (!_isAndroidNative) return;
    if (!_isPlayer) return;
    final coord = ref.read(matchRecordingCoordinatorProvider);

    final status = widget.match.status;
    final isLive = status == MatchStatus.inProgress ||
        status == MatchStatus.scorePending ||
        status == MatchStatus.awaitingValidation;
    final isTerminal = status == MatchStatus.completed ||
        status == MatchStatus.cancelled ||
        status == MatchStatus.forfeited;

    if (isLive && !_startAttempted) {
      // Lock recording if this player has already submitted a score
      // for the match. Once a score is in, the match is either
      // pending-opponent, in dispute, or up for admin validation —
      // recording adds no value and would just chew battery.
      final submissions = ref
          .read(matchScoreSubmissionsProvider(widget.match.id))
          .valueOrNull;
      final alreadySubmitted = submissions?.any(
            (s) => s['created_by'] == widget.selfId,
          ) ??
          false;
      if (alreadySubmitted) {
        _startAttempted = true;
        return;
      }

      _startAttempted = true;
      var opp = _opponentId;
      // Debug-only fallback for solo BYE testing on the emulator: without
      // a real opponent the coordinator bails before MediaProjection. A
      // synthetic UUID lets the native recorder + overlay come up; the
      // forfeit auto-flow will FK-fail at markForfeit() if the pause grace
      // ever expires — fine, debug data only.
      if (opp == null && kDebugMode) {
        opp = '00000000-0000-0000-0000-000000000000';
      }
      if (opp == null) return;

      // Request runtime permissions BEFORE handing off to the native
      // recorder. Without RECORD_AUDIO the audio track is silently
      // dropped; without POST_NOTIFICATIONS (Android 13+) the foreground
      // service notification can't show and the OS kills the FGS in ~5s.
      final permissions = ref.read(permissionsServiceProvider);
      final bundle = await permissions.requestRecordingBundle();
      if (!bundle.allGranted) {
        if (mounted) {
          setState(() => _startError = _bundleErrorMessage(bundle));
        }
        return;
      }

      // SYSTEM_ALERT_WINDOW for the floating anti-cheat button. Sends the
      // user to a full-screen settings page on Android 6+, so handle it
      // explicitly here — RecordingOverlayController.start() also checks
      // but bails silently on denial, which hides the failure.
      final overlay = await permissions.requestOverlay();
      if (!overlay.isGranted) {
        if (mounted) {
          setState(() => _startError = _overlayErrorMessage(overlay));
        }
        return;
      }

      try {
        await coord.startForMatch(
          matchId: widget.match.id,
          playerId: widget.selfId!,
          opponentId: opp,
        );
      } catch (e) {
        if (mounted) {
          setState(() => _startError = e.toString());
        }
      }
      return;
    }

    if (isTerminal && coord.state is! CoordinatorIdle) {
      try {
        await coord.stopCleanly();
      } catch (e) {
        debugPrint('[recording] terminal stopCleanly failed: $e');
      }
    }
  }

  /// Anti-double export — un seul export par session, sinon le user voit
  /// 2 snackbars (saveAndStop déjà déclenché + transition CoordinatorStopped).
  String? _exportedPath;

  /// Démarre Agora en broadcaster après que l'overlay a demandé "Live".
  /// Le recording a déjà été stoppé par le coordinator (voir
  /// `_onOverlayAction.goLive`), donc plus aucune MediaProjection
  /// concurrente. Snackbar success / error pour informer le user.
  Future<void> _goLive(String matchId) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await ref
          .read(agoraStreamingServiceProvider)
          .joinAsBroadcaster(matchId: matchId);
      if (!mounted || messenger == null) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.recordingLiveStreamStarted),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[stream] goLive failed: $e\n$st');
      }
      if (!mounted || messenger == null) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.recordingLiveStreamError(e)),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Export auto vers `Téléchargements/ARENA/` dès que le coord transite
  /// vers `CoordinatorStopped` avec un path. Couvre tous les chemins de
  /// stop (notif système, auto-stop 25 min, terminal match status,
  /// forfait), pas seulement l'overlay "Enregistrer & arrêter".
  void _maybeAutoExportRecording(
    CoordinatorState? prev,
    CoordinatorState? next,
  ) {
    if (next is! CoordinatorStopped) {
      if (kDebugMode) {
        debugPrint('[recording] autoExport skip — state=${next.runtimeType}');
      }
      return;
    }
    final path = next.localRecordingPath;
    if (path == null || path.isEmpty) {
      if (kDebugMode) {
        debugPrint('[recording] autoExport skip — Stopped reached but path=$path');
      }
      return;
    }
    if (_exportedPath == path) {
      if (kDebugMode) {
        debugPrint('[recording] autoExport skip — already exported $path');
      }
      return;
    }
    _exportedPath = path;
    if (kDebugMode) {
      debugPrint('[recording] autoExport firing for $path');
    }
    unawaited(_exportRecording(path));
  }

  Future<void> _exportRecording(String path) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final uri = await ref.read(galleryExporterProvider).saveVideoToGallery(path);
    if (kDebugMode) {
      debugPrint('[recording] saveVideoToGallery uri=$uri mounted=$mounted');
    }
    if (!mounted || messenger == null) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          uri != null
              ? l10n.recordingReplaySavedDownloads
              : l10n.recordingReplayInCache,
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  String _bundleErrorMessage(RecordingPermissionsBundle bundle) {
    final l10n = AppLocalizations.of(context);
    final missing = <String>[];
    if (!bundle.microphone.isGranted) missing.add(l10n.recordingPermMissingMic);
    if (!bundle.notifications.isGranted) {
      missing.add(l10n.recordingPermMissingNotifications);
    }
    final list = missing.join(' + ');
    if (bundle.microphone.needsSettings ||
        bundle.notifications.needsSettings) {
      return l10n.recordingPermBundleNeedsSettings(list);
    }
    return l10n.recordingPermBundleDenied(list);
  }

  String _overlayErrorMessage(PermissionOutcome outcome) {
    final l10n = AppLocalizations.of(context);
    if (outcome.needsSettings) {
      return l10n.recordingPermOverlayNeedsSettings;
    }
    return l10n.recordingPermOverlayDenied;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (!_isAndroidNative || !_isPlayer) {
      return const SizedBox.shrink();
    }

    // Pas d'auto-start streaming (Android 14+ refuse 2 MediaProjection
    // simultanées — cf. mémoire mediaprojection_constraints). En revanche
    // on PROPAGE l'éligibilité streaming au controller overlay : si
    // l'admin a flagué une row stream is_public + is_active ownée par
    // self, le 5ᵉ mini "Live" devient visible sur le bouton flottant.
    // Le tap sur ce mini déclenche `OverlayAction.goLive` côté
    // coordinator : stopCleanly + push matchId via `goLiveRequests`,
    // qu'on récupère ici pour appeler `joinAsBroadcaster`.
    ref
      ..listen<AsyncValue<List<MatchStream>>>(
        matchStreamsByMatchProvider(widget.match.id),
        (_, next) {
          final streams = next.valueOrNull;
          final eligible = streams != null &&
              streams.any(
                (s) =>
                    s.isPublic && s.isActive && s.playerId == widget.selfId,
              );
          ref
              .read(recordingOverlayControllerProvider)
              .setLiveAvailable(eligible);
        },
      )
      ..listen<AsyncValue<String>>(
        coordinatorGoLiveRequestsProvider,
        (_, next) {
          final matchId = next.valueOrNull;
          if (matchId == null || matchId.isEmpty) return;
          unawaited(_goLive(matchId));
        },
      )
      ..listen<AsyncValue<CoordinatorState>>(
        coordinatorStateProvider,
        (prev, next) {
          _maybeAutoExportRecording(prev?.valueOrNull, next.valueOrNull);
        },
      )
      // MediaProjection morte (user a tapé Stop sur la notif système, ou
      // perm révoquée). Le service Kotlin a déjà teardown — on doit juste
      // propager au coord pour qu'il flippe son état + déclencher l'export.
      ..listen<AsyncValue<NativeLifecycleEvent>>(
        nativeLifecycleEventsStreamProvider,
        (_, next) {
          if (next.valueOrNull != NativeLifecycleEvent.mediaProjectionDied) {
            return;
          }
          final coord = ref.read(matchRecordingCoordinatorProvider);
          final s = coord.state;
          if (s is CoordinatorRecording || s is CoordinatorPaused) {
            unawaited(coord.stopCleanly());
          }
        },
      )
      // Open the actions sheet when the overlay sends a focusMain (tap on
      // the floating button). L'export MP4 vers Téléchargements/ARENA est
      // désormais déclenché par la transition CoordinatorRecording →
      // CoordinatorStopped (`_maybeAutoExportRecording` ci-dessus), donc
      // valable pour TOUS les chemins de stop : saveAndStop overlay, stop
      // via notif système Android, auto-stop 25 min, match terminé.
      ..listen(coordinatorFocusRequestsProvider, (_, __) {
        if (!mounted) return;
        MatchRecordingActionsSheet.show(context);
      });

    final startError = _startError;
    if (startError != null) {
      return _LifecycleBanner(
        icon: Icons.warning_amber_rounded,
        color: ArenaColors.warning,
        text: l10n.recordingBannerUnavailable(startError),
        onTap: () {
          setState(() {
            _startError = null;
            _startAttempted = false;
          });
          _maybeReact();
        },
      );
    }

    final asyncState = ref.watch(coordinatorStateProvider);
    final coordState = asyncState.value ?? const CoordinatorIdle();

    void openSheet() {
      MatchRecordingActionsSheet.show(context);
    }

    return switch (coordState) {
      CoordinatorRecording() => _LifecycleBanner(
          icon: Icons.fiber_manual_record,
          color: ArenaColors.danger,
          text: l10n.recordingBannerRecording,
          onTap: openSheet,
        ),
      CoordinatorPaused() => _LifecycleBanner(
          icon: Icons.pause_circle_outline,
          color: ArenaColors.warning,
          text: l10n.recordingBannerPaused,
          onTap: openSheet,
        ),
      CoordinatorForfeited(reason: final r) => _LifecycleBanner(
          icon: Icons.flag_outlined,
          color: ArenaColors.danger,
          text: r == 'pause_grace_expired'
              ? l10n.recordingBannerForfeitPauseExpired
              : l10n.recordingBannerForfeitDeclared,
        ),
      _ => const SizedBox.shrink(),
    };
  }
}

class _LifecycleBanner extends StatelessWidget {
  const _LifecycleBanner({
    required this.icon,
    required this.color,
    required this.text,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final inner = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: ArenaSpacing.md,
        vertical: ArenaSpacing.sm,
      ),
      color: color.withValues(alpha: 0.16),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: ArenaSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: ArenaText.small.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return inner;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, child: inner),
    );
  }
}
