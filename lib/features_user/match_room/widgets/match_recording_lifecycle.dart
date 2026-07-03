import 'dart:async';

import 'package:arena/core/services/agora_streaming_service.dart';
import 'package:arena/core/services/anticheat/anticheat_config_service.dart';
import 'package:arena/core/services/anticheat/anticheat_provider.dart';
import 'package:arena/core/services/livekit_capture_service.dart';
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

  /// Nom d'équipe du joueur courant (posé quand il rejoint / démarre). Sert
  /// de signal « ce joueur a rejoint la room » dans le nouveau flux.
  static String? _teamNameFor(ArenaMatch m, String? selfId) {
    if (selfId == m.player1Id) return m.player1TeamName;
    if (selfId == m.player2Id) return m.player2TeamName;
    return null;
  }

  /// Vrai quand le joueur courant a rejoint (team name non vide). Le HOME
  /// le pose à « DÉMARRER L'ENREGISTREMENT », l'AWAY à « J'AI REJOINT LA
  /// ROOM » — on ne démarre donc SON recording qu'à ce moment (l'AWAY ne
  /// filme pas avant d'avoir le code / rejoint la room).
  bool get _selfJoined =>
      _teamNameFor(widget.match, widget.selfId)?.trim().isNotEmpty ?? false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeReact());
  }

  @override
  void didUpdateWidget(MatchRecordingLifecycle old) {
    super.didUpdateWidget(old);
    // Réagir au changement de statut ET au passage null→set du team name du
    // joueur courant : dans le nouveau flux, l'AWAY rejoint (pose son team
    // name) alors que le match est DÉJÀ in_progress — c'est ce changement,
    // pas le statut, qui doit déclencher son recording.
    final wasJoined =
        _teamNameFor(old.match, old.selfId)?.trim().isNotEmpty ?? false;
    if (old.match.status != widget.match.status || wasJoined != _selfJoined) {
      _maybeReact();
    }
    // Pousse le code room courant + le rôle à l'overlay : la clé de l'AWAY
    // reflète en direct tout nouveau code renvoyé par le HOME. No-op si rien
    // n'a changé / overlay pas affiché.
    if (old.match.roomCode != widget.match.roomCode ||
        old.match.homePlayerId != widget.match.homePlayerId) {
      _pushRoomCodeInfo();
    }
  }

  /// true si le joueur courant est le HOME (la clé ouvre la SAISIE ; sinon la
  /// VUE lecture seule + Copier côté AWAY).
  bool get _isHome =>
      widget.selfId != null && widget.selfId == widget.match.homePlayerId;

  void _pushRoomCodeInfo() {
    if (!_isAndroidNative || !_isPlayer) return;
    ref
        .read(recordingOverlayControllerProvider)
        .setRoomCodeInfo(widget.match.roomCode, _isHome);
  }

  Future<void> _maybeReact() async {
    if (!_isAndroidNative) return;
    if (!_isPlayer) return;

    final status = widget.match.status;
    final isInProgress = status == MatchStatus.inProgress;
    final isLive = isInProgress ||
        status == MatchStatus.scorePending ||
        status == MatchStatus.awaitingValidation;
    final isTerminal = status == MatchStatus.completed ||
        status == MatchStatus.cancelled ||
        status == MatchStatus.forfeited;

    if (isLive && _selfJoined && !_startAttempted) {
      // Lock recording if this player has already submitted a score
      // for the match. Once a score is in, the match is either
      // pending-opponent, in dispute, or up for admin validation —
      // recording adds no value and would just chew battery.
      final submissions =
          ref.read(matchScoreSubmissionsProvider(widget.match.id)).valueOrNull;
      final alreadySubmitted = submissions?.any(
            (s) => s['created_by'] == widget.selfId,
          ) ??
          false;
      if (alreadySubmitted) {
        _startAttempted = true;
        return;
      }

      _startAttempted = true;

      // Provider anti-triche actif — lecture réelle de app_config (pas le
      // best-effort sync : on est déjà dans un contexte async one-shot).
      AntiCheatProviderKind kind;
      try {
        kind = await ref.read(activeAntiCheatProviderProvider.future);
      } catch (_) {
        kind = AntiCheatProviderKind.fallback;
      }
      if (!mounted) return;

      // Exclusivité MediaProjection (Android 14+) : un seul provider démarre
      // une capture d'écran à la fois.
      if (kind == AntiCheatProviderKind.livekitTrackEgress) {
        // LiveKit Track Egress est facturé à la minute (2 pistes/match) : on
        // ne démarre l'egress que pendant le gameplay actif (in_progress).
        // Entrer en cours de score_pending/awaiting_validation = gameplay
        // déjà terminé → rien à filmer, on ne lance pas de capture facturée.
        if (isInProgress) {
          await _startLiveKit();
        }
      } else {
        await _startNative();
      }
      return;
    }

    // Couper l'egress LiveKit DÈS la fin du gameplay (sortie de in_progress
    // vers score_pending / awaiting_validation / …), sans attendre l'état
    // terminal : chaque minute post-gameplay serait facturée pour rien. Le
    // recorder natif (fichier local, sans coût/minute) garde son comportement
    // historique — il ne s'arrête qu'aux états terminaux (_stopOnTerminal).
    if (!isInProgress) {
      await _stopLiveKitIfRunning();
    }

    if (isTerminal) {
      await _stopOnTerminal();
    }
  }

  /// Coupe la capture LiveKit si elle tourne (idempotent). La room se ferme →
  /// le serveur reçoit `egress_ended` et clôture la facturation des minutes.
  Future<void> _stopLiveKitIfRunning() async {
    final livekit = ref.read(liveKitCaptureServiceProvider);
    if (livekit.state is! LiveKitCaptureIdle) {
      try {
        await livekit.stop();
      } catch (e) {
        debugPrint('[recording] livekit gameplay-end stop failed: $e');
      }
    }
  }

  /// Démarre la capture anti-triche via le recorder natif (filet de
  /// sécurité). Comportement historique INCHANGÉ.
  Future<void> _startNative() async {
    final coord = ref.read(matchRecordingCoordinatorProvider);
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
      // Overlay affiché : pousse le code + rôle pour l'état initial de la clé
      // (AWAY = vue lecture seule du code ; HOME = saisie).
      _pushRoomCodeInfo();
    } catch (e) {
      if (mounted) {
        setState(() => _startError = e.toString());
      }
    }
  }

  /// Démarre la capture anti-triche via LiveKit (publish-only). Pas
  /// d'overlay ni de micro : capture vidéo seule, enregistrée côté serveur
  /// par Track Egress. Seule POST_NOTIFICATIONS est requise (foreground
  /// service de capture d'écran) ; la consent MediaProjection est gérée par
  /// le plugin flutter_webrtc lui-même.
  Future<void> _startLiveKit() async {
    final permissions = ref.read(permissionsServiceProvider);
    final notif = await permissions.requestNotifications();
    if (!notif.isGranted) {
      if (mounted) {
        setState(() => _startError = _notifErrorMessage(notif));
      }
      return;
    }

    // Bouton flottant overlay (best-effort) : on demande SYSTEM_ALERT_WINDOW
    // en amont pour qu'il s'affiche pendant la capture egress. Si l'utilisateur
    // refuse, la capture continue sans overlay (la notif système reste le
    // moyen d'arrêter) — on ne bloque donc PAS sur ce résultat.
    await permissions.requestOverlay();

    try {
      await ref
          .read(liveKitCaptureServiceProvider)
          .start(matchId: widget.match.id);
    } catch (e) {
      if (mounted) {
        setState(() => _startError = e.toString());
      }
    }
  }

  /// Stoppe le provider actif aux états terminaux du match. `disputed` reste
  /// volontairement en cours (l'admin veut la vidéo live). Les deux providers
  /// sont vérifiés : un changement de réglage en cours de match ne doit pas
  /// laisser une capture orpheline.
  Future<void> _stopOnTerminal() async {
    final coord = ref.read(matchRecordingCoordinatorProvider);
    if (coord.state is! CoordinatorIdle) {
      try {
        await coord.stopCleanly();
      } catch (e) {
        debugPrint('[recording] terminal stopCleanly failed: $e');
      }
    }
    await _stopLiveKitIfRunning();
  }

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

  String _bundleErrorMessage(RecordingPermissionsBundle bundle) {
    final l10n = AppLocalizations.of(context);
    final missing = <String>[];
    if (!bundle.microphone.isGranted) missing.add(l10n.recordingPermMissingMic);
    if (!bundle.notifications.isGranted) {
      missing.add(l10n.recordingPermMissingNotifications);
    }
    final list = missing.join(' + ');
    if (bundle.microphone.needsSettings || bundle.notifications.needsSettings) {
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

  /// Message d'erreur quand POST_NOTIFICATIONS est refusée pour la capture
  /// LiveKit (foreground service). Réutilise les clés du bundle natif.
  String _notifErrorMessage(PermissionOutcome outcome) {
    final l10n = AppLocalizations.of(context);
    final label = l10n.recordingPermMissingNotifications;
    if (outcome.needsSettings) {
      return l10n.recordingPermBundleNeedsSettings(label);
    }
    return l10n.recordingPermBundleDenied(label);
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
                (s) => s.isPublic && s.isActive && s.playerId == widget.selfId,
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
      // MediaProjection morte (user a tapé Stop sur la notif système, ou
      // perm révoquée). Le service Kotlin a déjà teardown — on doit juste
      // propager au coord pour qu'il flippe son état + déclencher l'export.
      ..listen<AsyncValue<NativeLifecycleEvent>>(
        nativeLifecycleEventsStreamProvider,
        (_, next) {
          final evt = next.valueOrNull;
          if (evt == NativeLifecycleEvent.mediaProjectionDied) {
            final coord = ref.read(matchRecordingCoordinatorProvider);
            final s = coord.state;
            if (s is CoordinatorRecording || s is CoordinatorPaused) {
              unawaited(coord.stopCleanly());
            }
          } else if (evt == NativeLifecycleEvent.liveKitStopRequested) {
            // Tap "Arrêter" sur la notif (ou le bouton flottant) pendant une
            // capture LiveKit → on coupe la room (→ egress_ended serveur).
            final livekit = ref.read(liveKitCaptureServiceProvider);
            if (livekit.state is! LiveKitCaptureIdle) {
              unawaited(livekit.stop());
            }
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

    final nativeBanner = switch (coordState) {
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
      _ => null,
    };
    if (nativeBanner != null) return nativeBanner;

    // Provider LiveKit actif : bannière simple « enregistrement en cours »
    // (pas d'overlay/pause/forfait — capture publish-only enregistrée serveur).
    final livekitState = ref.watch(liveKitCaptureStateProvider).value ??
        const LiveKitCaptureIdle();
    if (livekitState is LiveKitCapturePublishing) {
      return _LifecycleBanner(
        icon: Icons.fiber_manual_record,
        color: ArenaColors.danger,
        text: l10n.recordingBannerRecording,
      );
    }

    return const SizedBox.shrink();
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
