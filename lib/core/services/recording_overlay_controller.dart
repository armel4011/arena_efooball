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
  // Émis quand l'AWAY OUVRE la vue lecture seule du code (clé) — le cycle de
  // vie déclenche alors un fetch REST frais du code (le Realtime peut être
  // tombé en arrière-plan dans eFootball).
  final _codeViewRequests = StreamController<void>.broadcast();
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
  // Vrai quand le HOME a ouvert la saisie du code room depuis le bouton
  // d'enregistrement (nouveau flux). L'overlay a été agrandi côté main et
  // affiche le champ inline. DOIT être propagé dans CHAQUE tick tant que la
  // saisie est ouverte, sinon le premier tick périodique refermerait le champ.
  bool _codeEntry = false;
  // Vrai quand l'AWAY a ouvert la VUE lecture seule du code (clé du bouton).
  bool _codeView = false;
  // Dernier code room connu (poussé par MatchRecordingLifecycle via le
  // Realtime) — affiché dans la vue AWAY, mis à jour en direct si le HOME
  // ré-envoie un nouveau code.
  String? _roomCode;
  // true = ce joueur est le HOME (la clé ouvre la SAISIE) ; false = AWAY
  // (la clé ouvre la VUE lecture seule + Copier).
  bool _canSendCode = true;

  /// Total length of a recording — must match `RecordingService.maxDuration`.
  /// Used by the overlay to flash a warning in the last 30 s.
  Duration totalDuration = const Duration(minutes: 25);

  /// Stream of typed actions raised inside the overlay (long-press menu).
  Stream<OverlayAction> get actions => _actions.stream;

  /// Codes room soumis depuis le panneau overlay code-sender (HOME).
  /// L'écran de partage du code s'y abonne pour appeler `setRoomCode`.
  Stream<String> get roomCodeSubmissions => _roomCodes.stream;

  /// Émis quand l'AWAY ouvre la vue lecture seule du code (tap sur la clé).
  /// `MatchRecordingLifecycle` s'y abonne pour rafraîchir le code (fetch REST).
  Stream<void> get codeViewRequests => _codeViewRequests.stream;

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
    if (_startedAt == null) return;
    _pushTickNow();
  }

  /// Pousse à l'overlay le code room courant + le rôle (HOME peut envoyer,
  /// AWAY est en lecture seule). Appelé par `MatchRecordingLifecycle` sur
  /// chaque mise à jour Realtime du match → la clé de l'AWAY reflète en
  /// direct tout nouveau code renvoyé par le HOME. No-op si rien n'a changé
  /// ou si l'overlay n'est pas affiché.
  // ignore: avoid_positional_boolean_parameters
  void setRoomCodeInfo(String? code, bool canSend) {
    if (_roomCode == code && _canSendCode == canSend) return;
    _roomCode = code;
    _canSendCode = canSend;
    if (_startedAt == null) return;
    _pushTickNow();
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

  /// Ouvre la saisie du code room DANS le bouton d'enregistrement (nouveau
  /// flux : le HOME envoie son code depuis le bouton rouge, sans quitter
  /// eFootball). Agrandit l'overlay pour loger le champ + clavier, puis
  /// pousse un tick immédiat `codeEntry:true` (le dispatcher rend le champ).
  /// Aucun re-`showOverlay` — juste un `resizeOverlay` (sûr, cf. quirk #4).
  Future<void> enterCodeEntry() async {
    if (_codeEntry) return;
    _codeEntry = true;
    await _platform.resizeToCodeEntry();
    // Remonter l'overlay en haut de l'écran : sinon, centré, le clavier
    // (moitié basse) recouvre le bouton ENVOYER (« coupé »).
    await _platform.moveToTop();
    _pushTickNow();
  }

  /// Referme la saisie du code : redonne au bouton sa taille 220×220 et
  /// pousse un tick `codeEntry:false`. Appelé après un envoi de code réussi.
  Future<void> exitCodeEntry() async {
    if (!_codeEntry) return;
    _codeEntry = false;
    await _platform.resizeToRecording();
    _pushTickNow();
  }

  /// Ouvre la VUE lecture seule du code (AWAY) : le code courant + « Copier ».
  /// Contrairement à la saisie, pas de clavier — la vue peut se rebuild à
  /// chaque tick pour refléter en direct un nouveau code renvoyé par le HOME.
  Future<void> enterCodeView() async {
    if (_codeView) return;
    _codeView = true;
    await _platform.resizeToCodeEntry();
    await _platform.moveToTop();
    _pushTickNow();
    // Demande un fetch REST frais du code : en arrière-plan (eFootball) le
    // Realtime peut être tombé → l'AWAY verrait un code périmé sinon.
    _codeViewRequests.add(null);
  }

  /// Referme la vue lecture seule → retour au bouton 220×220.
  Future<void> exitCodeView() async {
    if (!_codeView) return;
    _codeView = false;
    await _platform.resizeToRecording();
    _pushTickNow();
  }

  /// Pousse immédiatement un tick reflétant l'état courant (chrono +
  /// `codeEntry`), sans attendre le prochain Timer périodique. Utilisé par
  /// enter/exitCodeEntry pour un affichage instantané du champ / du bouton.
  void _pushTickNow() {
    final start = _startedAt;
    final elapsed =
        start == null ? Duration.zero : DateTime.now().difference(start);
    final remaining = totalDuration - elapsed;
    unawaited(
      _platform.shareData(
        _buildTick(
          elapsedSeconds: elapsed.inSeconds,
          warning: remaining <= const Duration(seconds: 30),
          paused: _pausedElapsed != null,
        ),
      ),
    );
  }

  /// Construit un payload de tick avec TOUT l'état courant (live, simple,
  /// codeEntry/codeView, roomCode, canSendCode). Centralisé pour qu'aucun
  /// point d'émission n'oublie un flag (ex. codeEntry qui refermait le champ).
  Map<String, dynamic> _buildTick({
    required int elapsedSeconds,
    required bool warning,
    bool paused = false,
  }) {
    return RecordingOverlayMessages.tick(
      elapsedSeconds: elapsedSeconds,
      warning: warning,
      paused: paused,
      liveAvailable: _liveAvailable,
      simple: _simpleMode,
      codeEntry: _codeEntry,
      codeView: _codeView,
      roomCode: _roomCode,
      canSendCode: _canSendCode,
    );
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
    _codeEntry = false;
    _codeView = false;
    _roomCode = null;
    _canSendCode = true;
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
      _buildTick(
        elapsedSeconds: _pausedElapsed!.inSeconds,
        warning: false,
        paused: true,
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
      _buildTick(
        elapsedSeconds: paused.inSeconds,
        warning: totalDuration - paused <= const Duration(seconds: 30),
      ),
    );
  }

  Future<void> dispose() async {
    await stop();
    await _actions.close();
    await _roomCodes.close();
    await _codeViewRequests.close();
  }

  /// Route un événement overlay→main : soit une soumission de code room
  /// (→ `roomCodeSubmissions`), soit une action du menu (→ `actions`).
  void _onOverlayEvent(Object? event) {
    final code = roomCodeFromMessage(event);
    if (code != null) {
      _roomCodes.add(code);
      // Envoi réussi → on referme la saisie et on rend au bouton sa taille.
      unawaited(exitCodeEntry());
      return;
    }
    // Tap sur la clé du bouton : le rôle décide — HOME (canSend) ouvre la
    // SAISIE, AWAY ouvre la VUE lecture seule + Copier. Affaire interne
    // overlay/resize, pas une OverlayAction (pause/forfait/…).
    if (_isMessage(event, RecordingOverlayMessages.askEnterCodeType)) {
      unawaited(_canSendCode ? enterCodeEntry() : enterCodeView());
      return;
    }
    // Bouton « Fermer » : referme la saisie OU la vue (celle qui est ouverte).
    if (_isMessage(event, RecordingOverlayMessages.askExitCodeType)) {
      unawaited(_codeView ? exitCodeView() : exitCodeEntry());
      return;
    }
    _actions.add(_parseAction(event));
  }

  static bool _isMessage(Object? event, String type) {
    if (event == type) return true;
    return event is Map && event['type'] == type;
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
        _buildTick(elapsedSeconds: elapsed.inSeconds, warning: isWarning),
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

  /// Redimensionne l'overlay AFFICHÉ au format saisie de code (fenêtre plus
  /// grande, NON draggable pour ne pas voler les taps du champ/bouton —
  /// quirk #3) — utilisé quand le HOME ouvre la saisie depuis le bouton rouge.
  Future<void> resizeToCodeEntry();

  /// Repositionne l'overlay en haut de l'écran (centré horizontalement) —
  /// utilisé à l'ouverture de la saisie pour que le clavier ne recouvre pas
  /// le champ / le bouton ENVOYER.
  Future<void> moveToTop();

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
  Future<void> resizeToCodeEntry() async {
    final dpr = PlatformDispatcher.instance.views.first.devicePixelRatio;
    // enableDrag: false — pendant la saisie, le handler de drag natif volerait
    // les taps du champ/bouton (quirk #3). Retour à draggable via
    // resizeToRecording quand la saisie se referme.
    // Fenêtre COMPACTE : eFootball tourne en paysage (écran court) — une
    // fenêtre trop haute déborde et « coupe » le bouton ENVOYER. La carte
    // inline compacte fait ~155 dp ; 190 laisse une petite marge.
    await FlutterOverlayWindow.resizeOverlay(
      (360 * dpr).round(),
      (190 * dpr).round(),
      false,
    );
  }

  @override
  Future<void> moveToTop() async {
    final view = PlatformDispatcher.instance.views.first;
    final dpr = view.devicePixelRatio;
    final screenW = view.physicalSize.width; // px
    final overlayW = 360 * dpr;
    final x = ((screenW - overlayW) / 2).clamp(0, screenW).toDouble();
    // Tout en haut (juste sous la barre de statut) pour laisser le maximum
    // de place au clavier en bas (paysage).
    final y = view.physicalSize.height * 0.02;
    await FlutterOverlayWindow.moveOverlay(OverlayPosition(x, y));
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
