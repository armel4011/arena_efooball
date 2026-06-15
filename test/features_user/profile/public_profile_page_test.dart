// Tests UI — PublicProfilePage (profil public par username, Phase 13).
//
// ConsumerWidget : `publicProfileByUsernameProvider(username)` + (en interne)
// session/amitié/matchs récents. On override le profil public avec une valeur
// et les matchs récents avec une liste vide ; sans session (null), le bloc
// amitié retombe sur `data(null)`. On couvre le rendu et l'état introuvable.

import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/models/profile.dart';
import 'package:arena/data/repositories/friends_repository.dart';
import 'package:arena/data/repositories/match_stats_repository.dart';
import 'package:arena/features_shared/auth_common/shared_auth_providers.dart';
import 'package:arena/features_user/profile/public_profile_page.dart';
import 'package:arena/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

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

const _profile = Profile(
  id: 'p-2',
  username: 'Eto',
  countryCode: 'CM',
);

Widget _scoped({required Profile? publicProfile}) => ProviderScope(
      overrides: [
        // Session = le joueur affiché (p-2) → vue « soi-même » : pas de
        // _FriendCtaSection (qui accède à Supabase.instance), et `me!` dans le
        // body est non-null.
        currentSessionProvider.overrideWith((ref) => _FakeSession('p-2')),
        publicProfileByUsernameProvider
            .overrideWith((ref, username) async => publicProfile),
        friendshipBetweenProvider
            .overrideWith((ref, targetId) async => null),
        playerRecent10MatchesProvider
            .overrideWith((ref, id) async => <ArenaMatch>[]),
      ],
      child: const MaterialApp(
        locale: Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PublicProfilePage(username: 'Eto'),
      ),
    );

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  Future<void> bumpViewport(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets('profil trouvé → titre + username affiché', (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped(publicProfile: _profile));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // ArenaAppBar met le titre en majuscules.
    expect(find.text('PROFIL'), findsOneWidget);
    expect(find.text('Eto'), findsWidgets);
  });

  testWidgets("profil introuvable (null) → message d'erreur", (tester) async {
    await bumpViewport(tester);
    await tester.pumpWidget(_scoped(publicProfile: null));
    await tester.pumpAndSettle();

    expect(find.text('Joueur introuvable.'), findsOneWidget);
  });
}
