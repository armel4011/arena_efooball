import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:arena/features_user/recording/overlay/recording_overlay_messages.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Action requested by the expanded menu inside the overlay isolate.
///
/// The main app subscribes via [RecordingOverlayController.actions] and
/// reacts (resume / pause → freeze auto-stop, saveAndStop → stop +
/// export MP4, forfeit → stop + mark forfeit).
enum OverlayAction {
  focusMain,
  resume,
  pause,
  forfeit,
  saveAndStop,
  goLive,
  unknown,
}

/// Drives the floating button rendered by `flutter_overlay_window`.
///
/// Owned by the main app (lives in the main isolate). Responsibilities:
///   * show / hide the overlay,
///   * emit a tick every second so the overlay's MM:SS timer stays in
///     sync without each isolate having to compute time independently,
///   * forward the user's long-press choices back as a typed
///     [OverlayAction] stream.
///
/// The 25-min auto-stop logic itself lives in `RecordingService` —
/// this controller is purely about the floating button's life cycle
/// and IPC.
class RecordingOverlayController {
  RecordingOverlayController({OverlayPlatform? platform})
      : _platform = platform ?? const _DefaultOverlayPlatform();

  final OverlayPlatform _platform;
  final _actions = StreamController<OverlayAction>.broadcast();
  // Codes room tapés par le HOME dans le panneau overlay code-sender.
  final _roomCodes = StreamController<String>.broadcast();
  // Vrai entre un show* et le stop() : permet au cycle de vie de choisir
  // entre morphToRecording (overlay déjà ouvert) et start (rien d'ouvert).
  bool _overlayShown = false;

  StreamSubscription<dynamic>? _listener;
  ReceivePort? _port;
  StreamSubscription<dynamic>? _portSub;
  Timer? _tickTimer;
  DateTime? _startedAt;
  // While paused: Duration the chronometer was at when the user paused.
  // null while running. Set in pause(), cleared in resume() after rebasing
  // _startedAt so the next ticks resume from the same MM:SS.
  Duration? _pausedElapsed;
  // Vrai quand l'admin a flag le match pour la diffusion live et que
  // c'est self (vu côté Riverpod par MatchRecordingLifecycle qui pousse
  // l'info via `setLiveAvailable`). Propagé dans chaque tick payload —
  // l'overlay isolate affiche son 5ᵉ mini button "Live" en fonction.
  bool _liveAvailable = false;
  // Mode simplifié (capture LiveKit Track Egress) : l'overlay ne montre que
  // « ouvrir ARENA » + « stop ». Propagé dans chaque tick payload.
  bool _simpleMode = false;

  /// Total length of a recording — must match `RecordingService.maxDuration`.
  /// Used by the overlay to flash a warning in the last 30 s.
  Duration totalDuration = const Duration(minutes: 25);

  /// Stream of typed actions raised inside the overlay (long-press menu).
  Stream<OverlayAction> get actions => _actions.stream;

  /// Codes room soumis depuis le panneau overlay code-sender (HOME).
  /// L'écran de partage du code s'y abonne pour appeler `setRoomCode`.
  Stream<String> get roomCodeSubmissions => _roomCodes.stream;

  /// Vrai tant qu'un overlay (code-sender OU recording) est affiché. Le
  /// cycle de vie l'inspecte : si `true` au passage in_progress, on
  /// `morphToRecording()` au lieu de `start()` (quirk MIUI #4 : ne jamais
  /// re-`showOverlay`).
  bool get isShowing => _overlayShown;

  /// Bascule l'éligibilité streaming de la session courante. Appelé
  /// depuis `MatchRecordingLifecycle` quand le provider
  /// `matchStreamsByMatchProvider` détecte qu'une row stream
  /// `is_public + is_active` ownée par self existe. L'overlay reçoit
  /// le flag via le prochain tick et affiche/cache son 5ᵉ mini button.
  // ignore: avoid_positional_boolean_parameters
  void setLiveAvailable(bool value) {
    if (_liveAvailable == value) return;
    _liveAvailable = value;
    // Push immédiat pour éviter d'attendre 1 s le prochain Timer tick.
    final start = _startedAt;
    if (start == null) return;
    final elapsed = DateTime.now().difference(start);
    final remaining = totalDuration - elapsed;
    unawaited(
      _platform.shareData(
        RecordingOverlayMessages.tick(
          elapsedSeconds: elapsed.inSeconds,
          warning: remaining <= const Duration(seconds: 30),
          paused: _pausedElapsed != null,
          liveAvailable: _liveAvailable,
          simple: _simpleMode,
        ),
      ),
    );
  }

