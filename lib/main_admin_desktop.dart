import 'package:arena/core/flavors/flavor_config.dart';
import 'package:arena/core/i18n/i18n_service.dart';
import 'package:arena/core/i18n/supported_locale.dart';
import 'package:arena/core/router/admin_desktop_router.dart';
import 'package:arena/core/services/bootstrap_desktop.dart';
import 'package:arena/core/theme/arena_fluent_theme.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Point d'entrée ARENA Admin **Desktop** (Windows).
///
/// Lancement :
/// ```sh
/// flutter run -d windows -t lib/main_admin_desktop.dart
/// flutter build windows -t lib/main_admin_desktop.dart
/// ```
///
/// Design Fluent UI (Windows 11) — le code métier (repositories,
/// providers, modèles) est partagé avec l'app mobile.
Future<void> main() async {
  await bootstrapDesktop(
    appName: 'ARENA Admin',
    builder: ArenaAdminDesktopApp.new,
  );
}

class ArenaAdminDesktopApp extends ConsumerWidget {
  const ArenaAdminDesktopApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(currentLocaleProvider);
    final router = ref.watch(adminDesktopRouterProvider);

    return FluentApp.router(
      title: FlavorConfig.instance.appName,
      debugShowCheckedModeBanner: false,
      theme: ArenaFluentTheme.dark(),
      darkTheme: ArenaFluentTheme.dark(),
      themeMode: ThemeMode.dark,
      locale: locale.locale,
      supportedLocales: SupportedLocale.allFlutterLocales,
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        FluentLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
