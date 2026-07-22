import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// RAPPEL DE MATCH façon RÉVEIL (≠ appel entrant CallKit).
///
/// Le rappel T-5 min ne doit pas ressembler à « quelqu'un t'appelle » : on
/// affiche une **notification plein écran** (full-screen intent) qui réveille
/// l'appareil même écran verrouillé / app tuée, sonne EN BOUCLE (flag
/// `INSISTENT`), et ouvre — au tap ou via le full-screen intent — l'[écran
/// d'alarme Flutter] `/match-alarm/<id>` (« C'est l'heure ! » + Ouvrir / Ignorer).
///
/// Service SANS état partagé (statique) : utilisable aussi bien depuis l'isolate
/// FCM background (app tuée) que depuis le main isolate (app vivante). Chaque
/// appelant crée son propre plugin — l'isolate background ne partage pas le
/// singleton du main.
class MatchAlarmService {
  const MatchAlarmService._();

  /// Clé SharedPreferences d'un rappel EN ATTENTE : quand le full-screen intent
  /// réveille l'appareil app tuée, Android lance juste l'activité (sans payload)
  /// → au démarrage, l'app lit cette clé pour atterrir sur l'écran d'alarme.
  static const pendingPrefKey = 'pending_match_alarm_match_id';

  /// Id fixe de la notif d'alarme : un seul rappel à la fois, et permet de
  /// l'annuler (couper la sonnerie) sans retenir d'id dynamique.
  static const _notifId = 71010;

  static const _channel = AndroidNotificationChannel(
    'arena_match_alarm',
    'Rappels de match',
    description: 'Réveil quand ton match va commencer.',
    importance: Importance.max,
    playSound: true,
    // Son ALARME système (pas le son de notif) — feeling « réveil ».
    sound: UriAndroidNotificationSound('content://settings/system/alarm_alert'),
  );

  /// Scopes de `call_invite` qui sont en réalité des RÉVEILS de match (pas des
  /// appels personne-à-personne) : le rappel T-5 min (`match_reminder`) ET
  /// l'ouverture de la salle de match (`match_activated`, « Ta salle de match
  /// est ouverte »). Tous deux présentés en ALARME plein écran, jamais en
  /// écran d'appel CallKit.
  static const alarmScopes = {'match_reminder', 'match_activated'};

  /// `true` si [scope] désigne un réveil de match (→ alarme, pas appel).
  static bool isAlarmScope(String? scope) => alarmScopes.contains(scope);

  /// Route de l'écran d'alarme Flutter pour un match donné.
  static String routeFor(String matchId) => '/match-alarm/$matchId';

  static const _nativeChannel = MethodChannel('arena/native');

  /// Démarre la sonnerie de réveil EN BOUCLE côté natif (flux ALARM). La notif
  /// (FLAG_INSISTENT) ne loope pas de façon fiable sur certains OEM (MIUI) — on
  /// s'appuie donc sur un vrai lecteur natif tant que l'écran d'alarme est là.
  static Future<void> startRinging() async {
    try {
      await _nativeChannel.invokeMethod<void>('startAlarmSound');
    } catch (_) {/* canal down / autre OS */}
  }

  /// Coupe la sonnerie de réveil native.
  static Future<void> stopRinging() async {
    try {
      await _nativeChannel.invokeMethod<void>('stopAlarmSound');
    } catch (_) {/* canal down / autre OS */}
  }

  /// Affiche l'alarme plein écran pour [matchId]. [label] = sous-titre (ex.
  /// « vs Adversaire »). Mémorise le rappel en attente (cold-start).
  ///
  /// [initialize] = true UNIQUEMENT dans l'isolate FCM background (plugin natif
  /// non initialisé). En main isolate, NE PAS ré-initialiser : ça écraserait le
  /// callback de tap de `NotificationService` (routage des autres notifs).
  static Future<void> show({
    required String matchId,
    String? label,
    bool initialize = false,
    FlutterLocalNotificationsPlugin? plugin,
  }) async {
    if (matchId.isEmpty) return;
    final local = plugin ?? FlutterLocalNotificationsPlugin();

    if (initialize) {
      const androidInit =
          AndroidInitializationSettings('@drawable/ic_notification');
      await local.initialize(
        const InitializationSettings(android: androidInit),
      );
    }
    // Cold-start : si le full-screen intent lance l'app sans délivrer le
    // payload, on retrouve le match à ouvrir ici.
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(pendingPrefKey, matchId);
    } catch (_) {/* best-effort */}

    final details = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      icon: '@drawable/ic_notification',
      // Plein écran par-dessus le verrouillage (comme un réveil / minuteur).
      fullScreenIntent: true,
      // Persistante + on ne l'efface pas au tap : c'est l'écran d'alarme Flutter
      // qui coupe la sonnerie (via [cancel]) quand l'utilisateur agit.
      ongoing: true,
      autoCancel: false,
      playSound: true,
      sound: _channel.sound,
      // FLAG_INSISTENT (4) : rejoue le son EN BOUCLE jusqu'à l'annulation.
      additionalFlags: Int32List.fromList(<int>[4]),
      visibility: NotificationVisibility.public,
    );

    try {
      final android = local.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(_channel);
      await local.show(
        _notifId,
        '⏰ Ton match va commencer',
        (label == null || label.trim().isEmpty)
            ? 'Ouvre ARENA pour rejoindre la salle.'
            : label.trim(),
        NotificationDetails(android: details),
        // Tap → écran d'alarme Flutter (le routeur mappe /match-alarm/:id).
        payload: routeFor(matchId),
      );
    } catch (_) {/* affichage best-effort — ne jamais casser le handler FCM */}
  }

  /// Coupe la sonnerie : annule la notif d'alarme + efface le rappel en attente.
  /// Appelé par l'écran d'alarme quand l'utilisateur choisit Ouvrir ou Ignorer.
  static Future<void> cancel({FlutterLocalNotificationsPlugin? plugin}) async {
    final local = plugin ?? FlutterLocalNotificationsPlugin();
    try {
      await local.cancel(_notifId);
    } catch (_) {/* déjà annulée */}
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(pendingPrefKey);
    } catch (_) {/* best-effort */}
  }

  /// Lit (et efface) l'éventuel rappel en attente au démarrage de l'app.
  static Future<String?> consumePending() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final id = prefs.getString(pendingPrefKey);
      if (id != null && id.isNotEmpty) {
        await prefs.remove(pendingPrefKey);
        return id;
      }
    } catch (_) {/* best-effort */}
    return null;
  }
}
