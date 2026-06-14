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
    Map<String, dynamic> eventRow({
      String? proofPath = 'm1/p1/1.png',
      String? proofMime = 'image/png',
      String createdBy = 'p1',
    }) =>
        {
          'proof_path': proofPath,
          'proof_mime': proofMime,
          'created_by': createdBy,
          'created_at': '2026-06-14T10:00:00Z',
        };

    test('interroge match_events, filtre proof_path non null pour le match',
        () async {
      final from = stubFrom(client, 'match_events', [eventRow()]);
      final proofs = await repo.fetchProofs('m1');
      expect(proofs, hasLength(1));
      expect(from.selectedColumns, contains('proof_path'));
      expect(from.hasFilter('eq', 'match_id'), isTrue);
      expect(from.filters.any((f) => f == 'eq:match_id=m1'), isTrue);
      // .not('proof_path', 'is', null) → filtre 'not'
      expect(from.filters.any((f) => f.startsWith('not:proof_path=')), isTrue);
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

    test('ignore les lignes sans proof_path exploitable', () async {
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

  group('resolve', () {
    test('update status/resolution + resolved_at/by, cible le litige',
        () async {
      final from = stub('disputes', null);
      await repo.resolve(
        disputeId: 'd1',
        adminId: 'a1',
        resolution: 'P1 a triché',
      );
      final v = from.updatedValues!;
      expect(v['status'], 'resolved');
      expect(v['resolved_by'], 'a1');
      expect(v['resolution'], 'P1 a triché');
      expect(from.filters.any((f) => f == 'eq:id=d1'), isTrue);
    });

    test('status custom (cancelled)', () async {
      final from = stub('disputes', null);
      await repo.resolve(
        disputeId: 'd1',
        adminId: 'a1',
        resolution: 'x',
        status: 'cancelled',
      );
      expect(from.updatedValues!['status'], 'cancelled');
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
          },
        ),
      ).called(1);
    });
  });
}
