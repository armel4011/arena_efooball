import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '_supabase_mocks.dart';

void main() {
  late MockSupabaseClient client;
  late ProfileRepository repo;

  setUp(() {
    client = MockSupabaseClient();
    repo = ProfileRepository(client);
  });

  QueryProbe stub(String table, Object? result) =>
      stubFrom(client, table, result);

  Map<String, dynamic> profileRow({String id = 'u1', String? username}) => {
        'id': id,
        'username': username ?? 'jdoe',
        'country_code': 'CM',
        'avatar_color': '#4C7AFF',
        'role': 'player',
      };

  group('getById', () {
    test('lit la table profiles avec la liste de colonnes explicite '
        '(sans totp_secret / backup_codes)', () async {
      final from = stub('profiles', profileRow());
      await repo.getById('u1');

      final cols = from.selectedColumns!;
      expect(cols, contains('id'));
      expect(cols, contains('username'));
      expect(cols, contains('email'));
      // Le verrou C-1 : aucune colonne secrète ne doit être demandée.
      expect(cols, isNot(contains('totp_secret')));
      expect(cols, isNot(contains('backup_codes')));
      // Le sondage jeux : la colonne DOIT être lue, sinon le dialogue
      // obligatoire se rejouerait pour tout le monde (game_interests → null).
      expect(cols, contains('game_interests'));
      // Filtre sur l'id + maybeSingle.
      expect(from.hasFilter('eq', 'id'), isTrue);
      expect(from.hasFilter('maybeSingle', '_'), isTrue);
    });

    test('row non null → Profile parsé', () async {
      stub('profiles', profileRow(username: 'alice'));
      final p = await repo.getById('u1');
      expect(p, isNotNull);
      expect(p!.username, 'alice');
      expect(p.id, 'u1');
    });

    test('row null → null', () async {
      stub('profiles', null);
      expect(await repo.getById('absent'), isNull);
    });
  });

  group('getPublicById', () {
    test('lit la vue public_profiles avec les colonnes publiques', () async {
      final from = stub('public_profiles', profileRow());
      await repo.getPublicById('u1');

      final cols = from.selectedColumns!;
      expect(cols, contains('username'));
      expect(cols, contains('last_seen_at'));
      // La vue publique n'expose pas l'email (PII).
      expect(cols, isNot(contains('email')));
      expect(from.hasFilter('eq', 'id'), isTrue);
    });

    test('row null → null', () async {
      stub('public_profiles', null);
      expect(await repo.getPublicById('x'), isNull);
    });
  });

  group('getByIds', () {
    test('ids vides → map vide sans requête', () async {
      final result = await repo.getByIds(const []);
      expect(result, isEmpty);
      verifyNever(() => client.from(any()));
    });

    test('dédoublonne les ids et lit la vue publique via inFilter', () async {
      final from = stub('public_profiles', [
        profileRow(id: 'a', username: 'aa'),
        profileRow(id: 'b', username: 'bb'),
      ]);

      final map = await repo.getByIds(['a', 'b', 'a']);

      expect(map.keys, containsAll(<String>['a', 'b']));
      expect(map['a']!.username, 'aa');
      expect(map['b']!.username, 'bb');
      expect(from.hasFilter('in', 'id'), isTrue);
      // Colonnes publiques, pas d'email.
      expect(from.selectedColumns, isNot(contains('email')));
    });

    test("clé du map = Profile.id (et non l'ordre d'entrée)", () async {
      stub('public_profiles', [profileRow(id: 'zzz', username: 'z')]);
      final map = await repo.getByIds(['zzz']);
      expect(map.containsKey('zzz'), isTrue);
      expect(map['zzz']!.id, 'zzz');
    });
  });

  group('usernameExists', () {
    test('chaîne vide → false sans requête', () async {
      expect(await repo.usernameExists('   '), isFalse);
      verifyNever(() => client.from(any()));
    });

    test('row trouvée (ilike sur la vue publique) → true', () async {
      final from = stub('public_profiles', {'id': 'u1'});
      expect(await repo.usernameExists('jdoe'), isTrue);
      expect(from.hasFilter('ilike', 'username'), isTrue);
      expect(from.selectedColumns, 'id');
    });

    test('aucune row → false', () async {
      stub('public_profiles', null);
      expect(await repo.usernameExists('inconnu'), isFalse);
    });

    test('username trimé avant la requête', () async {
      final from = stub('public_profiles', null);
      await repo.usernameExists('  spaced  ');
      expect(
        from.filters.any((f) => f == 'ilike:username=spaced'),
        isTrue,
      );
    });
  });

  group('normalisation Profile.fromJson via le repo', () {
    test('colonnes secrètes présentes dans la row sont ignorées', () async {
      final row = profileRow()
        ..['totp_secret'] = 'SECRET'
        ..['backup_codes'] = <String>['c1'];
      stub('profiles', row);
      // Ne doit pas lever malgré les colonnes en trop.
      final p = await repo.getById('u1');
      expect(p, isNotNull);
      expect(p!.username, 'jdoe');
    });

    test('email absent (vue publique) → Profile.email null', () async {
      stub('public_profiles', profileRow());
      final p = await repo.getPublicById('u1');
      expect(p!.email, isNull);
    });

    test('game_interests null (jamais répondu) → hasAnsweredGameInterests false',
        () async {
      stub('profiles', profileRow());
      final p = await repo.getById('u1');
      expect(p!.gameInterests, isNull);
      expect(p.hasAnsweredGameInterests, isFalse);
    });

    test('game_interests présent → List<GameType> + hasAnswered true', () async {
      final row = profileRow()..['game_interests'] = ['efootball', 'draughts'];
      stub('profiles', row);
      final p = await repo.getById('u1');
      expect(p!.hasAnsweredGameInterests, isTrue);
      expect(p.gameInterests, [GameType.efootball, GameType.draughts]);
    });
  });

  group('setGameInterests (RPC set_game_interests)', () {
    test('envoie les GameType.value dans p_games', () async {
      when(
        () => client.rpc<void>(
          'set_game_interests',
          params: any(named: 'params'),
        ),
      ).thenAnswer((_) => FakeQueryChain<void>(Future<void>.value()));

      await repo.setGameInterests([GameType.efootball, GameType.eaSportsFc]);

      final captured = verify(
        () => client.rpc<void>(
          'set_game_interests',
          params: captureAny(named: 'params'),
        ),
      ).captured.single as Map<String, dynamic>;
      expect(captured['p_games'], ['efootball', 'ea_sports_fc']);
    });
  });
}
