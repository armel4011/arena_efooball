import 'dart:async';

import 'package:arena/core/flavors/flavor_config.dart';
import 'package:arena/core/i18n/i18n_service.dart';
import 'package:arena/core/i18n/supported_locale.dart';
import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/services/bootstrap.dart';
import 'package:arena/core/services/callkit_service.dart';
import 'package:arena/core/services/deep_link_service.dart';
import 'package:arena/core/services/notification_service.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/call_record.dart';
import 'package:arena/data/repositories/call_repository.dart';
import 'package:arena/data/repositories/notification_repository.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
import 'package:arena/features_user/chat/call_screen.dart';
import 'package:arena/features_user/recording/overlay/recording_overlay.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  await bootstrap(
    flavor: Flavor.user,
    appName: 'ARENA',
    bundleId: 'com.arena.app',
    builder: ArenaUserApp.new,
  );
}

/// Entry point for the `flutter_overlay_window` isolate.
///
/// Spawned by the OverlayService when the recording starts (PHASE 8.4).
/// Runs in its own Flutter engine — providers / Supabase / SharedPrefs
/// from the main isolate are unreachable; data only crosses through
/// `FlutterOverlayWindow.shareData` / `overlayListener`.
@pragma('vm:entry-point')
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RecordingOverlayApp());
}

class ArenaUserApp extends ConsumerStatefulWidget {
  const ArenaUserApp({super.key});

  @override
  ConsumerState<ArenaUserApp> createState() => _ArenaUserAppState();
}

class _ArenaUserAppState extends ConsumerState<ArenaUserApp> {
  DeepLinkService? _deepLinkService;
  NotificationService? _notifications;
  String? _attachedUserId;

  /// Dernier appel entrant présenté en UI d'appel native (CallKit) —
  /// évite de relancer la sonnerie quand le flux Realtime ré-émet la
  /// même ligne, et permet de refermer l'UI si l'appelant annule.
  String? _shownIncomingCallId;

  /// Abonnement aux actions de l'UI d'appel native — Décrocher /
  /// Refuser / timeout, déclenchées y compris depuis l'écran verrouillé.
  StreamSubscription<CallEvent?>? _callkitSub;

  /// Dernier token PushKit VoIP (iOS) reçu du natif. Conservé en mémoire
  /// car il peut arriver avant la connexion : on le persiste alors dès
  /// qu'une session s'ouvre. `null` sur Android (jamais émis).
  String? _voipToken;

