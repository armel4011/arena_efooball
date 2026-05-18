import 'dart:async';

import 'package:arena/core/flavors/flavor_config.dart';
import 'package:arena/core/services/notification_service.dart';
import 'package:arena/core/services/onboarding_service.dart';
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

    // ─── Critical path : on attend uniquement ce dont SplashPage a besoin
    // pour rendre sa première frame (SharedPreferences pour le flag
    // `has_seen_splash_v1`). Tout le reste (Supabase, Firebase, Sentry,
    // .env) est différé après `runApp` pour minimiser la durée du splash
    // natif (Android 12+ SplashScreen API garde l'icône au centre tant
    // que Flutter n'a pas peint).
    final prefs = await SharedPreferences.getInstance();
    final overrides = <Override>[
      sharedPreferencesProvider.overrideWithValue(prefs),
    ];

    // ─── Background init (~300-500ms total) — ne bloque PAS runApp.
    // Pendant ce temps, l'utilisateur voit le splash Flutter qui dure
    // 2.5s (récurrent) ou 5.3s (1er lancement), donc Supabase/Firebase
    // sont prêts bien avant que le splash se termine.
    unawaited(_initBackgroundServices(flavor: flavor));

    runApp(ProviderScope(overrides: overrides, child: builder()));
  }, (error, stack) {
    Sentry.captureException(error, stackTrace: stack);
  });
}

Future<void> _initBackgroundServices({required Flavor flavor}) async {
  await _loadEnv();
  // En parallèle : Supabase + Firebase + Sentry.
  await Future.wait<void>([
    _initSupabase(),
    _initFirebase(),
    _initSentry(flavor: flavor),
  ]);
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
}
