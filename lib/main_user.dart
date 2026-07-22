import 'dart:async';

import 'package:arena/core/flavors/flavor_config.dart';
import 'package:arena/core/i18n/i18n_service.dart';
import 'package:arena/core/i18n/supported_locale.dart';
import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/services/bootstrap.dart';
import 'package:arena/core/services/callkit_service.dart';
import 'package:arena/core/services/deep_link_service.dart';
import 'package:arena/core/services/gallery_exporter.dart';
import 'package:arena/core/services/match_alarm_service.dart';
import 'package:arena/core/services/match_recording_coordinator.dart';
import 'package:arena/core/services/notification_service.dart';
import 'package:arena/core/services/proof_claim_service.dart';
import 'package:arena/core/services/proof_commitment_service.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/call_record.dart';
import 'package:arena/data/repositories/call_repository.dart';
import 'package:arena/data/repositories/notification_repository.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
import 'package:arena/features_user/chat/call_screen.dart';
import 'package:arena/features_user/match_room/widgets/match_recording_actions_sheet.dart'
    show coordinatorStateProvider;
import 'package:arena/features_user/recording/overlay/recording_overlay.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

Future<void> main() async {
  await bootstrap(
    flavor: Flavor.user,
    appName: 'ARENA',
    // Aligné sur l'applicationId (cf. android/app/build.gradle.kts). Sert de
    // tag d'observabilité (Sentry bundle_id). NB : le scheme de deep link
    // reste `com.arena.app` (cf. deep_link_service / AndroidManifest) car lié
    // aux redirect URLs Supabase/OAuth — indépendant de l'applicationId.
    bundleId: 'com.arena_skill.app',
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

/// Messenger racine — permet d'afficher un snackbar (ex. « replay
/// enregistré ») depuis un listener d'app, sans dépendre d'un `Scaffold`
/// d'écran. Indispensable pour l'export post-enregistrement, qui se
/// déclenche souvent alors qu'aucun écran de la salle de match n'est monté.
final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

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

  /// Anti-triche Phase 3 / replay — anti-doublon par chemin de fichier.
  /// La transition `CoordinatorStopped` peut être re-notifiée ; on n'engage
  /// le hash et on n'exporte qu'une fois par enregistrement.
  String? _committedRecordingPath;
  String? _exportedRecordingPath;

  /// Dernier userId pour lequel on a déjà lancé le rattrapage des réclamations
  /// de preuve — évite de relancer reconcile à chaque émission de session.
  String? _reconciledClaimsForUserId;

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
        // Anti-triche Phase 3 : push `proof_claim_request` → upload du fichier
        // engagé (via la sync queue).
        onProofClaimRequest: (matchId, streamId) {
          unawaited(
            ref.read(proofClaimServiceProvider).handleClaim(
                  matchId: matchId,
                  streamId: streamId,
                ),
          );
        },
      );
      // Démarrage à froid avec session déjà restaurée : le `listen` de session
      // ne se déclenche pas pour la valeur initiale → on lance le rattrapage
      // des réclamations ici aussi (dédup interne).
      _reconcileProofClaims(ref.read(currentSessionProvider)?.user.id);
      // Réveillé à froid par l'alarme de rappel (full-screen intent sans
      // payload délivré) : on atterrit sur l'écran de réveil.
      unawaited(_maybeShowPendingMatchAlarm(router));
    });
  }

  /// Ouvre l'écran de réveil si un rappel de match est EN ATTENTE (posé par
  /// [MatchAlarmService] quand la notif alarme a réveillé l'appareil app tuée).
  /// Ne consomme le rappel que si une session est ouverte — sinon on le laisse
  /// pour après la connexion.
  Future<void> _maybeShowPendingMatchAlarm(GoRouter router) async {
    if (ref.read(currentSessionProvider) == null) return;
    final matchId = await MatchAlarmService.consumePending();
    if (matchId == null || matchId.isEmpty || !mounted) return;
    unawaited(router.push(UserRoutes.matchAlarmPath(matchId)));
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
      // Session restaurée APRÈS le postFrame (ou app rouverte après login) :
      // rattrape un éventuel rappel de match en attente → écran de réveil.
      unawaited(_maybeShowPendingMatchAlarm(ref.read(userRouterProvider)));
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

  /// Backstop anti-triche Phase 3 : à session active, rattrape les preuves
  /// RÉCLAMÉES mais pas encore uploadées (`reconcilePendingClaims`).
  ///
  /// Volontairement DÉCOUPLÉ du service de notifications : c'est précisément le
  /// filet quand le push FCM n'arrive pas (token indisponible, isolate non
  /// réveillé…). Il ne doit donc PAS être gardé par `_notifications != null`.
  /// Idempotent côté serveur ; dédup local par [_reconciledClaimsForUserId].
  void _reconcileProofClaims(String? userId) {
    if (userId == null) {
      _reconciledClaimsForUserId = null;
      return;
    }
    if (userId == _reconciledClaimsForUserId) return;
    _reconciledClaimsForUserId = userId;
    unawaited(
      ref.read(proofClaimServiceProvider).reconcilePendingClaims(userId),
    );
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

  /// Résout le nom de l'appelant puis présente l'UI d'appel native — SAUF pour
  /// un réveil de match (`match_reminder` = rappel T-5, `match_activated` =
  /// salle ouverte), présenté en ALARME/réveil plein écran (pas un appel).
  Future<void> _presentIncomingCall(CallRecord call) async {
    if (MatchAlarmService.isAlarmScope(call.scope)) {
      await MatchAlarmService.show(matchId: call.scopeId);
      return;
    }
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
    // On NE réinitialise PAS `_shownIncomingCallId` ici : la ligne `calls`
    // peut rester `ringing` un court instant après l'action (settle
    // best-effort + latence Realtime). La garder mémorisée empêche le flux
    // `incomingCallProvider` de re-présenter le MÊME appel en boucle (plein
    // écran qui re-sonne toutes les ~45 s). Le reset a lieu quand l'appel
    // disparaît réellement du flux (`call == null`, cf. listener du build).
    switch (event.event) {
      case Event.actionCallAccept:
        unawaited(_acceptCall(callId, extra));
      case Event.actionCallDecline:
        unawaited(_settleCall(callId, missed: false));
      case Event.actionCallTimeout:
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
    // Réveil de match (rappel T-5 `match_reminder` ou salle ouverte
    // `match_activated`) : ce n'est pas un vrai appel. Tap "Décrocher" =
    // ouvrir la page du match, pas de joinChannel Agora ni markAccepted en DB.
    // (Filet : ces scopes passent normalement par l'alarme, pas CallKit.)
    if (MatchAlarmService.isAlarmScope(scope)) {
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

  /// Anti-triche Phase 3 + sauvegarde du replay, pilotés au niveau RACINE
  /// pour ne PAS dépendre du montage de l'écran salle de match.
  ///
  /// L'arrêt d'enregistrement survient typiquement depuis le jeu externe
  /// (ARENA en arrière-plan) : un listener porté par le widget de la salle
  /// ratait alors la transition `CoordinatorStopped` → ni hash engagé, ni
  /// export. Ici le listener vit aussi longtemps que l'app, donc il capte
  /// l'arrêt quel que soit l'écran courant.
  void _onRecordingStopped(CoordinatorState? state) {
    if (state is! CoordinatorStopped) return;
    final path = state.localRecordingPath;
    if (path == null || path.isEmpty) return;

    // 1) Engage le commitment hash (anti-triche) — un seul par fichier.
    if (_committedRecordingPath != path) {
      final self = ref.read(currentSessionProvider)?.user.id;
      if (self != null) {
        _committedRecordingPath = path;
        unawaited(
          ref.read(proofCommitmentServiceProvider).commitForMatch(
                matchId: state.matchId,
                filePath: path,
                playerId: self,
              ),
        );
      }
    }

    // 2) Exporte le replay vers la galerie — un seul par fichier.
    if (_exportedRecordingPath != path) {
      _exportedRecordingPath = path;
      unawaited(_exportRecording(path));
    }
  }

  /// Copie l'enregistrement vers Téléchargements/galerie + snackbar via le
  /// messenger racine (aucun `Scaffold` d'écran requis).
  Future<void> _exportRecording(String path) async {
    // Résolu AVANT l'await pour ne pas porter un BuildContext à travers le
    // saut asynchrone (lint use_build_context_synchronously). La sauvegarde
    // du replay a lieu de toute façon ; le snackbar est best-effort.
    final messenger = rootScaffoldMessengerKey.currentState;
    final l10n =
        messenger == null ? null : AppLocalizations.of(messenger.context);
    final uri =
        await ref.read(galleryExporterProvider).saveVideoToGallery(path);
    if (messenger == null || l10n == null) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          uri != null
              ? l10n.recordingReplaySavedDownloads
              : l10n.recordingReplayInCache,
        ),
        duration: const Duration(seconds: 4),
      ),
    );
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
    final nav =
        ref.read(userRouterProvider).routerDelegate.navigatorKey.currentState;
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
        // Rattrapage des réclamations de preuve — indépendant du service de
        // notifications (filet anti-triche quand le FCM n'arrive pas).
        _reconcileProofClaims(session?.user.id);
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
      })
      // Anti-triche Phase 3 + replay : on observe l'arrêt d'enregistrement au
      // niveau racine (toujours monté) plutôt que depuis l'écran salle de
      // match, qui peut être démonté/en arrière-plan au moment du stop.
      ..listen<AsyncValue<CoordinatorState>>(
        coordinatorStateProvider,
        (_, next) => _onRecordingStopped(next.valueOrNull),
      );

    return MaterialApp.router(
      title: FlavorConfig.instance.appName,
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      theme: arenaUserTheme,
      locale: locale.locale,
      supportedLocales: SupportedLocale.allFlutterLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: router,
    );
  }
}