  @override
  void initState() {
    super.initState();
    // Écoute des actions de l'UI d'appel native dès le tout début : un
    // décroché en démarrage à froid (app tuée, réveillée par CallKit)
    // peut arriver avant même le premier frame.
    _callkitSub = CallkitService.events.listen(_onCallkitEvent);
    unawaited(CallkitService.ensureFullScreenIntentPermission());
    // Wire the deep link listener after the first frame so the router is
    // fully built. Supabase already hydrates the recovery session via its
    // own internal listener — we only forward navigation.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final router = ref.read(userRouterProvider);
      _deepLinkService = DeepLinkService(router: router)..start();
      _notifications = NotificationService(
        repository: ref.read(notificationRepositoryProvider),
        router: router,
      );
    });
  }

  @override
  void dispose() {
    _deepLinkService?.dispose();
    _notifications?.detach();
    unawaited(_callkitSub?.cancel());
    super.dispose();
  }

  /// Attach / detach the FCM token saver as the auth state flips. We
  /// listen here rather than from the service because the service needs
  /// the router (built post-frame), and Riverpod's `ref.listen` gives a
  /// clean lifecycle.
  void _syncNotificationsWithSession(String? userId) {
    final service = _notifications;
    if (service == null) return;
    if (userId == _attachedUserId) return;
    final previousUserId = _attachedUserId;
    _attachedUserId = userId;
    if (userId != null) {
      // Lot B.1 — ping le serveur pour mettre à jour profiles.last_seen_at
      // (alimente le MAU/DAU du dashboard super-admin).
      unawaited(_pingHeartbeat());
      unawaited(service.attach(userId));
      // Token VoIP reçu avant la connexion : on le persiste maintenant.
      if (_voipToken != null) {
        unawaited(_persistVoipToken(userId, _voipToken));
      }
    } else {
      unawaited(service.detach(clearTokenOnServer: true));
      // Déconnexion : on coupe aussi le push VoIP vers cet appareil.
      if (previousUserId != null) {
        unawaited(_persistVoipToken(previousUserId, null));
      }
    }
  }

  /// Best-effort ping de `heartbeat()` RPC. Silencieux en cas d'échec
  /// (offline, Supabase pas init…) — c'est un metric, pas un blocant.
  Future<void> _pingHeartbeat() async {
    try {
      await ref.read(supabaseClientProvider).rpc<dynamic>('heartbeat');
    } catch (_) {
      // ignore : metric non-critique
    }
  }

  /// Résout le nom de l'appelant puis présente l'UI d'appel native.
  Future<void> _presentIncomingCall(CallRecord call) async {
    String name;
    try {
      name = await ref.read(callRepositoryProvider).usernameOf(call.callerId);
    } catch (_) {
      name = 'Joueur';
    }
    await CallkitService.showIncoming(
      callId: call.id,
      callerName: name,
      scope: call.scope,
      scopeId: call.scopeId,
      callerId: call.callerId,
    );
  }

  /// Réagit aux actions de l'UI d'appel native (Décrocher / Refuser /
  /// timeout) — vaut pour l'app au premier plan comme réveillée à froid.
  void _onCallkitEvent(CallEvent? event) {
    if (event == null) return;
    final body = event.body;
    if (body is! Map) return;

    // Mise à jour du token PushKit VoIP (iOS) — ce body n'a pas d'`id`
    // d'appel, il faut le traiter avant l'extraction ci-dessous.
    if (event.event == Event.actionDidUpdateDevicePushTokenVoip) {
      _onVoipTokenUpdated(body['deviceTokenVoIP'] as String?);
      return;
    }

    final callId = body['id'] as String?;
    if (callId == null || callId.isEmpty) return;
    final extra = body['extra'] is Map
        ? Map<String, dynamic>.from(body['extra'] as Map)
        : const <String, dynamic>{};
    switch (event.event) {
      case Event.actionCallAccept:
        _shownIncomingCallId = null;
        unawaited(_acceptCall(callId, extra));
      case Event.actionCallDecline:
        _shownIncomingCallId = null;
        unawaited(_settleCall(callId, missed: false));
      case Event.actionCallTimeout:
        _shownIncomingCallId = null;
        unawaited(_settleCall(callId, missed: true));
      case _:
        break;
    }
  }

  /// Décroché : marque l'appel `accepted`, referme l'UI native puis
  /// ouvre notre propre écran d'appel.
  Future<void> _acceptCall(String callId, Map<String, dynamic> extra) async {
    final scope = extra['scope'] as String? ?? '';
    final scopeId = extra['scope_id'] as String? ?? '';
    await CallkitService.end(callId);
    // F3 - rappel match T-5 min : ce n'est pas un vrai appel, juste une
    // sonnerie de rappel. Tap "Décrocher" = ouvrir la page du match,
    // pas de joinChannel Agora, pas de markAccepted en DB.
    if (scope == 'match_reminder') {
      if (scopeId.isNotEmpty) {
        ref.read(userRouterProvider).go('/match/$scopeId');
      }
      return;
    }
    try {
      await ref.read(callRepositoryProvider).accept(callId);
    } catch (_) {/* on rejoint Agora même si l'update de statut échoue */}
    final callerId = extra['caller_id'] as String? ?? '';
    if (scope.isEmpty || scopeId.isEmpty || callerId.isEmpty) return;
    final rawName = (extra['caller_name'] as String?)?.trim();
    _openCallScreen(
      callId: callId,
      scope: scope,
      scopeId: scopeId,
      callerId: callerId,
      peerName: (rawName == null || rawName.isEmpty) ? 'Joueur' : rawName,
    );
  }

  /// Refus / sonnerie expirée : pose le statut terminal correspondant.
  Future<void> _settleCall(String callId, {required bool missed}) async {
    try {
      final repo = ref.read(callRepositoryProvider);
      await (missed ? repo.markMissed(callId) : repo.decline(callId));
    } catch (_) {/* signalisation best-effort */}
  }

  /// Nouveau token PushKit VoIP (iOS). On le mémorise et — si une session
  /// est ouverte — on le persiste pour que l'Edge Function puisse router
  /// les appels iOS vers APNs. Un token vide = PushKit l'a invalidé.
  void _onVoipTokenUpdated(String? token) {
    _voipToken = (token == null || token.isEmpty) ? null : token;
    final userId = _attachedUserId;
    if (userId != null) unawaited(_persistVoipToken(userId, _voipToken));
  }

  /// Écrit (ou efface si [token] est `null`) le token VoIP sur le profil.
  Future<void> _persistVoipToken(String userId, String? token) async {
    try {
      final repo = ref.read(notificationRepositoryProvider);
      if (token == null || token.isEmpty) {
        await repo.clearVoipToken(userId);
      } else {
        await repo.saveVoipToken(userId: userId, token: token);
      }
    } catch (_) {/* best-effort — réessayé au prochain événement/session */}
  }

  /// Pousse [CallScreen] sur le navigator racine. En démarrage à froid
  /// (décroché depuis l'écran verrouillé) le navigator peut ne pas être
  /// encore monté — on réessaie alors au frame suivant.
  void _openCallScreen({
    required String callId,
    required String scope,
    required String scopeId,
    required String callerId,
    required String peerName,
  }) {
    final nav = ref
        .read(userRouterProvider)
        .routerDelegate
        .navigatorKey
        .currentState;
    if (nav == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _openCallScreen(
          callId: callId,
          scope: scope,
          scopeId: scopeId,
          callerId: callerId,
          peerName: peerName,
        ),
      );
      return;
    }
    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => CallScreen(
          callId: callId,
          scope: scope,
          id: scopeId,
          calleeId: callerId,
          peerName: peerName,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(currentLocaleProvider);
    final router = ref.watch(userRouterProvider);

    ref
      ..listen(currentSessionProvider, (_, session) {
        _syncNotificationsWithSession(session?.user.id);
      })
      // Appel entrant détecté en Realtime (app au premier plan) : on
      // déclenche l'UI d'appel native — sonnerie en boucle + plein
      // écran. L'app tuée passe, elle, par le handler FCM background.
      ..listen(incomingCallProvider, (_, asyncCall) {
        final call = asyncCall.value;
        if (call == null) {
          // Plus d'appel en sonnerie (annulé, décroché, expiré) : on
          // referme l'UI native restée éventuellement ouverte.
          final shown = _shownIncomingCallId;
          if (shown != null) {
            _shownIncomingCallId = null;
            unawaited(CallkitService.end(shown));
          }
          return;
        }
        if (call.id == _shownIncomingCallId) return;
        _shownIncomingCallId = call.id;
        unawaited(_presentIncomingCall(call));
      });

    return MaterialApp.router(
      title: FlavorConfig.instance.appName,
      debugShowCheckedModeBanner: false,
      theme: arenaUserTheme,
      locale: locale.locale,
      supportedLocales: SupportedLocale.allFlutterLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: router,
    );
  }
}
