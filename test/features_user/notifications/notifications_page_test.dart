// Tests UI — NotificationsPage.
//
// ConsumerStatefulWidget : profil courant + flux `userNotificationsProvider`
// (family par userId). On couvre l'état déconnecté (profil null) et l'état
// vide (flux sans notification → _EmptyState).

import 'package:arena/data/models/arena_notification.dart';
import 'package:arena/data/models/profile.dart';
import 'package:arena/data/repositories/notification_repository.dart';
import 'package:arena/features_user/auth/auth_providers.dart';
import 'package:arena/features_user/notifications/notifications_page.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Profile _profile() => const Profile(
      id: 'p-1',
      username: 'Drogba',
      email: 'd@arena.app',
      countryCode: 'CI',
    );

Widget _scoped({required Profile? profile}) => ProviderScope(
      overrides: [
        currentProfileProvider.overrideWith((ref) => Stream.value(profile)),
        userNotificationsProvider.overrideWith(
          (ref, userId) => Stream<List<ArenaNotification>>.value(const []),
        ),
      ],
      child: const MaterialApp(
        locale: Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: NotificationsPage(),
      ),
    );

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  Future<void> bumpViewport(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets('profil null → placeholder « connecte-toi »', (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped(profile: null));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(
      find.text('Connecte-toi pour voir tes notifications.'),
      findsOneWidget,
    );
  });

  testWidgets('flux vide → état vide', (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped(profile: _profile()));
    // Le profil et le flux émettent sur des microtasks → laisser converger.
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Aucune notification pour le moment.'), findsOneWidget);
  });
}
