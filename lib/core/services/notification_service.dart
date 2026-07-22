// NotificationService est instancié dynamiquement (initState de main_user /
// main_admin) et non depuis main() — faux positif unreachable_from_main.
// ignore_for_file: unreachable_from_main

import 'dart:async';
import 'dart:io';

import 'package:arena/core/services/callkit_service.dart';
import 'package:arena/core/services/match_alarm_service.dart';
import 'package:arena/core/services/proof_file_store.dart';
import 'package:arena/core/services/secure_local_storage.dart';
// sync_queue_service expose generateUuidV4 + ProofUploadAction (part
// sync_queue_actions.dart).
import 'package:arena/core/services/sync_queue_service.dart';
import 'package:arena/core/theme/arena_theme.dart' show ArenaColors;
import 'package:arena/core/utils/error_reporter.dart';
import 'package:arena/data/repositories/notification_repository.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show WidgetsFlutterBinding;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// FCM + in-app notifications glue (PHASE 10).
///
/// What this owns:
/// - Asking POST_NOTIFICATIONS (Android 13+).
/// - Pulling the FCM device token and saving it on
///   `public.profiles.fcm_token` so the dispatch Edge Function (PHASE
///   12.5) can target this device.
/// - Showing a local notification when a push lands while the app is in
///   the foreground (Firebase suppresses the system tray notif by design).
/// - Routing taps (`onMessageOpenedApp`, `getInitialMessage`) to the
///   deep link carried in `data.route`.
///
/// What this intentionally does NOT do:
/// - Sending pushes. That belongs to the `send_targeted_notification`
///   Edge Function (PHASE 12.5).
/// - iOS APNs setup. iOS lives behind PHASE 8b (Apple Dev account).
class NotificationService {
  NotificationService({
    required NotificationRepository repository,
    required GoRouter router,
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
    this.onProofClaimRequest,
  })  : _repository = repository,
        _router = router,
        _messaging = messaging ?? FirebaseMessaging.instance,
        _local = localNotifications ?? FlutterLocalNotificationsPlugin();

  /// Anti-triche Phase 3 : appelé quand un push `proof_claim_request` arrive
  /// (foreground ou tap) — déclenche l'upload du fichier engagé.
  final void Function(String matchId, String streamId)? onProofClaimRequest;

  static const _androidChannel = AndroidNotificationChannel(
    'arena_default',
    'ARENA notifications',
    description: 'Matches, gains, litiges, et notifs système.',
    importance: Importance.high,
  );

  final NotificationRepository _repository;
  final GoRouter _router;
  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _local;

  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedSub;
  StreamSubscription<String>? _onTokenRefreshSub;
  String? _userId;
  bool _localReady = false;

  /// Attaches the service to [userId] — requests permission, registers
  /// the FCM token, and starts listening for messages.
  ///
  /// Safe to call multiple times (sign-in then session refresh): the
  /// previous subscriptions are cancelled first so a token from an old
  /// session never overwrites the new one.
  Future<void> attach(String userId) async {
    await detach();
    _userId = userId;

    await _ensurePermission();
    await _ensureLocalPlugin();

    try {
      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await _repository.saveFcmToken(userId: userId, token: token);
      }
    } catch (e, st) {
      unawaited(reportError(e, st, context: 'NotificationService.attach'));
    }

    _onTokenRefreshSub = _messaging.onTokenRefresh.listen((token) async {
      final id = _userId;
      if (id == null || token.isEmpty) return;
      try {
        await _repository.saveFcmToken(userId: id, token: token);
      } catch (e, st) {
        unawaited(
          reportError(
            e,
            st,
            context: 'NotificationService.onTokenRefresh',
          ),
        );
      }
    });

    _onMessageSub = FirebaseMessaging.onMessage.listen(_handleForeground);
    _onMessageOpenedSub =
        FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

