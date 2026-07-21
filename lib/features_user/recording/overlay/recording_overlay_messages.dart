/// IPC message vocabulary used between the main app isolate and the
/// overlay isolate (PHASE 8.4 — `flutter_overlay_window`).
///
/// `flutter_overlay_window` exposes a single bidirectional channel
/// (`shareData` / `overlayListener`) that ferries arbitrary JSON
/// payloads. We wrap it in a typed pair so a typo in a string literal
/// doesn't silently break the overlay → main wiring.
abstract final class RecordingOverlayMessages {
  /// Name under which the main isolate registers a `ReceivePort` in
  /// `IsolateNameServer`. The overlay isolate looks the port up and
  /// uses `SendPort.send` to deliver action strings (`ask_pause`,
  /// `ask_screenshot`, …) — this works on MIUI / Android 12+ where
  /// `flutter_overlay_window`'s `shareData → overlayListener` channel
  /// silently drops events once the main activity is paused.
  static const String mainPortName = 'arena_overlay_actions_main';

  /// `main → overlay` — push the elapsed recording duration in
  /// seconds. The overlay re-renders MM:SS each tick.
  static const String tickType = 'tick';

  /// `main → overlay` — flag that the auto-stop deadline is near
  /// (< 30 s). UI can pulse / change color.
  static const String warnType = 'warn';

  /// `main → overlay` — recording is paused. Overlay freezes its
  /// MM:SS counter and switches to a yellow "PAUSE" face.
  static const String pausedType = 'paused';

  /// `overlay → main` — the user tapped the overlay (short tap).
  /// Triggers "bring ARENA to front" if a method channel is wired,
  /// or simply closes the overlay otherwise.
  static const String focusMainType = 'focus_main';

  /// `overlay → main` — the user picked "Pause" in the expanded
  /// menu. Main app freezes the auto-stop timer for the grace
  /// window (Q5 = 2 min) and pauses the chronometer.
  static const String askPauseType = 'ask_pause';

  /// `overlay → main` — the user picked "Continuer" — resume the
  /// recording chronometer.
  static const String askResumeType = 'ask_resume';

  /// `overlay → main` — the user picked "Arrêter (forfait)". Main
  /// app stops the recording, marks the player as forfeit, alerts
  /// the admin.
  static const String askForfeitType = 'ask_forfeit';

  /// `overlay → main` — the user picked "Enregistrer et arrêter".
  /// Main app cleanly stops the recording and exports the resulting
  /// MP4 to Download/ARENA/.
  static const String askSaveStopType = 'ask_save_stop';

  /// `overlay → main` — l'utilisateur tape la 5ᵉ mini "Live" affichée
  /// uniquement quand l'admin a flag ce match pour la diffusion.
  /// Main stoppe d'abord le recording proprement (Android 14+ refuse
  /// 2 MediaProjection simultanées, voir mémoire mediaprojection_
  /// constraints), exporte le MP4 puis appelle joinAsBroadcaster.
  static const String askGoLiveType = 'ask_go_live';

  /// `main → overlay` — bascule l'overlay en mode « saisie du code room »
  /// (panneau champ + « Envoyer »). Utilisé par le HOME à l'étape
  /// « partager le code » AVANT que l'enregistrement ne démarre. Voir
  /// _anticheat_ref/PLAN_OVERLAY_CODE_ROOM.md.
  static const String modeCodeSenderType = 'mode_code_sender';

  /// `main → overlay` — bascule l'overlay en mode « bouton
  /// d'enregistrement » (le cluster 4-minis + chrono). Envoyé au morph
  /// (in_progress) juste après `resizeOverlay`, SANS re-`showOverlay`
  /// (quirk MIUI #4 : un 2ᵉ cycle show casse l'isolate).
  static const String modeRecordingType = 'mode_recording';

  /// `overlay → main` — le HOME a tapé un code room dans le champ et
  /// appuyé sur « Envoyer ». Payload : `{'type': ..., 'code': 'ABC123'}`.
  /// Le main appelle `matchRepository.sendRoomCode(...)`.
  static const String submitRoomCodeType = 'submit_room_code';

  /// `overlay → main` — depuis le bouton d'enregistrement, le HOME tape le
  /// mini « envoyer le code » : il veut saisir/envoyer le code room. Le main
  /// agrandit l'overlay (`resizeToCodeEntry`) et pousse un tick `codeEntry:
  /// true` pour que le bouton affiche le champ inline. Nouveau flux : le code
  /// s'envoie APRÈS le démarrage du recording, sans mode overlay séparé.
  static const String askEnterCodeType = 'ask_enter_code';

  /// `overlay → main` — le HOME referme la saisie du code sans envoyer
  /// (bouton « Fermer »). Le main rétrécit l'overlay (`exitCodeEntry`) et
  /// pousse un tick `codeEntry:false` → retour au bouton d'enregistrement.
  static const String askExitCodeType = 'ask_exit_code';

