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

    // Pendant la saisie du code inline, un tick chrono arrive chaque seconde.
    // Reconstruire le TextField à chaque tick lui ferait perdre focus/clavier
    // (champ figé). On met donc à jour `_tick` SANS setState tant que la
    // saisie reste ouverte ; on ne rebuild que si `codeEntry` (ou le mode)
    // change réellement (ouverture / fermeture du champ).
    if (tick != null && !modeChanged && _tick.isCodeEntry && tick.isCodeEntry) {
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
      OverlayMode.idle => const IdleOverlayButton(),
      null => const SizedBox.shrink(),
    };
  }
}

/// Bouton flottant en état ARRÊTÉ : l'enregistrement est stoppé mais la fenêtre
/// overlay reste vivante (évite le 2ᵉ `showOverlay` qui figerait le panneau).
/// Visuel DISTINCT de la pause : gris, icône « replay » + « Reprendre ». Un tap
/// ramène Arena au premier plan (`focus_main`) — le redémarrage du recording est
/// piloté par le flux de match côté app.
class IdleOverlayButton extends StatelessWidget {
  const IdleOverlayButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Center(
        child: GestureDetector(
          onTap: () => sendToMain(RecordingOverlayMessages.focusMainType),
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: ArenaColors.carbon,
              shape: BoxShape.circle,
              border: Border.all(color: ArenaColors.silverDim, width: 1.5),
              boxShadow: const [
                BoxShadow(color: Colors.black45, blurRadius: 8),
              ],
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.replay, color: ArenaColors.silver, size: 34),
                SizedBox(height: 4),
                Text(
                  'Reprendre',
                  style: TextStyle(
                    color: ArenaColors.silver,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
    super.key,
  });

  /// Called with the normalised (trimmed, upper-cased) code when the user
  /// taps "Envoyer" and the code passes the 4–12 length check.
  final void Function(String code) onSubmit;

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
                  const Flexible(
                    child: Text(
                      'Code de la room',
                      textAlign: TextAlign.center,
                      style: TextStyle(
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
                const Text(
                  'Tape le code eFootball et envoie-le à ton adversaire, '
                  'sans quitter le jeu.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ],
              SizedBox(height: compact ? 8 : 10),
              Focus(
                onFocusChange: widget.onFocusChange,
                child: TextField(
                  controller: _controller,
                  autofocus: false,
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
                    hintText: 'ABC123',
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
    if (_tick.isCodeEntry) {
      return RoomCodeField(
        onSubmit: widget.onSubmitCode,
        onFocusChange: widget.onFieldFocusChange,
        timerLabel: _tick.formatted,
        onClose: () => sendToMain(RecordingOverlayMessages.askExitCodeType),
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
          _MiniButton(
            // HOME uniquement : ouvre la saisie pour ENVOYER le code. Côté AWAY
            // (roomCode reçu), la clé devient l'AFFICHAGE du code — pastille
            // « 🔑 + code » rendue ci-dessous, pas ce bouton d'envoi.
            visible: _expanded && !_tick.isSimple && _tick.roomCode == null,
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
          // S stop — natif : « enregistrer & arrêter » (icône save) ; simple
          // (LiveKit) : « arrêter » (icône stop). Même message askSaveStop.
          _MiniButton(
            visible: _expanded,
            offset: const Offset(0, _miniRadius),
            icon: _tick.isSimple ? Icons.stop : Icons.save_alt,
            color: _tick.isSimple ? ArenaColors.danger : ArenaColors.success,
            onTap: () => _onMiniTap(RecordingOverlayMessages.askSaveStopType),
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
          // Code de salle reçu de l'hôte (côté AWAY) : PORTÉ PAR LA CLÉ du
          // bouton flottant — pastille « 🔑 + code » ancrée sous le cluster,
          // visible quand le bouton est déployé (elle remplace, côté AWAY, le
          // bouton clé d'envoi réservé au HOME). Le presse-papier est impossible
          // depuis l'overlay (MIUI) → lecture + saisie manuelle. Se met à jour
          // si l'hôte change le code (le main repropage `roomCode` dans chaque
          // tick).
          if (_tick.roomCode != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 160),
                  opacity: _expanded ? 1 : 0,
                  child: Center(child: _RoomCodeKey(code: _tick.roomCode!)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Pastille « clé » affichant le code de salle reçu par l'AWAY, portée par le
/// bouton overlay (icône clé + code sur une ligne, cf. maquette « 🔑 4F7K2 »).
/// TextStyle natif : l'isolate overlay n'a pas GoogleFonts (cf. le chrono).
class _RoomCodeKey extends StatelessWidget {
  const _RoomCodeKey({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ArenaColors.iceCyan, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.vpn_key, color: ArenaColors.iceCyan, size: 13),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              code,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
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