    // App was launched cold by tapping a push.
    final initial = await _messaging.getInitialMessage();
    if (initial != null) _handleTap(initial);
  }

  /// Detaches all subscriptions and clears the FCM token on the
  /// profile — call this from sign-out so an idle device stops
  /// receiving pushes for the previous account.
  Future<void> detach({bool clearTokenOnServer = false}) async {
    final id = _userId;
    _userId = null;
    await _onMessageSub?.cancel();
    await _onMessageOpenedSub?.cancel();
    await _onTokenRefreshSub?.cancel();
    _onMessageSub = null;
    _onMessageOpenedSub = null;
    _onTokenRefreshSub = null;

    if (clearTokenOnServer && id != null) {
      try {
        await _repository.clearFcmToken(id);
      } catch (e, st) {
        unawaited(reportError(e, st, context: 'NotificationService.detach'));
      }
    }
  }

  Future<void> _ensurePermission() async {
    if (Platform.isAndroid) {
      await Permission.notification.request();
    } else {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  Future<void> _ensureLocalPlugin() async {
    if (_localReady) return;
    const androidInit =
        AndroidInitializationSettings('@drawable/ic_notification');
    const iosInit = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          _navigate(payload);
        }
      },
    );

    final android = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(_androidChannel);
    _localReady = true;
  }

  Future<void> _handleForeground(RemoteMessage message) async {
    // Appel entrant : l'écran de sonnerie est géré par l'écoute Realtime
    // globale (`incomingCallProvider`) — pas de notification ici.
    if (message.data['notification_type'] == 'call_invite') return;
    // Réclamation de preuve (Phase 3) : déclenche l'upload en plus d'afficher
    // la notif (on continue le rendu ci-dessous).
    _maybeHandleProofClaim(message);
    final notif = message.notification;
    final title = notif?.title ?? message.data['title'] as String? ?? 'ARENA';
    final body = notif?.body ?? message.data['body'] as String? ?? '';
    final route = message.data['route'] as String?;
    // FCM v1 expose l'URL via `android.notification.image` qui remonte
    // dans `notif.android?.imageUrl`. En foreground l'OS ne rend pas
    // automatiquement la notif — il faut télécharger l'image et la
    // passer en BigPictureStyle à flutter_local_notifications.
    final imageUrl = notif?.android?.imageUrl ??
        message.data['image_url'] as String? ??
        notif?.apple?.imageUrl;
    final bigPicturePath =
        imageUrl == null ? null : await _downloadImageToCache(imageUrl);

    final androidDetails = AndroidNotificationDetails(
      _androidChannel.id,
      _androidChannel.name,
      channelDescription: _androidChannel.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_notification',
      // Couleur d'accent ARENA (signalBlue) : Android la peint en fond du
      // cercle qui entoure la petite icône dans le volet déroulé — c'est
      // notre « fond bleu ». Vaut aussi pour les notifs natives via le
      // meta-data default_notification_color du manifest.
      color: ArenaColors.signalBlue,
      styleInformation: bigPicturePath == null
          ? null
          : BigPictureStyleInformation(
              FilePathAndroidBitmap(bigPicturePath),
              contentTitle: title,
              summaryText: body,
              hideExpandedLargeIcon: true,
            ),
      // Gros icône à droite de la notif : l'image du push si présente,
      // sinon le chevron ARENA blanc sur cercle bleu (ic_notification_large).
      largeIcon: bigPicturePath == null
          ? const DrawableResourceAndroidBitmap('ic_notification_large')
          : FilePathAndroidBitmap(bigPicturePath),
    );

    await _local.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(),
      ),
      payload: route,
    );
  }

  /// Télécharge [url] dans le cache temporaire et retourne le chemin
  /// local — `BigPictureStyleInformation` exige un fichier sur disque
  /// (pas une URL). Renvoie `null` si le download échoue (auquel cas
  /// l'appelant tombe sur une notif texte seule sans planter).
  Future<String?> _downloadImageToCache(String url) async {
    try {
      final uri = Uri.parse(url);
      // Timeout 15s : utile sur 3G / connexion fluctuante (8s ratait sur
      // certains tests reels meme avec une image picsum < 100 KB).
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 15);
      final req = await client.getUrl(uri);
      final res = await req.close();
      if (res.statusCode != 200) {
        client.close();
        if (kDebugMode) {
          debugPrint(
            '[notifs] image download HTTP ${res.statusCode} for $url',
          );
        }
        return null;
      }
      final bytes = await res.fold<List<int>>(
        <int>[],
        (acc, chunk) => acc..addAll(chunk),
      );
      client.close();
      final dir = await getTemporaryDirectory();
      final name =
          'notif_${DateTime.now().millisecondsSinceEpoch}_${uri.pathSegments.isEmpty ? "img" : uri.pathSegments.last}';
      final file = File('${dir.path}/$name');
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[notifs] image download failed for $url: $e\n$st');
      }
      return null;
    }
  }

  void _handleTap(RemoteMessage message) {
    _maybeHandleProofClaim(message);
    final route = message.data['route'];
    if (route is String) _navigate(route);
  }

  /// Si le push est une réclamation de preuve (Phase 3), déclenche l'upload du
  /// fichier engagé via le callback. Les `match_id` / `stream_id` sont posés
  /// dans `data` par la RPC `admin_claim_proof`.
  void _maybeHandleProofClaim(RemoteMessage message) {
    if (message.data['notification_type'] != 'proof_claim_request') return;
    final matchId = message.data['match_id'] as String?;
    final streamId = message.data['stream_id'] as String?;
    if (matchId != null && streamId != null) {
      onProofClaimRequest?.call(matchId, streamId);
    }
  }

  void _navigate(String route) {
    if (route.isEmpty) return;
    try {
      // Empile la cible AU-DESSUS de l'accueil au lieu de `go()` qui remplace
      // toute la pile : les routes de notif sont de 1er niveau (frères de `/`),
      // donc un `go()` laissait la pile sans Home dessous → le back système
      // fermait l'app. On reconstruit d'abord la base `/` puis on empile la
      // cible : le retour revient alors à l'accueil. Cf. bug retour notif.
      // `/` = accueil user (UserRoutes.home) ; littéral pour éviter d'importer
      // le routeur dans le service.
      const home = '/';
      if (route == home) {
        _router.go(home);
      } else {
        _router
          ..go(home)
          ..push(route);
      }
    } catch (e, st) {
      unawaited(reportError(e, st, context: 'NotificationService._navigate'));
    }
  }
}

