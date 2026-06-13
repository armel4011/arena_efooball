import 'dart:async';

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
      // Les compétitions archivées sont exclues (archived_at IS NULL).
      expect(from.hasFilter('is', 'archived_at'), isTrue);
    });

    test('filtre par game quand fourni', () async {
      final from = stub('competitions', <Map<String, dynamic>>[]);
      await repo.list(game: GameType.draughts);
      expect(
        from.filters.any((f) => f == 'eq:game=draughts'),
        isTrue,
      );
    });

    test('liste vide → []', () async {
      stub('competitions', <Map<String, dynamic>>[]);
      expect(await repo.list(), isEmpty);
    });
  });

  group("tri épinglées d'abord", () {
    Map<String, dynamic> pinnedRow({
      required String id,
      required bool isPinned,
      String? pinnedAt,
      String startDate = '2026-07-01T18:00:00.000Z',
    }) =>
        {
          'id': id,
          'name': id,
          'game': 'efootball',
          'format': 'single_elimination',
          'start_date': startDate,
          'status': 'registration_open',
          'max_players': 16,
          'is_pinned': isPinned,
          if (pinnedAt != null) 'pinned_at': pinnedAt,
        };

    test('list : épinglées en tête, par pinnedAt desc, autres par startDate',
        () async {
      // La requête renvoie déjà l'ordre start_date croissant (a, b, c, d).
      stub('competitions', [
        pinnedRow(id: 'a', isPinned: false, startDate: '2026-07-01T00:00:00Z'),
        pinnedRow(
          id: 'b',
          isPinned: true,
          pinnedAt: '2026-06-01T00:00:00Z',
          startDate: '2026-07-02T00:00:00Z',
        ),
        pinnedRow(id: 'c', isPinned: false, startDate: '2026-07-03T00:00:00Z'),
        pinnedRow(
          id: 'd',
          isPinned: true,
          pinnedAt: '2026-06-10T00:00:00Z',
          startDate: '2026-07-04T00:00:00Z',
        ),
      ]);

      final comps = await repo.list();
      // d épinglé le 10/06 (plus récent) avant b épinglé le 01/06 ;
      // puis les non-épinglés a, c dans l'ordre start_date d'origine.
      expect(comps.map((c) => c.id).toList(), ['d', 'b', 'a', 'c']);
    });

    test('list : épinglée sans pinnedAt passe après celle qui en a un',
        () async {
      stub('competitions', [
        pinnedRow(id: 'x', isPinned: true), // pinnedAt absent → null
        pinnedRow(id: 'y', isPinned: true, pinnedAt: '2026-06-01T00:00:00Z'),
      ]);
      final comps = await repo.list();
      expect(comps.map((c) => c.id).toList(), ['y', 'x']);
    });

    test("list : tri stable — non-épinglées gardent l'ordre d'entrée",
        () async {
      stub('competitions', [
        pinnedRow(id: 'a', isPinned: false),
        pinnedRow(id: 'b', isPinned: false),
        pinnedRow(id: 'c', isPinned: false),
      ]);
      final comps = await repo.list();
      expect(comps.map((c) => c.id).toList(), ['a', 'b', 'c']);
    });

    test("watch : applique le même tri épinglées-d'abord", () async {
      stubStream(
        client,
        'competitions',
        Stream.value([
          pinnedRow(id: 'a', isPinned: false),
          pinnedRow(
            id: 'b',
            isPinned: true,
            pinnedAt: '2026-06-10T00:00:00Z',
          ),
        ]),
      );

      final list = await repo.watch().first;
      expect(list.map((c) => c.id).toList(), ['b', 'a']);
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

  group('getParticipants', () {
    test('aucune inscription → liste vide, pas de requête profils', () async {
      stub('competition_registrations', <Map<String, dynamic>>[]);
      final parts = await repo.getParticipants('c1');
      expect(parts, isEmpty);
      verifyNever(() => client.from('public_profiles'));
    });

    test('joint registrations + public_profiles, confirmés en tête', () async {
      stub('competition_registrations', [
        {'player_id': 'p1', 'status': 'pending'},
        {'player_id': 'p2', 'status': 'confirmed'},
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

      final parts = await repo.getParticipants('c1');

      expect(parts, hasLength(2));
      // Confirmé d'abord, même si alphabétiquement après.
      expect(parts.first.playerId, 'p2');
      expect(parts.first.isConfirmed, isTrue);
      expect(parts.last.playerId, 'p1');
      expect(parts.last.isConfirmed, isFalse);
      // Profils résolus via la vue publique (pas de colonne email).
      expect(profiles.hasFilter('in', 'id'), isTrue);
      expect(profiles.selectedColumns, isNot(contains('email')));
    });

    test('même statut → tri alphabétique sur username', () async {
      stub('competition_registrations', [
        {'player_id': 'p1', 'status': 'confirmed'},
        {'player_id': 'p2', 'status': 'confirmed'},
      ]);
      stub('public_profiles', [
        {'id': 'p1', 'username': 'Zoe', 'country_code': 'CM'},
        {'id': 'p2', 'username': 'Adam', 'country_code': 'CM'},
      ]);

      final parts = await repo.getParticipants('c1');
      expect(parts.first.username, 'Adam');
      expect(parts.last.username, 'Zoe');
    });

    test('profil manquant → fallback username "—"', () async {
      stub('competition_registrations', [
        {'player_id': 'ghost', 'status': 'confirmed'},
      ]);
      stub('public_profiles', <Map<String, dynamic>>[]);

      final parts = await repo.getParticipants('c1');
      expect(parts.single.username, '—');
      expect(parts.single.avatarColor, '#4C7AFF');
    });
  });
}
