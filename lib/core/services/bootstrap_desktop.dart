import 'dart:async';

import 'package:arena/core/flavors/flavor_config.dart';
import 'package:arena/core/services/onboarding_service.dart';
import 'package:arena/core/theme/arena_fluent_theme.dart';
import 'package:arena/core/utils/sentry_provider_observer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:window_manager/window_manager.dart';

typedef DesktopAppBuilder = Widget Function();

/// Bootstrap de l'app ARENA Admin **Desktop** (Windows).
///
/// Différences avec le `bootstrap()` mobile :
///  * **Pas de Firebase** — FCM n'existe pas sur Windows. Les
///    notifications passent par Supabase Realtime (in-app, Vague 4).
///  * **window_manager** — taille minimale, taille par défaut, titre.
///  * Supabase / Sentry / dotenv / SharedPreferences : identiques.
Future<void> bootstrapDesktop({
  required String appName,
  required DesktopAppBuilder builder,
}) async {
  await runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlavorConfig.init(
      flavor: Flavor.admin,
      appName: appName,
      bundleId: 'com.arena.admin.desktop',
    );

    // ─── Fenêtre Windows ────────────────────────────────────────────
    await windowManager.ensureInitialized();
    // Barre de titre native masquée : c'est le TitleBar Fluent (shell) ou
    // le DesktopWindowDragStrip (écrans d'auth) qui fournit le drag + les
    // boutons réduire/agrandir/fermer (DesktopWindowCaption).
    const windowOptions = WindowOptions(
      size: Size(
        ArenaDesktop.defaultWindowWidth,
        ArenaDesktop.defaultWindowHeight,
      ),
      minimumSize: Size(
        ArenaDesktop.minWindowWidth,
        ArenaDesktop.minWindowHeight,
      ),
      center: true,
      title: 'ARENA Admin',
      backgroundColor: Color(0x00000000),
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: false,
    );
    unawaited(
      windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      }),
    );

    // ─── Critical path : prefs + .env + Supabase avant runApp ───────
    final prefs = await SharedPreferences.getInstance();
    final overrides = <Override>[
      sharedPreferencesProvider.overrideWithValue(prefs),
    ];

    await _loadEnv();
    await _initSupabase();

    // Sentry en arrière-plan — ne bloque pas la 1re frame.
    unawaited(_initSentry());

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

Future<void> _initSentry() async {
  // Desktop réutilise le DSN admin — même projet Sentry, tag dédié.
  final sentryDsn = (dotenv.env['SENTRY_DSN_ADMIN']?.trim().isNotEmpty ?? false)
      ? dotenv.env['SENTRY_DSN_ADMIN']!.trim()
      : (dotenv.env['SENTRY_DSN']?.trim() ?? '');

  if (sentryDsn.isEmpty) {
    if (kDebugMode) {
      debugPrint('[bootstrap-desktop] SENTRY_DSN missing — no Sentry.');
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

  await Sentry.configureScope((scope) {
    scope
      ..setTag('flavor', 'admin')
      ..setTag('platform', 'windows-desktop')
      ..setTag('bundle_id', FlavorConfig.instance.bundleId);
  });
}

Future<void> _loadEnv() async {
  try {
    await dotenv.load();
  } catch (_) {
    if (kDebugMode) {
      debugPrint('[bootstrap-desktop] .env not loaded — empty env fallback.');
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
        '[bootstrap-desktop] Supabase creds missing/placeholder — '
        'skipping Supabase.initialize.',
      );
    }
    return;
  }

  await Supabase.initialize(url: url, anonKey: anon);

  // Realtime auth refresh hook — même besoin que le mobile : Supabase
  // Flutter ne propage pas le JWT rafraîchi au client Realtime.
  final client = Supabase.instance.client;
  client.auth.onAuthStateChange.listen((data) {
    final token = data.session?.accessToken;
    unawaited(client.realtime.setAuth(token));
  });
  final initialToken = client.auth.currentSession?.accessToken;
  if (initialToken != null) {
    unawaited(client.realtime.setAuth(initialToken));
  }

  // Sentry user binder — uniquement l'UUID (RGPD, jamais l'email).
  // `configureScope` renvoie FutureOr<void> : on l'ignore explicitement
  // (no-op si Sentry n'est pas initialisé).
  final initial = client.auth.currentSession?.user;
  if (initial != null) {
    // ignore: discarded_futures
    Sentry.configureScope((scope) {
      scope.setUser(SentryUser(id: initial.id));
    });
  }
  client.auth.onAuthStateChange.listen((data) {
    final user = data.session?.user;
    // ignore: discarded_futures
    Sentry.configureScope((scope) {
      scope.setUser(user == null ? null : SentryUser(id: user.id));
    });
  });
}