  /// Shows the floating button and starts the per-second tick.
  ///
  /// [matchId] is currently unused but accepted so the API stays
  /// stable when we wire deep-link "tap on overlay → open match-room"
  /// in PHASE 8.5.
  Future<void> start({String? matchId, bool simpleMode = false}) async {
    if (!await _ensurePermission()) return;

    _simpleMode = simpleMode;
    await _platform.showOverlay();
    _overlayShown = true;
    _startedAt = DateTime.now();
    _bindListener();
    _bindIsolatePort();
    // Bascule immédiate en mode recording pour que le bouton apparaisse sans
    // attendre le 1er tick périodique (le dispatcher ne rend rien tant qu'il
    // n'a pas reçu de mode). Belt-and-braces : le tick suivant le confirme.
    await _platform.shareData(RecordingOverlayMessages.modeRecording());
    _startTicking();
  }

  /// Affiche l'overlay en mode « saisie du code room » (HOME, à l'étape
  /// partage du code, AVANT que l'enregistrement ne démarre). Renvoie
  /// `false` si la permission overlay est refusée.
  ///
  /// Un heartbeat pousse `mode_code_sender` chaque seconde : contrairement
  /// au mode recording (ticks périodiques), le panneau code-sender n'a pas
  /// de flux périodique, donc si le tout premier message court-circuite le
  /// spawn de l'isolate le panneau resterait vide — le heartbeat garantit
  /// son affichage (le dispatcher ignore les répétitions sans changement).
  Future<bool> showAsCodeSender({String? matchId}) async {
    if (!await _ensurePermission()) return false;
    await _platform.showCodeSenderOverlay();
    _overlayShown = true;
    _bindListener();
    _bindIsolatePort();
    _startCodeSenderHeartbeat();
    return true;
  }

  /// Transforme l'overlay code-sender déjà affiché en bouton
  /// d'enregistrement — SANS re-`showOverlay` (quirk MIUI #4). No-op si
  /// aucun overlay n'est réellement affiché (l'appelant fait alors `start()`).
  ///
  /// On teste l'état RÉEL du natif (`isActive`) et pas seulement le mémoire
  /// `_overlayShown` : si le process principal a été recréé (MIUI) alors que
  /// la fenêtre overlay survivait, `_overlayShown` est repassé à `false` à
  /// tort — morpher reste le bon geste (re-`showOverlay` tuerait l'isolate).
  Future<void> morphToRecording({bool simpleMode = false}) async {
    if (!_overlayShown && !await _platform.isActive()) return;
    _overlayShown = true;
    _simpleMode = simpleMode;
    // Après une recréation du process, les canaux overlay→main (listener +
    // port isolate) ont été perdus alors que la fenêtre native survivait :
    // on les (re)lie de façon idempotente pour que les taps du bouton
    // recording (stop/pause/forfait) remontent bien. No-op si déjà liés.
    _bindListener();
    _bindIsolatePort();
    await _platform.resizeToRecording();
    _startedAt = DateTime.now();
    await _platform.shareData(RecordingOverlayMessages.modeRecording());
    // Remplace le heartbeat code-sender par les ticks recording.
    _startTicking();
  }

  /// Démarre le bouton d'enregistrement, OU transforme l'overlay
  /// code-sender déjà affiché (HOME) — sans re-`showOverlay` (quirk MIUI
  /// #4). Point d'entrée unique pour le coordinator natif et LiveKit.
  ///
  /// La décision se base sur l'état RÉEL du natif (`isActive`) plutôt que sur
  /// le seul `_overlayShown` mémoire : sinon, après une recréation du process
  /// (MIUI tue l'app pendant eFootball), on croirait à tort qu'aucun overlay
  /// n'est affiché → 2ᵉ `showOverlay` → mort de l'isolate → panneau figé.
  Future<void> startOrMorphToRecording({
    String? matchId,
    bool simpleMode = false,
  }) async {
    var overlayLive = _overlayShown;
    if (!overlayLive) {
      try {
        overlayLive = await _platform.isActive();
      } catch (_) {
        overlayLive = false;
      }
    }
    if (overlayLive) {
      await morphToRecording(simpleMode: simpleMode);
    } else {
      await start(matchId: matchId, simpleMode: simpleMode);
    }
  }

  Future<bool> _ensurePermission() async {
    final granted = await _platform.isPermissionGranted();
    if (granted) return true;
    final ok = await _platform.requestPermission();
    if (!ok && kDebugMode) {
      debugPrint('[overlay] user denied SYSTEM_ALERT_WINDOW permission');
    }
    return ok;
  }