/// Background isolate handler — must be a top-level annotated function.
///
/// Firebase spawns a separate isolate for terminated/background pushes.
/// Pour un appel entrant (`call_invite`, message DATA-only haute
/// priorité) on déclenche l'UI d'appel natif `flutter_callkit_incoming`
/// (plein écran + sonnerie en boucle) qui réveille l'appareil même app
/// tuée. Les autres pushes sont rendus par l'OS — rien à faire ici.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    debugPrint('[notifs] background message ${message.messageId}');
  }
  final type = message.data['notification_type'];
  if (type == 'call_invite') {
    // Les réveils de match (rappel T-5 `match_reminder` ET ouverture de salle
    // `match_activated`) arrivent comme des `call_invite` pour réutiliser le
    // canal DATA haute priorité, mais ce ne sont PAS des appels : on les
    // affiche en ALARME plein écran (réveil), pas en écran d'appel CallKit.
    final scope = message.data['scope'] as String? ?? '';
    if (MatchAlarmService.isAlarmScope(scope)) {
      await MatchAlarmService.show(
        matchId: message.data['scope_id'] as String? ?? '',
        label: message.data['caller_name'] as String?,
        // Isolate FCM background : le plugin natif n'est pas encore initialisé.
        initialize: true,
      );
      return;
    }
    await CallkitService.showIncoming(
      callId: message.data['call_id'] as String? ?? '',
      callerName: message.data['caller_name'] as String? ?? '',
      scope: scope,
      scopeId: message.data['scope_id'] as String? ?? '',
      callerId: message.data['caller_id'] as String? ?? '',
    );
    return;
  }
  // Réclamation de preuve anti-triche reçue APP TUÉE : on enfile l'upload de la
  // vidéo engagée sans dépendre d'une réouverture volontaire du joueur (les
  // chemins foreground/tap/reconcile ne s'exécutent qu'app rouverte). Envoyée en
  // data-only haute priorité par `dispatch_notification`.
  if (type == 'proof_claim_request') {
    await _uploadClaimedProofInBackground(message.data);
    return;
  }
}

/// Upload de la preuve engagée depuis l'isolate BACKGROUND (fresh isolate FCM),
/// sur réclamation admin. Bootstrappe Supabase (session restaurée depuis le
/// secure storage) puis réutilise [ProofUploadAction] (upload + `proof-verify`).
///
/// Best-effort : soumis aux limites d'exécution background de l'OS (certains OEM
/// agressifs — MIUI/Xiaomi — peuvent tuer l'isolate avant la fin de l'upload) et
/// exige que le fichier engagé soit encore présent localement. Idempotent :
/// `proof-verify` + l'upsert storage tolèrent un ré-upload (foreground/reconcile).
Future<void> _uploadClaimedProofInBackground(Map<String, dynamic> data) async {
  final matchId = data['match_id'] as String?;
  final streamId = data['stream_id'] as String?;
  if (matchId == null || streamId == null) return;
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // 1. Fichier engagé localement (SharedPreferences). Rien à livrer sinon.
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload(); // voir les écritures du main isolate
    final entry = ProofFileStore(prefs).get(matchId);
    if (entry == null || !File(entry.filePath).existsSync()) return;

    // 2. Supabase dans cet isolate : session du joueur restaurée depuis le
    //    secure storage (l'isolate FCM ne partage pas le singleton du main).
    if (!dotenv.isInitialized) {
      await dotenv.load();
    }
    final url = dotenv.env['SUPABASE_URL']?.trim() ?? '';
    final anon = dotenv.env['SUPABASE_ANON_KEY']?.trim() ?? '';
    if (url.isEmpty || anon.isEmpty) return;
    try {
      await Supabase.initialize(
        url: url,
        anonKey: anon,
        authOptions: FlutterAuthClientOptions(
          localStorage: SecureLocalStorage.fromUrl(url),
        ),
      );
    } catch (_) {
      // Déjà initialisé dans cet isolate (handler ré-entrant) — on continue.
    }
    final client = Supabase.instance.client;
    if (client.auth.currentSession == null) return; // pas de session → rien

    // 3. Upload + proof-verify (réutilise l'action de la sync queue).
    await ProofUploadAction(
      id: generateUuidV4(),
      createdAt: DateTime.now().toUtc(),
      matchId: matchId,
      streamId: streamId,
      playerId: entry.playerId,
      filePath: entry.filePath,
    ).execute(client);
  } catch (e, st) {
    unawaited(reportError(e, st, context: 'notifs.bgProofClaimUpload'));
  }
}