  /// `overlay → main` — depuis le bouton d'enregistrement, l'utilisateur tape le
  /// mini « Score » (remplace « Enregistrer & arrêter »). Le main agrandit
  /// l'overlay (`resizeToScoreEntry`) et pousse un tick `scoreEntry:true` → le
  /// bouton affiche le formulaire de score inline.
  static const String askEnterScoreType = 'ask_enter_score';

  /// `overlay → main` — referme le formulaire de score sans valider.
  static const String askExitScoreType = 'ask_exit_score';

  /// `overlay → main` — l'utilisateur a VALIDÉ le score. Payload :
  /// `{type, my, opp, viaPenalties, myPen?, oppPen?}`. Le main mappe
  /// mon/adverse → joueur1/2 (selon le rôle), arrête + scelle la vidéo (preuve),
  /// puis appelle `submitScore`. Score = fin du match.
  static const String submitScoreType = 'submit_score';

  /// Construit le message `main → overlay` de bascule en mode code-sender.
  static Map<String, dynamic> modeCodeSender() => {'type': modeCodeSenderType};

  /// Construit le message `main → overlay` de bascule en mode recording.
  static Map<String, dynamic> modeRecording() => {'type': modeRecordingType};

  /// Construit le message `overlay → main` portant le code room saisi.
  static Map<String, dynamic> submitRoomCode(String code) => {
        'type': submitRoomCodeType,
        'code': code,
      };

  /// Construit le message `overlay → main` portant le score saisi (mon score /
  /// score adverse, + pénaltys optionnels en cas d'égalité).
  static Map<String, dynamic> submitScore({
    required int my,
    required int opp,
    bool viaPenalties = false,
    int? myPen,
    int? oppPen,
  }) =>
      {
        'type': submitScoreType,
        'my': my,
        'opp': opp,
        'viaPenalties': viaPenalties,
        if (viaPenalties) 'myPen': myPen,
        if (viaPenalties) 'oppPen': oppPen,
      };

  /// Builds a tick payload. Kept as a free function so both ends
  /// agree on the JSON shape.
  ///
  /// `liveAvailable` propage l'éligibilité du match au streaming
  /// (admin a flagué une row streams `is_public + is_active` ownée
  /// par le user). L'overlay affiche/cache son 5ᵉ mini button "Live"
  /// en fonction de ce flag — l'isolate overlay ne lit pas les
  /// providers Riverpod du main directement.
  ///
  /// `codeEntry` : quand true, le bouton d'enregistrement affiche le champ
  /// de saisie du code room inline (l'overlay a été agrandi côté main). Le
  /// chrono continue de tourner derrière ; ce flag DOIT être propagé dans
  /// TOUS les ticks tant que la saisie est ouverte, sinon le premier tick
  /// périodique qui l'omet refermerait le champ.
  ///
  /// `roomCode` : côté AWAY (adversaire), le code de salle partagé par l'hôte,
  /// affiché sur le bouton d'enregistrement pour que le joueur le tape sans
  /// rouvrir l'app. `null`/vide = pas encore de code. Comme `codeEntry`, il DOIT
  /// être propagé dans TOUS les ticks (le contrôleur le mémorise et le renvoie
  /// à chaque tick) sinon il disparaîtrait au premier tick périodique qui l'omet.
  static Map<String, dynamic> tick({
    required int elapsedSeconds,
    required bool warning,
    bool paused = false,
    bool liveAvailable = false,
    bool simple = false,
    bool codeEntry = false,
    bool scoreEntry = false,
    bool allowPenalties = false,
    String? roomCode,
  }) {
    final type = paused
        ? pausedType
        : warning
            ? warnType
            : tickType;
    return {
      'type': type,
      'elapsed': elapsedSeconds,
      'liveAvailable': liveAvailable,
      'simple': simple,
      'codeEntry': codeEntry,
      'scoreEntry': scoreEntry,
      'allowPenalties': allowPenalties,
      if (roomCode != null && roomCode.isNotEmpty) 'roomCode': roomCode,
    };
  }
}

/// Parsed payload of a tick — guards against malformed messages
/// crossing the IPC boundary.
class OverlayTick {
  const OverlayTick({
    required this.elapsedSeconds,
    required this.isWarning,
    this.isPaused = false,
    this.isLiveAvailable = false,
    this.isSimple = false,
    this.isCodeEntry = false,
    this.isScoreEntry = false,
    this.allowPenalties = false,
    this.roomCode,
  });

