import 'dart:async';

import 'package:arena/core/utils/error_reporter.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';

/// Façade autour de `flutter_callkit_incoming` — l'écran d'appel entrant
/// **natif** (plein écran par-dessus le verrouillage, sonnerie en boucle,
/// boutons Décrocher / Refuser).
///
/// Remplace l'ancienne `IncomingCallScreen` + la notification FCM
/// « bricolée » : une notification ne sait ni sonner en boucle ni passer
/// l'écran verrouillé. Déclenché aussi bien depuis le handler FCM
/// background (app tuée) que depuis le flux Realtime `incomingCallProvider`
/// (app au premier plan).
class CallkitService {
  const CallkitService._();

  /// Durée de sonnerie avant abandon automatique — alignée sur le TTL
  /// `ringing` côté signalisation et sur le timeout de `CallScreen`.
  static const _ringDuration = Duration(seconds: 45);

  /// Affiche l'UI d'appel entrant natif pour l'appel [callId].
  ///
  /// No-op si cet appel est déjà présenté — dédup cross-isolate (le
  /// handler FCM background tourne dans un autre isolate que l'UI).
  static Future<void> showIncoming({
    required String callId,
    required String callerName,
    required String scope,
    required String scopeId,
    required String callerId,
  }) async {
    if (callId.isEmpty) return;
    final name = callerName.trim().isEmpty ? "Quelqu'un" : callerName.trim();

    try {
      final active = await FlutterCallkitIncoming.activeCalls();
      if (active is List && active.any((c) => c is Map && c['id'] == callId)) {
        return;
      }
    } catch (_) {
      // activeCalls indisponible — on tente l'affichage quand même.
    }

    final params = CallKitParams(
      id: callId,
      nameCaller: name,
      appName: 'ARENA',
      type: 0, // appel audio
      duration: _ringDuration.inMilliseconds,
      textAccept: 'Décrocher',
      textDecline: 'Refuser',
      extra: <String, dynamic>{
        'scope': scope,
        'scope_id': scopeId,
        'caller_id': callerId,
        'caller_name': name,
      },
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#0A0E1A',
        actionColor: '#1E63FF',
        textColor: '#FFFFFF',
        incomingCallNotificationChannelName: 'Appels entrants',
        missedCallNotificationChannelName: 'Appels manqués',
        isShowFullLockedScreen: true,
        isImportant: true,
      ),
    );

    try {
      await FlutterCallkitIncoming.showCallkitIncoming(params);
    } catch (e, st) {
      unawaited(reportError(e, st, context: 'CallKitService.showIncoming'));
    }
  }

  /// Referme l'UI callkit d'un appel précis (annulé par l'appelant,
  /// décroché sur un autre appareil…).
  static Future<void> end(String callId) async {
    if (callId.isEmpty) return;
    try {
      await FlutterCallkitIncoming.endCall(callId);
    } catch (_) {/* déjà fermé */}
  }

  /// Referme toute UI callkit en cours.
  static Future<void> endAll() async {
    try {
      await FlutterCallkitIncoming.endAllCalls();
    } catch (_) {/* rien à fermer */}
  }

  /// Flux d'événements natifs : décrocher / refuser / timeout / raccroché.
  static Stream<CallEvent?> get events => FlutterCallkitIncoming.onEvent;

  /// Demande la permission « notification plein écran » (Android 14+) si
  /// elle n'est pas déjà accordée — sinon l'appel sur écran verrouillé
  /// sort en simple bandeau au lieu du plein écran. Best-effort.
  static Future<void> ensureFullScreenIntentPermission() async {
    try {
      final granted = await FlutterCallkitIncoming.canUseFullScreenIntent();
      if (granted == false) {
        await FlutterCallkitIncoming.requestFullIntentPermission();
      }
    } catch (_) {
      // API absente selon la version d'Android — best-effort.
    }
  }
}
