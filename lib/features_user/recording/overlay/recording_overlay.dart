import 'dart:ui';

import 'package:arena/core/theme/arena_colors.dart';
import 'package:arena/features_user/recording/overlay/recording_overlay_messages.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

/// Floating window rendered on top of eFootball / the game. Lives in its
/// own Flutter isolate spawned by `flutter_overlay_window` — it cannot
/// read providers from the main app, so all state arrives through
/// `FlutterOverlayWindow.shareData` / `overlayListener`.
///
/// A SINGLE overlay window (one `showOverlay` per match) carries two
/// faces, chosen by [ArenaOverlayRoot] from the mode messages:
///   * [OverlayMode.codeSender] → [RoomCodeOverlayPanel] : the HOME types
///     the eFootball room code without leaving the game (before the match
///     starts).
///   * [OverlayMode.recording] → [RecordingOverlayButton] : the anti-cheat
///     floating button (4-mini cardinal cluster + chrono).
///
/// The two faces never coexist and the window is never re-shown between
/// them (MIUI quirk #4 : a 2nd `closeOverlay → showOverlay` cycle breaks
/// the isolate). The code-sender morphs into the recording button via
/// `resizeOverlay` + a `mode_recording` message. See
/// `_anticheat_ref/PLAN_OVERLAY_CODE_ROOM.md`.
class RecordingOverlayApp extends StatelessWidget {
  const RecordingOverlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Material(
        color: Colors.transparent,
        child: Center(child: ArenaOverlayRoot()),
      ),
    );
  }
}

/// Sends a message from the overlay isolate back to the main app.
///
/// Primary route — Dart-native `SendPort` looked up in `IsolateNameServer`
/// — is reliable even when ARENA is paused (MIUI / Android 12+), where the
/// plugin's `shareData → overlayListener` channel silently drops events.
/// The `shareData` call is kept belt-and-braces (harmless duplicate; the
/// main-side handlers are idempotent).
Future<void> sendToMain(Object message) async {
  final port =
      IsolateNameServer.lookupPortByName(RecordingOverlayMessages.mainPortName);
  if (port != null) {
    port.send(message);
  } else if (kDebugMode) {
    debugPrint('[overlay] main port not registered, falling back');
  }
  await FlutterOverlayWindow.shareData(message);
}

/// Sole subscriber of `FlutterOverlayWindow.overlayListener` (which is a
/// single-subscription stream — quirk #4). Tracks the current [OverlayMode]
/// and the latest recording tick, and dispatches to the right face. The
/// recording button therefore receives its tick as a prop rather than
/// listening itself (two listeners on the stream would throw).
class ArenaOverlayRoot extends StatefulWidget {
  const ArenaOverlayRoot({super.key});

  @override
  State<ArenaOverlayRoot> createState() => _ArenaOverlayRootState();
}

class _ArenaOverlayRootState extends State<ArenaOverlayRoot> {
  // Null until the main app pushes the first mode / tick. Rendering nothing
  // in the meantime avoids a flash of the wrong face.
  OverlayMode? _mode;
  OverlayTick _tick = const OverlayTick(elapsedSeconds: 0, isWarning: false);

  @override
  void initState() {
    super.initState();
    FlutterOverlayWindow.overlayListener.listen(_onMessage);
  }

