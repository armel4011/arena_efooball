import 'dart:async';

import 'package:arena/core/flavors/flavor_config.dart';
import 'package:arena/core/services/notification_service.dart';
import 'package:arena/core/services/onboarding_service.dart';
import 'package:arena/core/utils/sentry_provider_observer.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef AppBuilder = Widget Function();

Future<void> bootstrap({
  required Flavor flavor,
  required String appName,
  required String bundleId,
  required AppBuilder builder,
}) async {
  // Single zone wraps binding init, Sentry init and runApp so the framework
  // sees the same zone everywhere — avoids the "Zone mismatch" warning that
  // appears when SentryFlutter.init's appRunner spins up a child zone.
  await runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlavorConfig.init(
      flavor: flavor,
      appName: appName,
      bundleId: bundleId,
    );

    // ─── Critical path : on attend SharedPreferences (flag `has_seen_
    // splash_v1`) + .env + Supabase + Firebase avant `runApp`. Tous sont
    // load-bearing pour la 1re frame :
    //
    // * Supabase : `userRouterProvider` consomme `currentSessionProvider`
    //   → `supabaseClientProvider` qui assert `Supabase.instance._isInit
    //   ialized`. Race observée 2026-05-19 (log `Failed assertion line
    //   44 pos 7: '_instance._isInitialized'`).
    //
    // * Firebase : le post-frame callback de `_ArenaUserAppState.init
    //   State` instancie `NotificationService` dont le constructor lit
    //   `FirebaseMessaging.instance` (assert `Firebase.app` initialisé).
    //   Race observée 2026-05-19 (log `MethodChannelFirebase.app ...
    //   NotificationService(notification_service.dart:35)`).
    //
    // Coût : ~250-400 ms ajoutés au pre-runApp. Le splash Flutter dure
    // 2.5 s (récurrent) ou 5.3 s (1er lancement), donc invisible.
    final prefs = await SharedPreferences.getInstance();
    final overrides = <Override>[
      sharedPreferencesProvider.overrideWithValue(prefs),
    ];

    await _loadEnv();
    await Future.wait<void>([
      _initSupabase(),
      _initFirebase(),
    ]);

    // ─── Background init (~200-500 ms) — ne bloque PAS runApp.
    // Sentry n'est pas consommé pendant la 1re frame : il a une queue
    // interne qui accepte les events avant `SentryFlutter.init`. Le
    // binding natif (env. 500 ms) reste différé pour préserver la perf
    // splash.
    unawaited(_initSentry(flavor: flavor));

    runApp(
      ProviderScope(
        overrides: overrides,
        observers: const [SentryProviderObserver()],
        child: builder(),
      ),
    );
  }, (error, stack) {
    Sentry.captureException(error, stackTrace: stack);
  });
}

Future<void> _initSentry({required Flavor flavor}) async {
  // Per-flavor DSN — `.env` exposes SENTRY_DSN_USER / SENTRY_DSN_ADMIN.
  // Falls back to a generic SENTRY_DSN if a flavor-specific one is missing.
  final dsnKey =
      flavor == Flavor.admin ? 'SENTRY_DSN_ADMIN' : 'SENTRY_DSN_USER';
  final sentryDsn = (dotenv.env[dsnKey]?.trim().isNotEmpty ?? false)
      ? dotenv.env[dsnKey]!.trim()
      : (dotenv.env['SENTRY_DSN']?.trim() ?? '');

  if (sentryDsn.isEmpty) {
    if (kDebugMode) {
      debugPrint('[bootstrap] SENTRY_DSN missing — running without Sentry.');
    }
    return;
  }
  await SentryFlutter.init((options) {
    options
      ..dsn = sentryDsn
      ..environment = dotenv.env['APP_ENV'] ?? 'development'
      ..tracesSampleRate = kReleaseMode ? 0.2 : 1.0
      ..attachScreenshot = false;
  });

  // ─── Phase 4/4 — observability scope ────────────────────────────────
  // Tags posés une fois pour toute la session : permettent de filtrer
  // les issues par app (com.arena.app vs com.arena.admin) et par
  // version sans avoir à inspecter chaque event individuellement.
  await Sentry.configureScope((scope) {
    scope
      ..setTag('flavor', flavor == Flavor.admin ? 'admin' : 'user')
      ..setTag('bundle_id', FlavorConfig.instance.bundleId);
  });
}

