import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/data/repositories/competition_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '_supabase_mocks.dart';

void main() {
  late MockSupabaseClient client;
  late CompetitionRepository repo;

  setUp(() {
    client = MockSupabaseClient();
    repo = CompetitionRepository(client);
  });

  QueryProbe stub(String table, Object? result) =>
      stubFrom(client, table, result);

  Map<String, dynamic> competitionRow({
    String id = 'c1',
    String name = 'Coupe Arena',
    String game = 'efootball',
  }) =>
      {
        'id': id,
        'name': name,
        'game': game,
        'format': 'single_elimination',
        'start_date': '2026-07-01T18:00:00.000Z',
        'status': 'registration_open',
        'max_players': 16,
      };

  group('list', () {
    test('parse les rows en Competition + applique order/limit', () async {
      final from = stub('competitions', [
        competitionRow(id: 'c1', name: 'A'),
        competitionRow(id: 'c2', name: 'B'),
      ]);

      final comps = await repo.list();

      expect(comps, hasLength(2));
      expect(comps.first.name, 'A');
      expect(comps.first.game, GameType.efootball);
      expect(comps.first.format, TournamentFormat.singleElimination);
      // order(start_date) + limit appliqués.
      expect(from.hasFilter('order', 'start_date'), isTrue);
      expect(from.filters.any((f) => f.startsWith('limit:')), isTrue);
      // Pas de filtre game quand game == null.
      expect(from.hasFilter('eq', 'game'), isFalse);
    });

    test('filtre par game quand fourni', () async {
      final from = stub('competitions', <Map<String, dynamic>>[]);
      await repo.list(game: GameType.fifaMobile);
      expect(
        from.filters.any((f) => f == 'eq:game=fifa_mobile'),
        isTrue,
      );
    });

    test('liste vide → []', () async {
      stub('competitions', <Map<String, dynamic>>[]);
      expect(await repo.list(), isEmpty);
    });
  });

  group('getById', () {
    test('row null → null', () async {
      stub('competitions', null);
      expect(await repo.getById('absent'), isNull);
    });

    test('row → Competition parsée avec defaults', () async {
      stub('competitions', competitionRow(id: 'c9'));
      final c = await repo.getById('c9');
      expect(c, isNotNull);
      expect(c!.id, 'c9');
      expect(c.status, CompetitionStatus.registrationOpen);
      // Défaut Freezed appliqué (non présent dans la row).
      expect(c.registrationFee, 0);
    });
  });

  group('getRanking', () {
    test('aucune inscription → liste vide, pas de 2e requête profils',
        () async {
      stub('competition_registrations', <Map<String, dynamic>>[]);
      final ranking = await repo.getRanking('c1');
      expect(ranking, isEmpty);
      // public_profiles ne doit pas être interrogée s'il n'y a aucun id.
      verifyNever(() => client.from('public_profiles'));
    });

    test('joint registrations + public_profiles et trie par final_rank',
        () async {
      stub('competition_registrations', [
        {'player_id': 'p1', 'final_rank': 2},
        {'player_id': 'p2', 'final_rank': 1},
      ]);
      final profiles = stub('public_profiles', [
        {
          'id': 'p1',
          'username': 'alpha',
          'country_code': 'CM',
          'avatar_color': '#111111',
        },
        {
          'id': 'p2',
          'username': 'bravo',
          'country_code': 'CI',
          'avatar_color': '#222222',
        },
      ]);

      final ranking = await repo.getRanking('c1');

      expect(ranking, hasLength(2));
      // Trié par final_rank croissant : p2 (rank 1) avant p1 (rank 2).
      expect(ranking.first.playerId, 'p2');
      expect(ranking.first.username, 'bravo');
      expect(ranking.first.finalRank, 1);
      expect(ranking.last.playerId, 'p1');
      // Profils résolus via la vue publique avec colonnes restreintes.
      expect(profiles.hasFilter('in', 'id'), isTrue);
      expect(profiles.selectedColumns, isNot(contains('email')));
    });

    test('non-classés (final_rank null) renvoyés en fin de liste', () async {
      stub('competition_registrations', [
        {'player_id': 'p1', 'final_rank': null},
        {'player_id': 'p2', 'final_rank': 3},
      ]);
      stub('public_profiles', [
        {'id': 'p1', 'username': 'zeta', 'country_code': 'CM'},
        {'id': 'p2', 'username': 'beta', 'country_code': 'CM'},
      ]);

      final ranking = await repo.getRanking('c1');
      expect(ranking.first.playerId, 'p2'); // classé
      expect(ranking.last.playerId, 'p1'); // non classé en dernier
      expect(ranking.last.finalRank, isNull);
    });

    test('profil manquant → fallback username "—" et avatar par défaut',
        () async {
      stub('competition_registrations', [
        {'player_id': 'ghost', 'final_rank': 1},
      ]);
      stub('public_profiles', <Map<String, dynamic>>[]);

      final ranking = await repo.getRanking('c1');
      expect(ranking, hasLength(1));
      expect(ranking.first.username, '—');
      expect(ranking.first.avatarColor, '#4C7AFF');
      expect(ranking.first.countryCode, '');
    });

    test('égalité de rang → tri secondaire alphabétique sur username',
        () async {
      stub('competition_registrations', [
        {'player_id': 'p1', 'final_rank': 1},
        {'player_id': 'p2', 'final_rank': 1},
      ]);
      stub('public_profiles', [
        {'id': 'p1', 'username': 'Zoe', 'country_code': 'CM'},
        {'id': 'p2', 'username': 'Adam', 'country_code': 'CM'},
      ]);

      final ranking = await repo.getRanking('c1');
      expect(ranking.first.username, 'Adam');
      expect(ranking.last.username, 'Zoe');
    });
  });
}