  void _onMessage(Object? event) {
    if (!mounted) return;
    final mode = overlayModeFromMessage(event);
    // Only tick-shaped payloads carry a chrono; mode-only messages (e.g. the
    // 1 Hz code-sender heartbeat) leave the last tick untouched.
    final tick = (event is Map && _isTickPayload(event))
        ? OverlayTick.fromMap(event)
        : null;
    final modeChanged = mode != null && mode != _mode;

    // Pendant la saisie du code OU du score, un tick chrono arrive chaque
    // seconde. Reconstruire les TextField à chaque tick leur ferait perdre
    // focus/clavier (champ figé, impossible d'y taper deux valeurs) — et côté
    // score, ne jamais pouvoir poser un score à ÉGALITÉ ⇒ le volet pénaltys
    // (qui n'apparaît qu'à égalité) ne sortait JAMAIS. On met donc à jour
    // `_tick` SANS setState tant que la saisie reste ouverte ; on ne rebuild
    // qu'à l'ouverture / fermeture (transition du flag ou changement de mode).
    if (tick != null &&
        !modeChanged &&
        ((_tick.isCodeEntry && tick.isCodeEntry) ||
            (_tick.isScoreEntry && tick.isScoreEntry))) {
      _tick = tick;
      return;
    }

    // Skip rebuilds when nothing changed — avoids re-rendering the code-sender
    // panel (and any focus/keyboard flicker) on every heartbeat tick.
    if (!modeChanged && tick == null) return;
    setState(() {
      if (mode != null) _mode = mode;
      if (tick != null) _tick = tick;
    });
  }

  bool _isTickPayload(Map<dynamic, dynamic> event) {
    final type = event['type'];
    return type == RecordingOverlayMessages.tickType ||
        type == RecordingOverlayMessages.warnType ||
        type == RecordingOverlayMessages.pausedType;
  }

  Future<void> _onCodeSubmitted(String code) async {
    await sendToMain(RecordingOverlayMessages.submitRoomCode(code));
  }

  // Focusable window steals input focus (dims the game, hides other apps'
  // keyboards) — so we only request focus WHILE the field is focused, then
  // drop back to defaultFlag. `showOverlay(focusPointer)` doesn't even
  // attach on MIUI, but `updateFlag` on a live window does. Spike-validated.
  Future<void> _onFieldFocusChange(bool hasFocus) async {
    await FlutterOverlayWindow.updateFlag(
      hasFocus ? OverlayFlag.focusPointer : OverlayFlag.defaultFlag,
    );
  }

  @override
  Widget build(BuildContext context) {
    return switch (_mode) {
      OverlayMode.codeSender => RoomCodeOverlayPanel(
          onSubmit: _onCodeSubmitted,
          onFocusChange: _onFieldFocusChange,
        ),
      OverlayMode.recording => RecordingOverlayButton(
          tick: _tick,
          onSubmitCode: _onCodeSubmitted,
          onFieldFocusChange: _onFieldFocusChange,
        ),
      null => const SizedBox.shrink(),
    };
  }
}

/// Champ de saisie du code room réutilisable — carte compacte (titre +
/// champ + « Envoyer » + badge « Envoyé »). Widget PUR : l'IPC (`onSubmit`)
/// et le toggle de flag focus (`onFocusChange`) sont injectés, donc testable
/// sans platform channel. Utilisé à deux endroits :
///   * inline dans [RecordingOverlayButton] quand `tick.isCodeEntry` (nouveau
///     flux : le HOME envoie son code depuis le bouton rouge) — `timerLabel`
///     affiche alors le chrono d'enregistrement en tête ;
///   * via [RoomCodeOverlayPanel] (mode code-sender legacy, sans timer).
class RoomCodeField extends StatefulWidget {
  const RoomCodeField({
    required this.onSubmit,
    required this.onFocusChange,
    this.timerLabel,
    this.onClose,
    this.readOnlyCode,
    super.key,
  });

  /// Called with the normalised (trimmed, upper-cased) code when the user
  /// taps "Envoyer" and the code passes the 4–12 length check.
  final void Function(String code) onSubmit;

  /// Côté EXTÉRIEUR : le code REÇU de l'hôte. Non nul ⇒ le champ passe en
  /// **lecture seule** (même carte que le HOME, mais texte non modifiable et
  /// pas de bouton « Envoyer » — juste « Fermer »). Nul ⇒ champ de saisie
  /// normal (le HOME tape et envoie son code).
  final String? readOnlyCode;