/// Push le user courant sur le scope Sentry quand la session bouge.
///
/// Appelé par `_initSupabase()` après l'init du client. Branché sur
/// `onAuthStateChange` (même flux que le hook Realtime JWT) :
///  * `signedIn` / `tokenRefreshed` → setUser(id, email)
///  * `signedOut`                    → setUser(null) + breadcrumb
///
/// Sentry n'a pas besoin du profile complet (username / role) ici —
/// on garde le hook côté Supabase auth pour rester async-safe et
/// indépendant de Riverpod (qui n'est pas encore prêt pendant le
/// pre-runApp). Le tag `role` peut être posé plus tard depuis
/// `currentProfileProvider` si besoin.
void _attachSentryUserBinder(SupabaseClient client) {
  // RGPD : on ne pousse QUE l'id (UUID) sur le scope Sentry — surtout pas
  // l'email, qui est une PII propagée hors de notre contrôle dès qu'un
  // event part vers Sentry (audit sécu 2026-05-23). L'id suffit pour
  // pivoter vers le profil côté équipe via le dashboard admin.
  //
  // Push initial — couvre le cas d'une session déjà restaurée.
  final initial = client.auth.currentSession?.user;
  if (initial != null) {
    Sentry.configureScope((scope) {
      scope.setUser(SentryUser(id: initial.id));
    });
  }

  client.auth.onAuthStateChange.listen((data) {
    final user = data.session?.user;
    final event = data.event;
    Sentry.configureScope((scope) {
      scope.setUser(
        user == null ? null : SentryUser(id: user.id),
      );
    });
    Sentry.addBreadcrumb(
      Breadcrumb(
        category: 'auth',
        message: event.name,
        level: SentryLevel.info,
        data: {
          if (user != null) 'user_id': user.id,
        },
      ),
    );
  });
}

Future<void> _loadEnv() async {
  try {
    await dotenv.load();
  } catch (_) {
    if (kDebugMode) {
      debugPrint('[bootstrap] .env not loaded — falling back to empty env.');
    }
  }
}

/// Initialise Firebase + register the FCM background handler.
///
/// Android pulls config from `app/src/<flavor>/google-services.json` via
/// the `com.google.gms.google-services` Gradle plugin. iOS lives behind
/// PHASE 8b (Apple Developer account required), so any failure on that
/// platform is logged but never crashes the boot.
Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(
      firebaseMessagingBackgroundHandler,
    );
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('[bootstrap] Firebase init skipped: $e\n$st');
    }
  }
}

Future<void> _initSupabase() async {
  final url = dotenv.env['SUPABASE_URL']?.trim() ?? '';
  final anon = dotenv.env['SUPABASE_ANON_KEY']?.trim() ?? '';
  final hasPlaceholder = url.contains('YOUR_PROJECT') || anon.contains('YOUR_');

  if (url.isEmpty || anon.isEmpty || hasPlaceholder) {
    if (kDebugMode) {
      debugPrint(
        '[bootstrap] Supabase creds missing/placeholder — '
        'skipping Supabase.initialize for now.',
      );
    }
    return;
  }

  await Supabase.initialize(url: url, anonKey: anon);

  // ─── Realtime auth refresh hook ──────────────────────────────────────
  // Supabase Flutter ne propage PAS automatiquement le nouveau JWT au
  // client Realtime quand la session se refresh (~60 min). Sans ce hook,
  // tous les `.from(t).stream(...)` et `.channel(...)` rejettent avec
  // `InvalidJWTToken: Token has expired N seconds ago` quelques secondes
  // après le refresh (observé 2026-05-19 sur Home + Compétitions).
  //
  // On écoute `onAuthStateChange` et on pousse le nouvel access_token
  // dans le client Realtime à chaque event (signedIn, tokenRefreshed,
  // signedOut → null). Listener fire-and-forget, jamais dispose : il
  // vit le temps de l'app.
  final client = Supabase.instance.client;
  client.auth.onAuthStateChange.listen((data) {
    final token = data.session?.accessToken;
    unawaited(client.realtime.setAuth(token));
  });
  // Push initial — couvre le cas où une session était déjà restaurée
  // depuis le storage avant que l'écouteur ne soit attaché.
  final initialToken = client.auth.currentSession?.accessToken;
  if (initialToken != null) {
    unawaited(client.realtime.setAuth(initialToken));
  }

  // Sentry user binder (Phase 4/4) — câblé après l'init Supabase. Le
  // hook est tolérant à un Sentry non-initialisé (SENTRY_DSN absent) :
  // `configureScope` et `addBreadcrumb` sont des no-ops dans ce cas.
  _attachSentryUserBinder(client);
}