  factory OverlayTick.fromMap(Object? raw) {
    if (raw is! Map) {
      return const OverlayTick(elapsedSeconds: 0, isWarning: false);
    }
    final type = raw['type'];
    final elapsed = raw['elapsed'];
    final liveAvailable = raw['liveAvailable'];
    final simple = raw['simple'];
    final codeEntry = raw['codeEntry'];
    final scoreEntry = raw['scoreEntry'];
    final allowPenalties = raw['allowPenalties'];
    final roomCode = raw['roomCode'];
    return OverlayTick(
      elapsedSeconds: elapsed is int ? elapsed : 0,
      isWarning: type == RecordingOverlayMessages.warnType,
      isPaused: type == RecordingOverlayMessages.pausedType,
      isLiveAvailable: liveAvailable == true,
      isSimple: simple == true,
      isCodeEntry: codeEntry == true,
      isScoreEntry: scoreEntry == true,
      allowPenalties: allowPenalties == true,
      roomCode: roomCode is String && roomCode.isNotEmpty ? roomCode : null,
    );
  }

  final int elapsedSeconds;
  final bool isWarning;
  final bool isPaused;
  final bool isLiveAvailable;

  /// Côté AWAY : le code de salle partagé par l'hôte (affiché sur le bouton),
  /// ou `null` s'il n'est pas encore disponible.
  final String? roomCode;

  /// Le bouton d'enregistrement affiche le champ de saisie du code room
  /// inline (nouveau flux : le HOME envoie son code depuis le bouton rouge).
  final bool isCodeEntry;

  /// Le bouton affiche le formulaire de SCORE inline (mon/adverse + pénaltys).
  final bool isScoreEntry;

  /// Match en KO (groupId null) → le formulaire de score autorise les pénaltys
  /// en cas d'égalité. Propagé par le main (seul à connaître le match).
  final bool allowPenalties;

  /// Mode « simplifié » (capture LiveKit Track Egress) : l'overlay ne
  /// montre que « ouvrir ARENA » + « stop » — pause / forfait / Live sont
  /// propres au recorder natif et masqués.
  final bool isSimple;

  String get formatted {
    final m = (elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

/// Deux visages de l'overlay Arena, portés par un unique isolate /
/// une unique fenêtre (quirk MIUI #4 : on ne rouvre jamais l'overlay,
/// on le *transforme*). Voir `ArenaOverlayRoot`.
enum OverlayMode {
  /// Panneau de saisie du code room (HOME, avant démarrage du match).
  codeSender,

  /// Bouton d'enregistrement anti-triche (cluster 4-minis + chrono).
  recording,
}

/// Déduit le mode overlay d'un message `main → overlay`, ou `null` si le
/// message ne porte pas d'information de mode (l'appelant garde alors le
/// mode courant).
///
/// Rétro-compat : un tick / warn / paused implique `recording` — c'est le
/// tout premier message que l'overlay d'enregistrement reçoit aujourd'hui
/// (chemin AWAY / recording direct), donc le dispatcher affiche bien le
/// bouton sans qu'on ait à modifier le contrôleur existant.
OverlayMode? overlayModeFromMessage(Object? raw) {
  if (raw is! Map) return null;
  switch (raw['type']) {
    case RecordingOverlayMessages.modeCodeSenderType:
      return OverlayMode.codeSender;
    case RecordingOverlayMessages.modeRecordingType:
    case RecordingOverlayMessages.tickType:
    case RecordingOverlayMessages.warnType:
    case RecordingOverlayMessages.pausedType:
      return OverlayMode.recording;
    default:
      return null;
  }
}

/// Extrait le code room d'un message `overlay → main`, ou `null` si le
/// message n'est pas une soumission de code.
String? roomCodeFromMessage(Object? raw) {
  if (raw is! Map) return null;
  if (raw['type'] != RecordingOverlayMessages.submitRoomCodeType) return null;
  final code = raw['code'];
  return code is String ? code : null;
}

/// Score saisi côté overlay, parsé d'un message `overlay → main`.
class OverlayScore {
  const OverlayScore({
    required this.my,
    required this.opp,
    this.viaPenalties = false,
    this.myPen,
    this.oppPen,
  });

  final int my;
  final int opp;
  final bool viaPenalties;
  final int? myPen;
  final int? oppPen;
}

/// Extrait le score d'un message `overlay → main`, ou `null` si ce n'en est
/// pas un / s'il est malformé.
OverlayScore? scoreFromMessage(Object? raw) {
  if (raw is! Map) return null;
  if (raw['type'] != RecordingOverlayMessages.submitScoreType) return null;
  final my = raw['my'];
  final opp = raw['opp'];
  if (my is! int || opp is! int) return null;
  final via = raw['viaPenalties'] == true;
  final myPen = raw['myPen'];
  final oppPen = raw['oppPen'];
  return OverlayScore(
    my: my,
    opp: opp,
    viaPenalties: via,
    myPen: myPen is int ? myPen : null,
    oppPen: oppPen is int ? oppPen : null,
  );
}