  /// Called when the text field gains / loses focus, so the host can flip
  /// the overlay window flag (focusPointer ↔ defaultFlag). Positional bool
  /// mirrors the `Focus.onFocusChange` signature it wraps.
  // ignore: avoid_positional_boolean_parameters
  final Future<void> Function(bool hasFocus) onFocusChange;

  /// Chrono d'enregistrement (MM:SS) affiché en tête quand le champ est
  /// rendu inline dans le bouton rouge. `null` = pas de bandeau chrono.
  final String? timerLabel;

  /// Referme la saisie sans envoyer (bouton « Fermer »). `null` = pas de
  /// bouton fermer (mode panneau legacy).
  final VoidCallback? onClose;

  @override
  State<RoomCodeField> createState() => _RoomCodeFieldState();
}

class _RoomCodeFieldState extends State<RoomCodeField> {
  final _controller = TextEditingController();
  String? _sentCode;
  bool _tooShort = false;

  bool get _readOnly => widget.readOnlyCode != null;

  @override
  void initState() {
    super.initState();
    // EXTÉRIEUR : pré-remplit le champ (lecture seule) avec le code reçu.
    if (widget.readOnlyCode != null) _controller.text = widget.readOnlyCode!;
  }

  @override
  void didUpdateWidget(RoomCodeField old) {
    super.didUpdateWidget(old);
    // L'hôte peut changer le code (realtime) → rafraîchir le champ lecture seule.
    if (widget.readOnlyCode != null &&
        widget.readOnlyCode != old.readOnlyCode) {
      _controller.text = widget.readOnlyCode!;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final code = _controller.text.trim().toUpperCase();
    if (code.length < 4 || code.length > 12) {
      setState(() => _tooShort = true);
      return;
    }
    widget.onSubmit(code);
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _sentCode = code;
      _tooShort = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final timer = widget.timerLabel;
    // Mode inline (dans le bouton rouge, par-dessus eFootball) : eFootball
    // tourne en PAYSAGE (écran court) → carte COMPACTE, sinon ENVOYER déborde
    // hors de l'écran (« coupé »). Titre + chrono sur une ligne, pas de
    // sous-titre, ENVOYER + Fermer côte à côte.
    final compact = timer != null;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Container(
          margin: EdgeInsets.all(compact ? 6 : 8),
          padding: EdgeInsets.all(compact ? 10 : 14),
          decoration: BoxDecoration(
            color: ArenaColors.void_.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ArenaColors.gameEfoot, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (timer != null) ...[
                    const Icon(
                      Icons.fiber_manual_record,
                      color: ArenaColors.danger,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timer,
                      style: const TextStyle(
                        color: ArenaColors.danger,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Flexible(
                    child: Text(
                      _readOnly ? "Code reçu de l'hôte" : 'Code de la room',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              if (!compact) ...[
                const SizedBox(height: 4),
                Text(
                  _readOnly
                      ? 'Ouvre eFootball et rejoins la room avec ce code.'
                      : 'Tape le code eFootball et envoie-le à ton adversaire, '
                          'sans quitter le jeu.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ],
              SizedBox(height: compact ? 8 : 10),
              Focus(
                onFocusChange: widget.onFocusChange,
                child: TextField(
                  controller: _controller,
                  autofocus: false,
                  readOnly: _readOnly,
                  showCursor: !_readOnly,
                  maxLength: 12,
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: _readOnly ? null : 'ABC123',
                    hintStyle: const TextStyle(
                      color: Colors.white24,
                      letterSpacing: 3,
                    ),
                    filled: true,
                    fillColor: Colors.white10,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: ArenaColors.gameEfoot),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: ArenaColors.gameEfoot,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
              if (_tooShort) ...[
                const SizedBox(height: 4),
                const Text(
                  'Le code doit faire 4 à 12 caractères.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: ArenaColors.neonRed, fontSize: 11),
                ),
              ],
              SizedBox(height: compact ? 8 : 10),
              // EXTÉRIEUR (lecture seule) : pas d'« Envoyer », juste « Fermer »
              // pleine largeur. HOME : « Envoyer » (+ « Fermer » si fourni).
              if (_readOnly)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.onClose,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          'Fermer',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: ArenaColors.gameEfoot,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _submit,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Text(
                                'ENVOYER',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (widget.onClose != null) ...[
                      const SizedBox(width: 8),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: widget.onClose,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Text(
                              'Fermer',
                              style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              if (_sentCode != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: ArenaColors.statusOk.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Envoyé : $_sentCode',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: ArenaColors.statusOk,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Code-sender face (mode legacy) : la carte plein panneau réutilisant
/// [RoomCodeField]. Conservée pour le mode `OverlayMode.codeSender` ; le
/// nouveau flux passe par la saisie inline du bouton d'enregistrement.
class RoomCodeOverlayPanel extends StatelessWidget {
  const RoomCodeOverlayPanel({
    required this.onSubmit,
    required this.onFocusChange,
    super.key,
  });

  final void Function(String code) onSubmit;
  // ignore: avoid_positional_boolean_parameters
  final Future<void> Function(bool hasFocus) onFocusChange;

  @override
  Widget build(BuildContext context) {
    return RoomCodeField(onSubmit: onSubmit, onFocusChange: onFocusChange);
  }
}

/// Recording face : the anti-cheat floating button.
///
/// Gestures — collapsed: tap → expand into a 4-mini-button cardinal cluster
/// (N pause / E open ARENA / S save+stop / W forfeit). Expanded: tap on the
/// main button → collapse; tap on a mini → send the action and auto-collapse.
///
/// Taps are wired through `Listener.onPointerDown` rather than
/// `GestureDetector.onTap`: the native drag handler in
/// `flutter_overlay_window` claims ACTION_MOVE on any micro-jitter, which
/// makes Flutter's gesture arena cancel `onTap` before it can fire.
/// `Listener` sits below the arena and fires synchronously on touch-down.
///
/// Receives its tick from [ArenaOverlayRoot] (the sole stream subscriber)
/// rather than listening to `overlayListener` itself.
class RecordingOverlayButton extends StatefulWidget {
  const RecordingOverlayButton({
    required this.tick,
    required this.onSubmitCode,
    required this.onFieldFocusChange,
    super.key,
  });

  final OverlayTick tick;

  /// Appelé avec le code normalisé quand le HOME l'envoie depuis la saisie
  /// inline (nouveau flux). Route vers `submit_room_code` → main.
  final void Function(String code) onSubmitCode;

  /// Toggle du flag focus pendant l'édition du champ (focusPointer ↔
  /// defaultFlag), comme pour [RoomCodeField].
  // ignore: avoid_positional_boolean_parameters
  final Future<void> Function(bool hasFocus) onFieldFocusChange;

  @override
  State<RecordingOverlayButton> createState() => _RecordingOverlayButtonState();
}

class _RecordingOverlayButtonState extends State<RecordingOverlayButton> {
  static const double _mainSize = 72;
  // Distance between the main button center and a mini button center.
  // The overlay window is 220×220 — a 40 dp mini at radius 64 around a
  // 72 dp main fits with a 14 dp gutter to the window edge.
  static const double _miniRadius = 64;

  bool _expanded = false;

  OverlayTick get _tick => widget.tick;

  void _onMainTap() {
    setState(() => _expanded = !_expanded);
  }

  Future<void> _onMiniTap(String message) async {
    setState(() => _expanded = false);
    await sendToMain(message);
  }

  Color get _mainColor {
    if (_tick.isPaused) return ArenaColors.warning;
    if (_tick.isWarning) return ArenaColors.warning;
    return ArenaColors.danger;
  }

  IconData get _mainIcon {
    if (_tick.isPaused) return Icons.pause;
    return Icons.fiber_manual_record;
  }

  @override
  Widget build(BuildContext context) {
    // Saisie du code inline (le HOME envoie son code depuis le bouton rouge).
    // L'overlay a été agrandi côté main (resizeToCodeEntry) ; on rend la même
    // carte que le panneau, avec le chrono en tête.
    if (_tick.isScoreEntry) {
      return ScoreEntryField(
        allowPenalties: _tick.allowPenalties,
        timerLabel: _tick.formatted,
        onFocusChange: widget.onFieldFocusChange,
        onClose: () => sendToMain(RecordingOverlayMessages.askExitScoreType),
        onSubmit: (my, opp, viaPen, myPen, oppPen) => sendToMain(
          RecordingOverlayMessages.submitScore(
            my: my,
            opp: opp,
            viaPenalties: viaPen,
            myPen: myPen,
            oppPen: oppPen,
          ),
        ),
      );
    }
    if (_tick.isCodeEntry) {
      return RoomCodeField(
        onSubmit: widget.onSubmitCode,
        onFocusChange: widget.onFieldFocusChange,
        timerLabel: _tick.formatted,
        onClose: () => sendToMain(RecordingOverlayMessages.askExitCodeType),
        // EXTÉRIEUR : `roomCode` reçu ⇒ champ en LECTURE SEULE (affiche le code).
        // HOME : `roomCode` null ⇒ champ de SAISIE (tape + envoie).
        readOnlyCode: _tick.roomCode,
      );
    }
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // SW « envoyer le code » — nouveau flux : le HOME, déjà en train
          // d'enregistrer, ouvre la saisie du code room. Masqué en mode simple
          // (LiveKit egress n'a pas de bouton flottant de code).
          // SW « code room » — MÊME clé et MÊME geste des deux côtés : elle ouvre
          // la carte du code. HOME → champ de SAISIE (tape + envoie) ; EXTÉRIEUR
          // (roomCode reçu) → même carte en LECTURE SEULE (affiche le code reçu).
          // Masquée en mode simple (LiveKit egress n'a pas de code room).
          _MiniButton(
            visible: _expanded && !_tick.isSimple,
            offset: const Offset(-_miniRadius * 0.707, _miniRadius * 0.707),
            icon: Icons.vpn_key,
            color: ArenaColors.gameEfoot,
            onTap: () => _onMiniTap(RecordingOverlayMessages.askEnterCodeType),
          ),
          // 4 cardinals — N pause / E focus / S save+stop / W forfeit.
          // IgnorePointer + opacity 0 while collapsed so they don't eat
          // touches around the main button.
          // N pause/resume — natif uniquement (la capture LiveKit egress ne
          // se met pas en pause). Masqué en mode simple.
          _MiniButton(
            visible: _expanded && !_tick.isSimple,
            offset: const Offset(0, -_miniRadius),
            icon: _tick.isPaused ? Icons.play_arrow : Icons.pause,
            color: _tick.isPaused ? ArenaColors.success : ArenaColors.warning,
            onTap: () => _onMiniTap(
              _tick.isPaused
                  ? RecordingOverlayMessages.askResumeType
                  : RecordingOverlayMessages.askPauseType,
            ),
          ),
          // E ouvrir ARENA — commun aux deux modes.
          _MiniButton(
            visible: _expanded,
            offset: const Offset(_miniRadius, 0),
            icon: Icons.open_in_new,
            color: ArenaColors.signalBlue,
            onTap: () => _onMiniTap(RecordingOverlayMessages.focusMainType),
          ),
          // S — natif : « Score » → ouvre le formulaire (score = fin du match :
          // le main arrête + scelle la preuve + envoie le score). Simple
          // (LiveKit egress) : « arrêter » (askSaveStop, pas de saisie de score).
          _MiniButton(
            visible: _expanded,
            offset: const Offset(0, _miniRadius),
            icon: _tick.isSimple ? Icons.stop : Icons.scoreboard_outlined,
            color: _tick.isSimple ? ArenaColors.danger : ArenaColors.success,
            onTap: () => _onMiniTap(
              _tick.isSimple
                  ? RecordingOverlayMessages.askSaveStopType
                  : RecordingOverlayMessages.askEnterScoreType,
            ),
          ),
          // W forfait — natif uniquement. Masqué en mode simple.
          _MiniButton(
            visible: _expanded && !_tick.isSimple,
            offset: const Offset(-_miniRadius, 0),
            icon: Icons.stop_circle_outlined,
            color: ArenaColors.danger,
            onTap: () => _onMiniTap(RecordingOverlayMessages.askForfeitType),
          ),
          // 5ᵉ mini "Live" en diagonale NE — visible seulement quand le
          // main isolate signale que l'admin a flag ce match pour la
          // diffusion (`liveAvailable` dans le tick payload). Tap → le
          // coordinator stoppe le recording puis appelle joinAsBroadcaster
          // (Android 14+ refuse 2 MediaProjection simultanées, cf. mémoire
          // mediaprojection_constraints).
          _MiniButton(
            visible: _expanded && _tick.isLiveAvailable && !_tick.isSimple,
            offset: const Offset(_miniRadius * 0.707, -_miniRadius * 0.707),
            icon: Icons.live_tv,
            color: ArenaColors.danger,
            onTap: () => _onMiniTap(RecordingOverlayMessages.askGoLiveType),
          ),
          // Main button stays on top so the cardinals don't capture
          // a touch aimed at the chrono.
          // HitTestBehavior.opaque is REQUIRED inside an overlay isolate:
          // the default `deferToChild` defers to Container's hit test,
          // and Container with `decoration` (no `color` field) doesn't
          // declare a hit area on every Flutter version — touches then
          // bubble up to nothing and the Listener never fires.
          Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (_) => _onMainTap(),
            child: Container(
              width: _mainSize,
              height: _mainSize,
              decoration: BoxDecoration(
                color: _mainColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _mainColor.withValues(alpha: 0.45),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_mainIcon, color: Colors.white, size: 14),
                    const SizedBox(height: 2),
                    Text(
                      _tick.formatted,
                      // KEEP : ce widget tourne dans un isolate Flutter
                      // détaché (flutter_overlay_window). GoogleFonts
                      // n'est pas initialisé côté isolate, donc on
                      // garde un TextStyle natif minimal au lieu
                      // d'`ArenaText.small`.
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Formulaire de SCORE inline dans le bouton flottant (natif) : mon score /
/// score adversaire + tirs au but optionnels (KO, si égalité). À la validation,
/// le main arrête + scelle la vidéo (preuve) puis appelle `submitScore`.
/// Couleurs = `ArenaColors` (l'isolate overlay n'a ni GoogleFonts ni ArenaText —
/// on garde des `TextStyle` natifs minimaux, cf. le chrono).
class ScoreEntryField extends StatefulWidget {
  const ScoreEntryField({
    required this.onSubmit,
    required this.onFocusChange,
    required this.onClose,
    required this.allowPenalties,
    required this.timerLabel,
    super.key,
  });

  // ignore: avoid_positional_boolean_parameters
  final void Function(int my, int opp, bool viaPen, int? myPen, int? oppPen)
      onSubmit;

  // ignore: avoid_positional_boolean_parameters
  final Future<void> Function(bool hasFocus) onFocusChange;
  final VoidCallback onClose;
  final bool allowPenalties;
  final String timerLabel;

  @override
  State<ScoreEntryField> createState() => _ScoreEntryFieldState();
}

class _ScoreEntryFieldState extends State<ScoreEntryField> {
  final _my = TextEditingController();
  final _opp = TextEditingController();
  final _myPen = TextEditingController();
  final _oppPen = TextEditingController();
  bool _viaPen = false;
  String? _error;

  @override
  void dispose() {
    _my.dispose();
    _opp.dispose();
    _myPen.dispose();
    _oppPen.dispose();
    super.dispose();
  }

  bool get _isTie {
    final m = int.tryParse(_my.text.trim());
    final o = int.tryParse(_opp.text.trim());
    return m != null && o != null && m == o;
  }

  void _submit() {
    final my = int.tryParse(_my.text.trim());
    final opp = int.tryParse(_opp.text.trim());
    if (my == null || opp == null || my < 0 || my > 99 || opp < 0 || opp > 99) {
      setState(() => _error = 'Score invalide (0 à 99).');
      return;
    }
    int? myPen;
    int? oppPen;
    if (_viaPen) {
      if (my != opp) {
        setState(() => _error = 'Tirs au but : le score doit être à égalité.');
        return;
      }
      myPen = int.tryParse(_myPen.text.trim());
      oppPen = int.tryParse(_oppPen.text.trim());
      if (myPen == null ||
          oppPen == null ||
          myPen < 0 ||
          oppPen < 0 ||
          myPen > 30 ||
          oppPen > 30) {
        setState(() => _error = 'Tirs au but invalides (0 à 30).');
        return;
      }
      if (myPen == oppPen) {
        setState(
          () => _error = 'Les tirs au but ne peuvent pas être à égalité.',
        );
        return;
      }
    }
    widget.onSubmit(my, opp, _viaPen, myPen, oppPen);
  }

  Widget _numField(TextEditingController c, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: ArenaColors.bone.withValues(alpha: 0.65),
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        SizedBox(
          width: 52,
          child: TextField(
            controller: c,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 2,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(
              color: ArenaColors.bone,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
            decoration: InputDecoration(
              counterText: '',
              hintText: '0',
              hintStyle:
                  TextStyle(color: ArenaColors.bone.withValues(alpha: 0.2)),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              filled: true,
              fillColor: ArenaColors.bone.withValues(alpha: 0.08),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final canPen = widget.allowPenalties && _isTie;
    const sep = Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        ':',
        style: TextStyle(
          color: ArenaColors.bone,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
    // COMPACT & NON scrollable : tout tient d'un coup dans la fenêtre (360 dp).
    // `viewInsets.bottom` remonte la carte au-dessus du clavier. Éléments réduits
    // pour que titre + scores + pénaltys + Valider/Fermer soient visibles
    // ensemble, sans défilement.
    return Focus(
      onFocusChange: widget.onFocusChange,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: ArenaColors.void_.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ArenaColors.danger, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'SCORE DU MATCH',
                    style: TextStyle(
                      color: ArenaColors.bone,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    widget.timerLabel,
                    style: TextStyle(
                      color: ArenaColors.bone.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _numField(_my, 'MOI'),
                  sep,
                  _numField(_opp, 'ADVERSAIRE'),
                ],
              ),
              if (canPen) ...[
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => setState(() => _viaPen = !_viaPen),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _viaPen
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        color: ArenaColors.signalBlue,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Décidé aux tirs au but',
                        style: TextStyle(color: ArenaColors.bone, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                if (_viaPen)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _numField(_myPen, 'MES TAB'),
                        sep,
                        _numField(_oppPen, 'SES TAB'),
                      ],
                    ),
                  ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 4),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: ArenaColors.danger,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _submit,
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: ArenaColors.signalBlue,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Text(
                            'VALIDER',
                            style: TextStyle(
                              color: ArenaColors.bone,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: widget.onClose,
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: ArenaColors.bone.withValues(alpha: 0.24),
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          'Fermer',
                          style: TextStyle(
                            color: ArenaColors.bone.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  const _MiniButton({
    required this.visible,
    required this.offset,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final bool visible;
  final Offset offset;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const size = 40.0;
    return AnimatedSlide(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      offset:
          visible ? Offset(offset.dx / size, offset.dy / size) : Offset.zero,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: visible ? 1 : 0,
        child: IgnorePointer(
          ignoring: !visible,
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (_) => onTap(),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
          ),
        ),
      ),
    );
  }
}
