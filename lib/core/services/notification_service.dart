// NotificationService est instancié dynamiquement (initState de main_user /
// main_admin) et non depuis main() — faux positif unreachable_from_main.
// ignore_for_file: unreachable_from_main

import 'dart:async';
import 'dart:io';

import 'package:arena/core/services/callkit_service.dart';
import 'package:arena/core/theme/arena_theme.dart' show ArenaColors;
import 'package:arena/data/repositories/notification_repository.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

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
  })  : _repository = repository,
        _router = router,
        _messaging = messaging ?? FirebaseMessaging.instance,
        _local = localNotifications ?? FlutterLocalNotificationsPlugin();

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
      if (kDebugMode) {
        debugPrint('[notifs] getToken failed: $e\n$st');
      }
    }

    _onTokenRefreshSub = _messaging.onTokenRefresh.listen((token) async {
      final id = _userId;
      if (id == null || token.isEmpty) return;
      try {
        await _repository.saveFcmToken(userId: id, token: token);
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('[notifs] token refresh save failed: $e\n$st');
        }
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
        if (kDebugMode) {
          debugPrint('[notifs] clearFcmToken failed: $e\n$st');
        }
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
    const androidInit = AndroidInitializationSettings('@drawable/ic_notification');
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

    final android =
        _local.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(_androidChannel);
    _localReady = true;
  }

  Future<void> _handleForeground(RemoteMessage message) async {
    // Appel entrant : l'écran de sonnerie est géré par l'écoute Realtime
    // globale (`incomingCallProvider`) — pas de notification ici.
    if (message.data['notification_type'] == 'call_invite') return;
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
    final bigPicturePath = imageUrl == null
        ? null
        : await _downloadImageToCache(imageUrl);

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
    final route = message.data['route'];
    if (route is String) _navigate(route);
  }

  void _navigate(String route) {
    if (route.isEmpty) return;
    try {
      _router.go(route);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[notifs] navigate to "$route" failed: $e\n$st');
      }
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
  if (message.data['notification_type'] != 'call_invite') return;
  await CallkitService.showIncoming(
    callId: message.data['call_id'] as String? ?? '',
    callerName: message.data['caller_name'] as String? ?? '',
    scope: message.data['scope'] as String? ?? '',
    scopeId: message.data['scope_id'] as String? ?? '',
    callerId: message.data['caller_id'] as String? ?? '',
  );
}
