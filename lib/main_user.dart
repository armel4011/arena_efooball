import 'dart:async';

import 'package:arena/core/flavors/flavor_config.dart';
import 'package:arena/core/i18n/i18n_service.dart';
import 'package:arena/core/i18n/supported_locale.dart';
import 'package:arena/core/router/user_router.dart';
import 'package:arena/core/services/bootstrap.dart';
import 'package:arena/core/services/deep_link_service.dart';
import 'package:arena/core/services/notification_service.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/repositories/notification_repository.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
import 'package:arena/features_user/recording/overlay/recording_overlay.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
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
    _attachedUserId = userId;
    if (userId != null) {
      unawaited(service.attach(userId));
    } else {
      unawaited(service.detach(clearTokenOnServer: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(currentLocaleProvider);
    final router = ref.watch(userRouterProvider);

    ref.listen(currentSessionProvider, (_, session) {
      _syncNotificationsWithSession(session?.user.id);
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
