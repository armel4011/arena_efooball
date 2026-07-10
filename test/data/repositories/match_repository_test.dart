import 'package:arena/data/repositories/match_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '_supabase_mocks.dart';

void main() {
  late MockSupabaseClient client;
  late MatchRepository repo;

  setUp(() {
    client = MockSupabaseClient();
    repo = MatchRepository(client);
  });

  QueryProbe stub(String table, Object? result) =>
      stubFrom(client, table, result);

  Map<String, dynamic> matchRow({
    String id = 'm1',
    String competitionId = 'c1',
    String status = 'pending',
    int? round,
    int? matchNumber,
  }) =>
      {
        'id': id,
        'competition_id': competitionId,
        'status': status,
        if (round != null) 'round': round,
        if (matchNumber != null) 'match_number': matchNumber,
      };

  group('listForCompetition', () {
    test('filtre competition_id + ordonne round puis match_number', () async {
      final from = stub('matches', [
        matchRow(id: 'a', round: 1, matchNumber: 1),
        matchRow(id: 'b', round: 1, matchNumber: 2),
      ]);

      final matches = await repo.listForCompetition('c1');

      expect(matches, hasLength(2));
      expect(matches.first.id, 'a');
      expect(matches.first.competitionId, 'c1');
      expect(from.filters.any((f) => f == 'eq:competition_id=c1'), isTrue);
      expect(from.hasFilter('order', 'round'), isTrue);
      expect(from.hasFilter('order', 'match_number'), isTrue);
    });

    test('liste vide → []', () async {
      stub('matches', <Map<String, dynamic>>[]);
      expect(await repo.listForCompetition('c1'), isEmpty);
    });
  });

  group('listActiveForPlayer', () {
    test('OR sur les 2 sièges + exclut les statuts soldés + order/limit',
        () async {
      final from = stub('matches', [matchRow(id: 'm1', status: 'ready')]);

      final matches = await repo.listActiveForPlayer('me', limit: 5);

      expect(matches, hasLength(1));
      // OR couvre player1_id et player2_id du joueur.
      final orFilter = from.filters.firstWhere((f) => f.startsWith('or:'));
      expect(orFilter, contains('player1_id.eq.me'));
      expect(orFilter, contains('player2_id.eq.me'));
      // Statuts soldés exclus via NOT IN.
      final notFilter = from.filters.firstWhere((f) => f.startsWith('not:'));
      expect(notFilter, contains('completed'));
      expect(notFilter, contains('cancelled'));
      expect(notFilter, contains('forfeited'));
      expect(from.hasFilter('order', 'scheduled_at'), isTrue);
      expect(from.filters.any((f) => f == 'limit:_=5'), isTrue);
    });
  });

  group('listAnyForPlayer', () {
    test('OR sur les 2 sièges + tri finished_at desc puis scheduled_at',
        () async {
      final from = stub('matches', <Map<String, dynamic>>[]);
      await repo.listAnyForPlayer('me', limit: 10);
      final orFilter = from.filters.firstWhere((f) => f.startsWith('or:'));
      expect(orFilter, contains('player1_id.eq.me'));
      expect(from.hasFilter('order', 'finished_at'), isTrue);
      expect(from.hasFilter('order', 'scheduled_at'), isTrue);
      expect(from.filters.any((f) => f == 'limit:_=10'), isTrue);
    });
  });

  group('sendRoomCode', () {
    test("upper-case + trim le code, N'ÉCRIT QUE room_code (pas de statut)",
        () async {
      final from = stub('matches', null);
      await repo.sendRoomCode(matchId: 'm1', code: '  abc12 ');
      final values = from.updatedValues!;
      expect(values['room_code'], 'ABC12');
      // Nouveau flux : ne touche PAS au statut (sinon régresserait in_progress)
      // ni au siège home (déjà posé).
      expect(values.containsKey('status'), isFalse);
      expect(values.containsKey('home_player_id'), isFalse);
      expect(from.filters.any((f) => f == 'eq:id=m1'), isTrue);
    });
  });

  group('setTeamName', () {
    test('player1 → player1_team_name (trim)', () async {
      final from = stub('matches', null);
      await repo.setTeamName(
          matchId: 'm1', isPlayer1: true, teamName: ' FC X ');
      expect(from.updatedValues!['player1_team_name'], 'FC X');
      expect(from.updatedValues!.containsKey('player2_team_name'), isFalse);
    });

    test('player2 → player2_team_name', () async {
      final from = stub('matches', null);
      await repo.setTeamName(matchId: 'm1', isPlayer1: false, teamName: 'FC Y');
      expect(from.updatedValues!['player2_team_name'], 'FC Y');
      expect(from.updatedValues!.containsKey('player1_team_name'), isFalse);
    });
  });

  group('markInProgress', () {
    test('passe in_progress + stamp started_at', () async {
      final from = stub('matches', null);
      await repo.markInProgress('m1');
      expect(from.updatedValues!['status'], 'in_progress');
      expect(from.updatedValues!['started_at'], isA<String>());
      expect(from.filters.any((f) => f == 'eq:id=m1'), isTrue);
    });
  });

  group('flagDisputed', () {
    test('délègue à flag_score_dispute (litige matérialisé atomiquement)',
        () async {
      when(
        () => client.rpc<void>(
          'flag_score_dispute',
          params: any(named: 'params'),
        ),
      ).thenAnswer((_) => FakeQueryChain<void>(Future<void>.value()));

      await repo.flagDisputed('m1');

      verify(
        () => client.rpc<void>(
          'flag_score_dispute',
          params: {'p_match_id': 'm1'},
        ),
      ).called(1);
      // Plus d'UPDATE direct de matches.status : la RPC crée aussi la ligne
      // disputes pour la file d'arbitrage admin.
      verifyNever(() => client.from('matches'));
    });
  });

  group('submitScore', () {
    test('insère un event score_submitted avec le payload de base', () async {
      final from = stub('match_events', null);
      await repo.submitScore(
        matchId: 'm1',
        byProfileId: 'me',
        scoreP1: 3,
        scoreP2: 1,
      );
      final row = from.insertedValues! as Map<String, dynamic>;
      expect(row['match_id'], 'm1');
      expect(row['type'], 'score_submitted');
      expect(row['created_by'], 'me');
      final payload = row['payload'] as Map<String, dynamic>;
      expect(payload['score1'], 3);
      expect(payload['score2'], 1);
      // Pas de tirs au but quand non décidé aux pénos.
      expect(payload.containsKey('via_penalties'), isFalse);
      expect(payload.containsKey('proof_path'), isFalse);
    });

    test('stamp les pénos uniquement si decidedByPenalties', () async {
      final from = stub('match_events', null);
      await repo.submitScore(
        matchId: 'm1',
        byProfileId: 'me',
        scoreP1: 1,
        scoreP2: 1,
        decidedByPenalties: true,
        penaltyP1: 5,
        penaltyP2: 4,
        proofPath: 'p/1.jpg',
        proofMimeType: 'image/jpeg',
      );
      final payload = (from.insertedValues! as Map<String, dynamic>)['payload']
          as Map<String, dynamic>;
      expect(payload['via_penalties'], true);
      expect(payload['penalty1'], 5);
      expect(payload['penalty2'], 4);
      expect(payload['proof_path'], 'p/1.jpg');
      expect(payload['proof_mime'], 'image/jpeg');
    });
  });

  group('recordEvent', () {
    test('payload null → map vide par défaut', () async {
      final from = stub('match_events', null);
      await repo.recordEvent(matchId: 'm1', type: 'paused', byProfileId: 'me');
      final row = from.insertedValues! as Map<String, dynamic>;
      expect(row['type'], 'paused');
      expect(row['payload'], isEmpty);
    });
  });

  group('commitScore (RPC anti-triche)', () {
    test('délègue à finalize_match_score (score calculé serveur)', () async {
      when(
        () => client.rpc<void>(
          'finalize_match_score',
          params: any(named: 'params'),
        ),
      ).thenAnswer((_) => FakeQueryChain<void>(Future<void>.value()));

      await repo.commitScore(matchId: 'm1');

      verify(
        () => client.rpc<void>(
          'finalize_match_score',
          params: {'p_match_id': 'm1'},
        ),
      ).called(1);
      // Aucune écriture directe des colonnes protégées du match.
      verifyNever(() => client.from('matches'));
    });
  });

  group('markForfeit (RPC)', () {
    test('appelle forfeit_match sans p_reason quand reason == null', () async {
      when(
        () => client.rpc<void>('forfeit_match', params: any(named: 'params')),
      ).thenAnswer((_) => FakeQueryChain<void>(Future<void>.value()));

      await repo.markForfeit(
        matchId: 'm1',
        forfeitingPlayerId: 'me',
        opponentId: 'foe',
      );

      verify(
        () => client.rpc<void>(
          'forfeit_match',
          params: {'p_match_id': 'm1'},
        ),
      ).called(1);
    });

    test('inclut p_reason quand fourni', () async {
      when(
        () => client.rpc<void>('forfeit_match', params: any(named: 'params')),
      ).thenAnswer((_) => FakeQueryChain<void>(Future<void>.value()));

      await repo.markForfeit(
        matchId: 'm1',
        forfeitingPlayerId: 'me',
        opponentId: 'foe',
        reason: 'pause expirée',
      );

      verify(
        () => client.rpc<void>(
          'forfeit_match',
          params: {'p_match_id': 'm1', 'p_reason': 'pause expirée'},
        ),
      ).called(1);
    });
  });
}