  void _startCodeSenderHeartbeat() {
    _tickTimer?.cancel();
    // Push immédiat + répétition 1 s (voir showAsCodeSender).
    unawaited(_platform.shareData(RecordingOverlayMessages.modeCodeSender()));
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _platform.shareData(RecordingOverlayMessages.modeCodeSender());
    });
  }

  /// Hides the overlay and stops the tick timer.
  Future<void> stop() async {
    _tickTimer?.cancel();
    _tickTimer = null;
    _startedAt = null;
    _pausedElapsed = null;
    _liveAvailable = false;
    _simpleMode = false;
    await _listener?.cancel();
    _listener = null;
    await _portSub?.cancel();
    _portSub = null;
    _port?.close();
    _port = null;
    IsolateNameServer.removePortNameMapping(
      RecordingOverlayMessages.mainPortName,
    );
    _overlayShown = false;
    await _platform.closeOverlay();
  }

  /// Freezes the chronometer in the overlay isolate and pushes a
  /// `paused` tick so the floating button switches to the yellow
  /// "PAUSE" face. Idempotent.
  Future<void> pause() async {
    final start = _startedAt;
    if (start == null || _pausedElapsed != null) return;
    _pausedElapsed = DateTime.now().difference(start);
    await _platform.shareData(
      RecordingOverlayMessages.tick(
        elapsedSeconds: _pausedElapsed!.inSeconds,
        warning: false,
        paused: true,
        simple: _simpleMode,
      ),
    );
  }

  /// Resumes the chronometer from the paused MM:SS without losing the
  /// elapsed time accumulated before the pause. Idempotent.
  Future<void> resume() async {
    final paused = _pausedElapsed;
    if (paused == null) return;
    // Rebase the start anchor so DateTime.now() - _startedAt == paused
    // immediately after resume — keeps the existing tick formula intact.
    _startedAt = DateTime.now().subtract(paused);
    _pausedElapsed = null;
    // Push an immediate tick so the overlay UI flips to red without
    // waiting for the next 1-second period.
    await _platform.shareData(
      RecordingOverlayMessages.tick(
        elapsedSeconds: paused.inSeconds,
        warning: totalDuration - paused <= const Duration(seconds: 30),
        simple: _simpleMode,
      ),
    );
  }

  Future<void> dispose() async {
    await stop();
    await _actions.close();
    await _roomCodes.close();
  }

  /// Route un événement overlay→main : soit une soumission de code room
  /// (→ `roomCodeSubmissions`), soit une action du menu (→ `actions`).
  void _onOverlayEvent(Object? event) {
    final code = roomCodeFromMessage(event);
    if (code != null) {
      _roomCodes.add(code);
      return;
    }
    _actions.add(_parseAction(event));
  }

  void _bindListener() {
    _listener?.cancel();
    _listener = _platform.overlayListener.listen(_onOverlayEvent);
  }

  /// Registers a `ReceivePort` so the overlay isolate can deliver
  /// action strings via `SendPort.send`. This is the resilient
  /// fallback to `flutter_overlay_window`'s `shareData` channel which
  /// stops delivering on MIUI / Android 12+ once the main activity is
  /// paused.
  void _bindIsolatePort() {
    // Defensive: drop any leftover mapping from a previous run.
    IsolateNameServer.removePortNameMapping(
      RecordingOverlayMessages.mainPortName,
    );
    final port = ReceivePort();
    final registered = IsolateNameServer.registerPortWithName(
      port.sendPort,
      RecordingOverlayMessages.mainPortName,
    );
    if (!registered && kDebugMode) {
      debugPrint('[overlay-ctrl] failed to register isolate port');
    }
    _port = port;
    _portSub = port.listen(_onOverlayEvent);
  }

  void _startTicking() {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      // While paused, _pausedElapsed is non-null and pause() already
      // pushed the frozen frame — skip until resume() reseats _startedAt.
      if (_pausedElapsed != null) return;
      final start = _startedAt;
      if (start == null) return;
      final elapsed = DateTime.now().difference(start);
      final remaining = totalDuration - elapsed;
      final isWarning = remaining <= const Duration(seconds: 30);
      _platform.shareData(
        RecordingOverlayMessages.tick(
          elapsedSeconds: elapsed.inSeconds,
          warning: isWarning,
          liveAvailable: _liveAvailable,
          simple: _simpleMode,
        ),
      );
    });
  }

  static OverlayAction _parseAction(Object? event) {
    final raw = event is String ? event : event?.toString();
    return switch (raw) {
      RecordingOverlayMessages.focusMainType => OverlayAction.focusMain,
      RecordingOverlayMessages.askResumeType => OverlayAction.resume,
      RecordingOverlayMessages.askPauseType => OverlayAction.pause,
      RecordingOverlayMessages.askForfeitType => OverlayAction.forfeit,
      RecordingOverlayMessages.askSaveStopType => OverlayAction.saveAndStop,
      RecordingOverlayMessages.askGoLiveType => OverlayAction.goLive,
      _ => OverlayAction.unknown,
    };
  }
}

