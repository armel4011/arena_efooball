import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/models/competition.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/data/models/profile.dart';
import 'package:arena/data/repositories/competition_repository.dart';
import 'package:arena/data/repositories/match_repository.dart';
import 'package:arena/data/repositories/profile_repository.dart';
import 'package:arena/features_user/match_room/match_room_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

/// Tests des providers d'orchestration de la MatchRoom. Les sources
/// (match / compétition / profils) sont overridées : on vérifie les VALEURS
/// DÉRIVÉES correctes selon l'état du match — pas le rendu.
void main() {
  ArenaMatch match({
    String id = 'm1',
    String competitionId = 'c1',
    String? p1 = 'p1',
    String? p2 = 'p2',
  }) =>
      ArenaMatch(
        id: id,
        competitionId: competitionId,
        player1Id: p1,
        player2Id: p2,
      );

  Competition comp({String id = 'c1', GameType game = GameType.efootball}) =>
      Competition(
        id: id,
        name: 'Coupe Arena',
        game: game,
        format: TournamentFormat.singleElimination,
        startDate: DateTime.utc(2026, 6, 14),
      );

  Profile profile(String id) =>
      Profile(id: id, username: 'user_$id', countryCode: 'CM');

  ProviderContainer makeContainer(List<Override> overrides) {
    final c = ProviderContainer(overrides: overrides);
    addTearDown(c.dispose);
    return c;
  }

  group('matchGameTypeProvider', () {
    test('match introuvable → efootball par défaut', () async {
      final c = makeContainer([
        matchByIdProvider('m1').overrideWith((ref) => Stream.value(null)),
      ]);

      final game = await c.read(matchGameTypeProvider('m1').future);
      expect(game, GameType.efootball);
    });

    test('résout le type de jeu porté par la COMPÉTITION (draughts)',
        () async {
      final c = makeContainer([
        matchByIdProvider('m1')
            .overrideWith((ref) => Stream.value(match(competitionId: 'c1'))),
        competitionByIdProvider('c1').overrideWith(
          (ref) => Stream.value(comp(game: GameType.draughts)),
        ),
      ]);

      final game = await c.read(matchGameTypeProvider('m1').future);
      expect(game, GameType.draughts);
    });

    test('compétition introuvable → efootball (fallback)', () async {
      final c = makeContainer([
        matchByIdProvider('m1')
            .overrideWith((ref) => Stream.value(match())),
        competitionByIdProvider('c1').overrideWith((ref) => Stream.value(null)),
      ]);

      final game = await c.read(matchGameTypeProvider('m1').future);
      expect(game, GameType.efootball);
    });
  });

  group('matchPlayersProvider', () {
    test('match introuvable → deux profils null, sans appel repo', () async {
      final repo = MockProfileRepository();
      final c = makeContainer([
        matchByIdProvider('m1').overrideWith((ref) => Stream.value(null)),
        profileRepositoryProvider.overrideWithValue(repo),
      ]);

      final players = await c.read(matchPlayersProvider('m1').future);
      expect(players.p1, isNull);
      expect(players.p2, isNull);
      verifyNever(() => repo.getPublicById(any()));
    });

    test('charge les deux profils via la vue PUBLIQUE (getPublicById)',
        () async {
      final repo = MockProfileRepository();
      when(() => repo.getPublicById('p1'))
          .thenAnswer((_) async => profile('p1'));
      when(() => repo.getPublicById('p2'))
          .thenAnswer((_) async => profile('p2'));

      final c = makeContainer([
        matchByIdProvider('m1')
            .overrideWith((ref) => Stream.value(match(p1: 'p1', p2: 'p2'))),
        profileRepositoryProvider.overrideWithValue(repo),
      ]);

      final players = await c.read(matchPlayersProvider('m1').future);
      expect(players.p1!.id, 'p1');
      expect(players.p2!.id, 'p2');
      // Jamais via getById (table self+admin) : profils cross-user = vue publique.
      verifyNever(() => repo.getById(any()));
      verify(() => repo.getPublicById('p1')).called(1);
      verify(() => repo.getPublicById('p2')).called(1);
    });

    test('joueur 2 non encore slotté (null) → p2 null sans appel repo',
        () async {
      final repo = MockProfileRepository();
      when(() => repo.getPublicById('p1'))
          .thenAnswer((_) async => profile('p1'));

      final c = makeContainer([
        matchByIdProvider('m1')
            .overrideWith((ref) => Stream.value(match(p1: 'p1', p2: null))),
        profileRepositoryProvider.overrideWithValue(repo),
      ]);

      final players = await c.read(matchPlayersProvider('m1').future);
      expect(players.p1!.id, 'p1');
      expect(players.p2, isNull);
      verifyNever(() => repo.getPublicById('p2'));
    });
  });

  group('pendingScoreSubmissionProvider (optimistic, survit aux remounts)', () {
    test('défaut null, scopé par matchId', () {
      final c = makeContainer([]);
      expect(c.read(pendingScoreSubmissionProvider('m1')), isNull);

      c.read(pendingScoreSubmissionProvider('m1').notifier).state = {
        'score1': 2,
        'score2': 1,
      };

      expect(c.read(pendingScoreSubmissionProvider('m1'))!['score1'], 2);
      // Un autre match garde son propre état indépendant.
      expect(c.read(pendingScoreSubmissionProvider('m2')), isNull);
    });
  });

  group('pendingRoomCodeProvider (optimistic code room)', () {
    test('défaut null puis mémorise le code partagé par match', () {
      final c = makeContainer([]);
      expect(c.read(pendingRoomCodeProvider('m1')), isNull);

      c.read(pendingRoomCodeProvider('m1').notifier).state = 'ABCD12';
      expect(c.read(pendingRoomCodeProvider('m1')), 'ABCD12');
      expect(c.read(pendingRoomCodeProvider('m2')), isNull);
    });
  });
}
