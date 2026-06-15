// Tests UI — AdminMessagesPage (inbox des messages ARENA → user).
//
// ConsumerWidget : session courante + flux `userAdminMessagesProvider`. La page
// lit aussi `adminChatRepositoryProvider` (→ `supabaseClientProvider`) au build,
// d'où l'override par un client mock. On couvre l'état déconnecté (scaffold
// vide) et l'état vide (flux sans message).

import 'package:arena/data/repositories/admin_chat_repository.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:arena/features_user/profile/admin_messages_page.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class _MockSupabaseClient extends Mock implements sb.SupabaseClient {}

class _FakeUser extends Fake implements sb.User {
  _FakeUser(this.id);
  @override
  final String id;
}

class _FakeSession extends Fake implements sb.Session {
  _FakeSession(String userId) : user = _FakeUser(userId);
  @override
  final sb.User user;
}

Widget _scoped({required bool signedIn}) => ProviderScope(
      overrides: [
        supabaseClientProvider.overrideWithValue(_MockSupabaseClient()),
        currentSessionProvider
            .overrideWith((ref) => signedIn ? _FakeSession('p-1') : null),
        userAdminMessagesProvider.overrideWith(
          (ref) => Stream<List<AdminChatMessage>>.value(const []),
        ),
      ],
      child: const MaterialApp(
        locale: Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AdminMessagesPage(),
      ),
    );

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  Future<void> bumpViewport(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets('déconnecté → pas de titre (scaffold vide)', (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped(signedIn: false));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('MESSAGES ARENA'), findsNothing);
  });

  testWidgets('connecté + flux vide → état vide', (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped(signedIn: true));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // ArenaAppBar met le titre en majuscules.
    expect(find.text('MESSAGES ARENA'), findsOneWidget);
    expect(find.text("Aucun message de la part d'ARENA."), findsOneWidget);
  });
}
