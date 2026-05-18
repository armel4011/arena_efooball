import 'dart:async';

import 'package:arena/core/flavors/flavor_config.dart';
import 'package:arena/core/i18n/i18n_service.dart';
import 'package:arena/core/i18n/supported_locale.dart';
import 'package:arena/core/router/admin_router.dart';
import 'package:arena/core/services/bootstrap.dart';
import 'package:arena/core/services/notification_service.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/repositories/notification_repository.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  await bootstrap(
    flavor: Flavor.admin,
    appName: 'ARENA Admin',
    bundleId: 'com.arena.admin',
    builder: ArenaAdminApp.new,
  );
}

class ArenaAdminApp extends ConsumerStatefulWidget {
  const ArenaAdminApp({super.key});

  @override
  ConsumerState<ArenaAdminApp> createState() => _ArenaAdminAppState();
}

class _ArenaAdminAppState extends ConsumerState<ArenaAdminApp> {
  NotificationService? _notifications;
  String? _attachedUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final router = ref.read(adminRouterProvider);
      _notifications = NotificationService(
        repository: ref.read(notificationRepositoryProvider),
        router: router,
      );
    });
  }

  @override
  void dispose() {
    _notifications?.detach();
    super.dispose();
  }

  void _syncNotificationsWithSession(String? userId) {
    final service = _notifications;
    if (service == null) return;
    if (userId == _attachedUserId) return;
    _attachedUserId = userId;
    if (userId != null) {
      // Lot B.1 — ping last_seen_at pour MAU/DAU.
      unawaited(_pingHeartbeat());
      unawaited(service.attach(userId));
    } else {
      unawaited(service.detach(clearTokenOnServer: true));
    }
  }

  Future<void> _pingHeartbeat() async {
    try {
      await ref.read(supabaseClientProvider).rpc<dynamic>('heartbeat');
    } catch (_) {
      // metric non-critique
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(currentLocaleProvider);
    final router = ref.watch(adminRouterProvider);

    ref.listen(currentSessionProvider, (_, session) {
      _syncNotificationsWithSession(session?.user.id);
    });

    return MaterialApp.router(
      title: FlavorConfig.instance.appName,
      debugShowCheckedModeBanner: false,
      theme: arenaAdminTheme,
      locale: locale.locale,
      supportedLocales: SupportedLocale.allFlutterLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: router,
    );
  }
}
