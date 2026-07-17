import 'package:arena/data/repositories/admin/admin_disputes_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../_supabase_mocks.dart';

void main() {
  late MockSupabaseClient client;
  late AdminDisputesRepository repo;

  setUp(() {
    client = MockSupabaseClient();
    repo = AdminDisputesRepository(client);
  });

  QueryProbe stub(String table, Object? result) =>
      stubFrom(client, table, result);

  Map<String, dynamic> disputeRow({String id = 'd1', String status = 'open'}) =>
      {
        'id': id,
        'match_id': 'm1',
        'opened_by': 'p1',
        'status': status,
      };

  group('listAll', () {
    test('openOnly (défaut) → ne garde que open/escalated', () async {
      stub('disputes', [
        disputeRow(id: 'a'),
        disputeRow(id: 'b', status: 'resolved'),
        disputeRow(id: 'c', status: 'escalated'),
      ]);
      final list = await repo.listAll();
      expect(list.map((d) => d.id), ['a', 'c']);
    });

    test('openOnly:false → tout, ordonné par created_at', () async {
      final from = stub('disputes', [disputeRow(status: 'resolved')]);
      final list = await repo.listAll(openOnly: false);
      expect(list, hasLength(1));
      expect(from.hasFilter('order', 'created_at'), isTrue);
    });
  });

  group('getByMatchId', () {
    test('aucun litige → null', () async {
      stub('disputes', null);
      expect(await repo.getByMatchId('m1'), isNull);
    });

    test('row → Dispute, filtre match_id', () async {
      final from = stub('disputes', disputeRow());
      final d = await repo.getByMatchId('m1');
      expect(d!.id, 'd1');
      expect(from.filters.any((f) => f == 'eq:match_id=m1'), isTrue);
    });
  });

  group('fetchProofs', () {
    // Les preuves vivent dans match_events.payload (jsonb), pas dans des
    // colonnes dédiées. Un event sans proof_path dans le payload n'est PAS
    // une preuve (ex: score_submitted sans capture).
    Map<String, dynamic> eventRow({
      String? proofPath = 'm1/p1/1.png',
      String? proofMime = 'image/png',
      String createdBy = 'p1',
    }) =>
        {
          'payload': <String, dynamic>{
            'score1': 2,
            'score2': 1,
            if (proofPath != null) 'proof_path': proofPath,
            if (proofMime != null) 'proof_mime': proofMime,
          },
          'created_by': createdBy,
          'created_at': '2026-06-14T10:00:00Z',
        };

    test('interroge match_events.payload pour le match, plus récents en tête',
        () async {
      final from = stubFrom(client, 'match_events', [eventRow()]);
      final proofs = await repo.fetchProofs('m1');
      expect(proofs, hasLength(1));
      expect(proofs.single.path, 'm1/p1/1.png');
      // On lit le payload jsonb (pas de colonne proof_path).
      expect(from.selectedColumns, contains('payload'));
      expect(from.hasFilter('eq', 'match_id'), isTrue);
      expect(from.filters.any((f) => f == 'eq:match_id=m1'), isTrue);
      expect(from.hasFilter('order', 'created_at'), isTrue);
    });

    test('distingue image vs vidéo selon le mime', () async {
      stubFrom(client, 'match_events', [
        eventRow(proofPath: 'm1/p1/a.png', proofMime: 'image/png'),
        eventRow(proofPath: 'm1/p2/b.mp4', proofMime: 'video/mp4'),
      ]);
      final proofs = await repo.fetchProofs('m1');
      expect(proofs[0].isImage, isTrue);
      expect(proofs[0].isVideo, isFalse);
      expect(proofs[1].isVideo, isTrue);
      expect(proofs[1].isImage, isFalse);
    });

    test('mime manquant → repli sur l’extension du chemin', () async {
      stubFrom(client, 'match_events', [
        eventRow(proofPath: 'm1/p1/clip.mov', proofMime: null),
        eventRow(proofPath: 'm1/p2/shot.jpg', proofMime: null),
      ]);
      final proofs = await repo.fetchProofs('m1');
      expect(proofs[0].isVideo, isTrue);
      expect(proofs[1].isVideo, isFalse);
    });

    test('ignore les events sans proof_path dans le payload', () async {
      stubFrom(client, 'match_events', [
        eventRow(),
        eventRow(proofPath: null),
        eventRow(proofPath: ''),
      ]);
      final proofs = await repo.fetchProofs('m1');
      expect(proofs, hasLength(1));
      expect(proofs.single.playerId, 'p1');
      expect(proofs.single.createdAt, isNotNull);
    });
  });

  group('fetchSubmittedScores', () {
    Map<String, dynamic> scoreRow({
      required String createdBy,
      required int score1,
      required int score2,
      bool viaPen = false,
      int? pen1,
      int? pen2,
      String createdAt = '2026-07-11T10:00:00Z',
    }) =>
        {
          'payload': <String, dynamic>{
            'score1': score1,
            'score2': score2,
            if (viaPen) 'via_penalties': true,
            if (pen1 != null) 'penalty1': pen1,
            if (pen2 != null) 'penalty2': pen2,
          },
          'created_by': createdBy,
          'created_at': createdAt,
        };

    test('map player_id → score déclaré (divergence visible en litige)',
        () async {
      final from = stubFrom(client, 'match_events', [
        scoreRow(createdBy: 'p1', score1: 2, score2: 1),
        scoreRow(createdBy: 'p2', score1: 1, score2: 2),
      ]);
      final subs = await repo.fetchSubmittedScores('m1');
      expect(subs['p1']!.label, '2-1');
      expect(subs['p2']!.label, '1-2');
      expect(from.filters.any((f) => f == 'eq:type=score_submitted'), isTrue);
      expect(from.filters.any((f) => f == 'eq:match_id=m1'), isTrue);
    });

    test('ne garde que la soumission la plus récente par joueur', () async {
      // rows triés desc côté serveur → 1re occurrence d'un joueur = plus récente.
      stubFrom(client, 'match_events', [
        scoreRow(createdBy: 'p1', score1: 3, score2: 0),
        scoreRow(createdBy: 'p1', score1: 2, score2: 1),
      ]);
      final subs = await repo.fetchSubmittedScores('m1');
      expect(subs, hasLength(1));
      expect(subs['p1']!.label, '3-0');
    });

    test('formate les tirs au but', () async {
      stubFrom(client, 'match_events', [
        scoreRow(
          createdBy: 'p1',
          score1: 2,
          score2: 2,
          viaPen: true,
          pen1: 5,
          pen2: 4,
        ),
      ]);
      final subs = await repo.fetchSubmittedScores('m1');
      expect(subs['p1']!.label, '2-2 (tab 5-4)');
    });
  });

  group('watchById (Realtime)', () {
    test('liste vide → null, filtre id + primaryKey', () async {
      final probe = stubStream(
        client,
        'disputes',
        Stream.value(<Map<String, dynamic>>[]),
      );
      final first = await repo.watchById('d1').first;
      expect(first, isNull);
      expect(probe.primaryKey, ['id']);
      expect(probe.eqColumn, 'id');
      expect(probe.eqValue, 'd1');
    });

    test('row → Dispute (première ligne)', () async {
      stubStream(
        client,
        'disputes',
        Stream.value([disputeRow(id: 'd1', status: 'escalated')]),
      );
      final d = await repo.watchById('d1').first;
      expect(d!.id, 'd1');
      expect(d.isOpen, isTrue);
    });
  });

  group('resolveAtomic (RPC transactionnelle)', () {
    test('verdict : délègue à resolve_dispute avec tous les params', () async {
      when(
        () => client.rpc<void>('resolve_dispute', params: any(named: 'params')),
      ).thenAnswer((_) => FakeQueryChain<void>(Future<void>.value()));

      await repo.resolveAtomic(
        matchId: 'm1',
        disputeId: 'd1',
        justification: 'verdict',
        winnerId: 'p1',
        scoreP1: 2,
        scoreP2: 1,
      );

      verify(
        () => client.rpc<void>(
          'resolve_dispute',
          params: {
            'p_match_id': 'm1',
            'p_dispute_id': 'd1',
            'p_justification': 'verdict',
            'p_cancel': false,
            'p_winner_id': 'p1',
            'p_score1': 2,
            'p_score2': 1,
            // Trancher un litige n'accuse personne par défaut : le strike
            // (→ ban à vie au 3e) reste un choix explicite de l'admin.
            'p_guilty_party_id': null,
          },
        ),
      ).called(1);
      // Pas d'écriture directe : tout passe par la transaction serveur.
      verifyNever(() => client.from('disputes'));
    });

    test('annulation : p_cancel=true, sans winner ni score', () async {
      when(
        () => client.rpc<void>('resolve_dispute', params: any(named: 'params')),
      ).thenAnswer((_) => FakeQueryChain<void>(Future<void>.value()));

      await repo.resolveAtomic(
        matchId: 'm1',
        justification: 'match annulé',
        cancel: true,
      );

      verify(
        () => client.rpc<void>(
          'resolve_dispute',
          params: {
            'p_match_id': 'm1',
            'p_dispute_id': null,
            'p_justification': 'match annulé',
            'p_cancel': true,
            'p_winner_id': null,
            'p_score1': null,
            'p_score2': null,
            'p_guilty_party_id': null,
          },
        ),
      ).called(1);
    });

    test('verdict avec coupable : transmet p_guilty_party_id (strike)',
        () async {
      when(
        () => client.rpc<void>('resolve_dispute', params: any(named: 'params')),
      ).thenAnswer((_) => FakeQueryChain<void>(Future<void>.value()));

      // Le coupable est INDÉPENDANT du vainqueur : ici p1 gagne le tapis vert
      // et c'est p2 qui a triché — mais l'inverse doit rester exprimable.
      await repo.resolveAtomic(
        matchId: 'm1',
        disputeId: 'd1',
        justification: 'triche avérée',
        winnerId: 'p1',
        guiltyPartyId: 'p2',
      );

      verify(
        () => client.rpc<void>(
          'resolve_dispute',
          params: {
            'p_match_id': 'm1',
            'p_dispute_id': 'd1',
            'p_justification': 'triche avérée',
            'p_cancel': false,
            'p_winner_id': 'p1',
            'p_score1': null,
            'p_score2': null,
            'p_guilty_party_id': 'p2',
          },
        ),
      ).called(1);
    });
  });
}