/// Seam over `flutter_overlay_window` static API for tests.
abstract class OverlayPlatform {
  Future<bool> isPermissionGranted();
  Future<bool> requestPermission();

  /// Vrai si une fenêtre overlay native est actuellement affichée. Reflète
  /// l'état RÉEL du service overlay — il survit à une recréation du process
  /// principal (MIUI tue l'app en arrière-plan pendant eFootball), là où
  /// l'état mémoire `_overlayShown` du controller, lui, est perdu.
  Future<bool> isActive();

  /// Affiche l'overlay au format bouton d'enregistrement (220×220).
  Future<void> showOverlay();

  /// Affiche l'overlay au format panneau code-sender (fenêtre plus grande,
  /// non draggable pour ne pas voler les taps du champ/bouton — quirk #3).
  Future<void> showCodeSenderOverlay();

  /// Redimensionne l'overlay AFFICHÉ au format bouton d'enregistrement
  /// (220×220, draggable) — utilisé par le morph, sans re-show.
  Future<void> resizeToRecording();

  Future<void> closeOverlay();
  Future<void> shareData(Object data);
  Stream<dynamic> get overlayListener;
}

class _DefaultOverlayPlatform implements OverlayPlatform {
  const _DefaultOverlayPlatform();

  @override
  Future<bool> isPermissionGranted() {
    return FlutterOverlayWindow.isPermissionGranted();
  }

  @override
  Future<bool> requestPermission() async {
    final res = await FlutterOverlayWindow.requestPermission();
    return res ?? false;
  }

  @override
  Future<bool> isActive() async {
    return FlutterOverlayWindow.isActive();
  }

  @override
  Future<void> showOverlay() {
    // `flutter_overlay_window` interprets width/height as raw pixels, not
    // dp. On a 3x density display 220 px is only ~73 dp — the four mini
    // buttons (offset 64 dp from the centre of the cluster) would render
    // outside the native window and stay invisible. Scale by the device
    // pixel ratio so the rendered SizedBox(220, 220) actually fits.
    final dpr = PlatformDispatcher.instance.views.first.devicePixelRatio;
    final sizePx = (220 * dpr).round();
    return FlutterOverlayWindow.showOverlay(
      enableDrag: true,
      positionGravity: PositionGravity.auto,
      width: sizePx,
      height: sizePx,
      overlayTitle: 'ARENA',
      overlayContent: 'Enregistrement en cours',
    );
  }

  @override
  Future<void> showCodeSenderOverlay() {
    // Fenêtre plus grande que le bouton (champ + badge). `defaultFlag` :
    // `showOverlay(focusPointer)` ne s'attache pas sur MIUI — l'overlay
    // isolate bascule focusPointer via updateFlag pendant la saisie
    // (spike-validé). `enableDrag: false` pour ne pas voler les taps du
    // champ/bouton (quirk #3). Taille en px = dp × devicePixelRatio.
    final dpr = PlatformDispatcher.instance.views.first.devicePixelRatio;
    return FlutterOverlayWindow.showOverlay(
      enableDrag: false,
      flag: OverlayFlag.defaultFlag,
      alignment: OverlayAlignment.center,
      positionGravity: PositionGravity.none,
      width: (360 * dpr).round(),
      height: (380 * dpr).round(),
      overlayTitle: 'ARENA',
      overlayContent: 'Envoi du code room',
    );
  }

  @override
  Future<void> resizeToRecording() async {
    final dpr = PlatformDispatcher.instance.views.first.devicePixelRatio;
    final sizePx = (220 * dpr).round();
    await FlutterOverlayWindow.resizeOverlay(sizePx, sizePx, true);
  }

  @override
  Future<void> closeOverlay() async {
    await FlutterOverlayWindow.closeOverlay();
  }

  @override
  Future<void> shareData(Object data) async {
    await FlutterOverlayWindow.shareData(data);
  }

  @override
  Stream<dynamic> get overlayListener => FlutterOverlayWindow.overlayListener;
}

final recordingOverlayControllerProvider =
    Provider<RecordingOverlayController>((ref) {
  final controller = RecordingOverlayController();
  ref.onDispose(controller.dispose);
  return controller;
});
