import 'package:arena/data/models/draughts_game_row.dart';
import 'package:arena/data/repositories/draughts_repository.dart';
import 'package:arena/features_user/draughts/engine/draughts_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:functions_client/functions_client.dart';
import 'package:mocktail/mocktail.dart';

import '_supabase_mocks.dart';

class MockFunctionsClient extends Mock implements FunctionsClient {}

/// Tests de COMPORTEMENT du repo dames :
///  * lecture Realtime : la partie ACTIVE est sélectionnée (status `active`
///    sinon la plus récente par game_number), filtre `match_id`, `null` si
///    aucune partie ;
///  * écriture : AUCUNE écriture directe — tout passe par l'Edge Function
///    `draughts-game` (autorité serveur). On vérifie l'action + le payload du
///    coup sérialisé + la remontée d'erreur stable (`DraughtsActionException`).
void main() {
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  Map<String, dynamic> gameRow({
    String id = 'g1',
    String matchId = 'm1',
    int gameNumber = 1,
    String status = 'active',
    int ply = 0,
    String currentTurn = 'white',
  }) =>
      {
        'id': id,
        'match_id': matchId,
        'game_number': gameNumber,
        'white_id': 'w',
        'black_id': 'b',
        'current_turn': currentTurn,
        'board_fen': 'W:WK1:BK50', // FEN arbitraire, non parsée par watch.
        'ply': ply,
        'sterile_plies': 0,
        'status': status,
        'white_clock_ms': 300000,
        'black_clock_ms': 300000,
        'last_move_at': '2026-06-14T10:00:00.000Z',
      };

  group('watchActiveGame', () {
    test('aucune partie (liste vide) → émet null', () async {
      final client = MockSupabaseClient();
      final probe = stubStream(
        client,
        'draughts_games',
        Stream.value(<Map<String, dynamic>>[]),
      );
      final repo = DraughtsRepository(client);

      final first = await repo.watchActiveGame('m1').first;
      expect(first, isNull);
      // primaryKey + filtre Realtime corrects.
      expect(probe.primaryKey, ['id']);
      expect(probe.eqColumn, 'match_id');
      expect(probe.eqValue, 'm1');
    });

    test('une seule partie active → la mappe', () async {
      final client = MockSupabaseClient();
      stubStream(
        client,
        'draughts_games',
        Stream.value([gameRow(id: 'g1', ply: 3, currentTurn: 'black')]),
      );
      final repo = DraughtsRepository(client);

      final row = await repo.watchActiveGame('m1').first;
      expect(row, isA<DraughtsGameRow>());
      expect(row!.id, 'g1');
      expect(row.ply, 3);
      expect(row.isActive, isTrue);
      expect(row.turn, Side.black);
    });

    test(
      'plusieurs parties : sélectionne celle au status active, '
      'pas seulement la plus récente',
      () async {
        final client = MockSupabaseClient();
        // g3 est la plus récente (game_number 3) mais terminée ; g2 est active.
        stubStream(
          client,
          'draughts_games',
          Stream.value([
            gameRow(id: 'g1', gameNumber: 1, status: 'white_won'),
            gameRow(id: 'g3', gameNumber: 3, status: 'black_won'),
            gameRow(id: 'g2', gameNumber: 2, status: 'active'),
          ]),
        );
        final repo = DraughtsRepository(client);

        final row = await repo.watchActiveGame('m1').first;
        expect(row!.id, 'g2');
        expect(row.isActive, isTrue);
      },
    );

    test(
      'aucune partie active → fallback sur la plus récente (game_number max)',
      () async {
        final client = MockSupabaseClient();
        stubStream(
          client,
          'draughts_games',
          Stream.value([
            gameRow(id: 'g1', gameNumber: 1, status: 'white_won'),
            gameRow(id: 'g2', gameNumber: 2, status: 'draw'),
          ]),
        );
        final repo = DraughtsRepository(client);

        final row = await repo.watchActiveGame('m1').first;
        // game_number 2 > 1, et aucune n'est active → la plus récente.
        expect(row!.id, 'g2');
        expect(row.isActive, isFalse);
      },
    );

    test('émet pour chaque événement Realtime successif', () async {
      final client = MockSupabaseClient();
      stubStream(
        client,
        'draughts_games',
        Stream.fromIterable([
          [gameRow(id: 'g1', ply: 0)],
          [gameRow(id: 'g1', ply: 1, currentTurn: 'black')],
          <Map<String, dynamic>>[],
        ]),
      );
      final repo = DraughtsRepository(client);

      final emitted = await repo.watchActiveGame('m1').toList();
      expect(emitted, hasLength(3));
      expect(emitted[0]!.ply, 0);
      expect(emitted[1]!.ply, 1);
      expect(emitted[2], isNull);
    });
  });

  group('Edge Function actions (aucune écriture directe)', () {
    late MockSupabaseClient client;
    late MockFunctionsClient functions;
    late DraughtsRepository repo;

    setUp(() {
      client = MockSupabaseClient();
      functions = MockFunctionsClient();
      when(() => client.functions).thenReturn(functions);
      repo = DraughtsRepository(client);
    });

    void stubInvoke(Object? data, {int status = 200}) {
      when(
        () => functions.invoke(
          'draughts-game',
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => FunctionResponse(data: data, status: status));
    }

    Map<String, dynamic> capturedBody() {
      final captured = verify(
        () => functions.invoke('draughts-game', body: captureAny(named: 'body')),
      ).captured;
      return (captured.last as Map).cast<String, dynamic>();
    }

    test('start → action=start + matchId, sans move', () async {
      stubInvoke(<String, dynamic>{'ok': true});
      await repo.start('m1');
      final body = capturedBody();
      expect(body['action'], 'start');
      expect(body['matchId'], 'm1');
      expect(body.containsKey('move'), isFalse);
    });

    test('claimTimeout → action=timeout', () async {
      stubInvoke(<String, dynamic>{'ok': true});
      await repo.claimTimeout('m1');
      expect(capturedBody()['action'], 'timeout');
    });

    test('move → action=move + sérialise from/to/captured', () async {
      stubInvoke(<String, dynamic>{'status': 'active', 'ply': 1});
      const m = DraughtsMove(
        from: 31,
        to: 22,
        captured: [26],
        path: [31, 26, 22],
      );

      final res = await repo.move('m1', m);

      expect(res['ply'], 1);
      final body = capturedBody();
      expect(body['action'], 'move');
      expect(body['matchId'], 'm1');
      final move = (body['move'] as Map).cast<String, dynamic>();
      expect(move['from'], 31);
      expect(move['to'], 22);
      expect(move['captured'], [26]);
      // `path` est un détail UI : il ne part PAS au serveur (autorité = EF).
      expect(move.containsKey('path'), isFalse);
    });

    test('move simple → captured vide', () async {
      stubInvoke(<String, dynamic>{'status': 'active'});
      await repo.move('m1', DraughtsMove.simple(32, 28));
      final move = (capturedBody()['move'] as Map).cast<String, dynamic>();
      expect(move['captured'], isEmpty);
    });

    test(
      'status != 200 avec champ error → DraughtsActionException(code stable)',
      () async {
        stubInvoke(<String, dynamic>{'error': 'not_your_turn'}, status: 409);
        expect(
          () => repo.move('m1', DraughtsMove.simple(32, 28)),
          throwsA(
            isA<DraughtsActionException>().having(
              (e) => e.code,
              'code',
              'not_your_turn',
            ),
          ),
        );
      },
    );

    test('status != 200 sans champ error → code http_<status>', () async {
      stubInvoke(null, status: 500);
      expect(
        repo.start('m1'),
        throwsA(
          isA<DraughtsActionException>()
              .having((e) => e.code, 'code', 'http_500'),
        ),
      );
    });

    test('status 200 mais data null → renvoie une map vide (pas de throw)',
        () async {
      stubInvoke(null);
      final res = await repo.move('m1', DraughtsMove.simple(32, 28));
      expect(res, isEmpty);
    });
  });
}
