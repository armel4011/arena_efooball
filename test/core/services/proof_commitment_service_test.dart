import 'dart:io';

import 'package:arena/core/services/proof_commitment_service.dart';
import 'package:arena/core/services/sync_queue_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('sha256OfFile', () {
    test('vecteur connu "abc" → ba7816bf…', () async {
      final dir = await Directory.systemTemp.createTemp('proof_test');
      final f = File('${dir.path}/abc.bin');
      await f.writeAsString('abc');
      addTearDown(() => dir.delete(recursive: true));

      expect(
        await sha256OfFile(f),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );
    });

    test('fichier vide → hash du vide', () async {
      final dir = await Directory.systemTemp.createTemp('proof_test');
      final f = File('${dir.path}/empty.bin')..createSync();
      addTearDown(() => dir.delete(recursive: true));

      expect(
        await sha256OfFile(f),
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      );
    });

    test('hashe en flux un contenu plus gros que les chunks', () async {
      final dir = await Directory.systemTemp.createTemp('proof_test');
      final f = File('${dir.path}/big.bin');
      // 256 Ko de 'a' → un seul hash déterministe (cohérence chunked).
      await f.writeAsBytes(List<int>.filled(256 * 1024, 0x61));
      addTearDown(() => dir.delete(recursive: true));

      final h1 = await sha256OfFile(f);
      final h2 = await sha256OfFile(f);
      expect(h1, h2);
      expect(h1.length, 64);
    });
  });

  group('isTerminalCommitStatus', () {
    test('4xx hors 401 = terminal (drop)', () {
      expect(isTerminalCommitStatus(400), isTrue);
      expect(isTerminalCommitStatus(403), isTrue);
      expect(isTerminalCommitStatus(404), isTrue);
      expect(isTerminalCommitStatus(409), isTrue); // already_committed
    });

    test('401 / 5xx / null = non-terminal (retry)', () {
      expect(isTerminalCommitStatus(401), isFalse); // token périmé
      expect(isTerminalCommitStatus(500), isFalse);
      expect(isTerminalCommitStatus(503), isFalse);
      expect(isTerminalCommitStatus(null), isFalse);
      expect(isTerminalCommitStatus(200), isFalse);
    });
  });

  group('ProofCommitmentAction', () {
    test('payload + roundtrip JSON conserve les champs', () {
      final action = ProofCommitmentAction(
        id: 'a1',
        createdAt: DateTime.utc(2026, 6, 29, 22),
        matchId: 'm1',
        sha256: 'f' * 64,
        bytes: 123456,
      );

      expect(action.type, 'anticheat.commit');
      expect(action.payload, {
        'match_id': 'm1',
        'sha256': 'f' * 64,
        'bytes': 123456,
      });

      final back = SyncAction.fromJson(action.toJson());
      expect(back, isA<ProofCommitmentAction>());
      final p = back! as ProofCommitmentAction;
      expect(p.matchId, 'm1');
      expect(p.sha256, 'f' * 64);
      expect(p.bytes, 123456);
    });

    test('copyWithAttempts incrémente sans perdre les champs', () {
      final a = ProofCommitmentAction(
        id: 'a1',
        createdAt: DateTime.utc(2026),
        matchId: 'm1',
        sha256: 'a' * 64,
        bytes: 1,
      );
      final b = a.copyWithAttempts(3) as ProofCommitmentAction;
      expect(b.attempts, 3);
      expect(b.matchId, 'm1');
      expect(b.bytes, 1);
    });
  });

  group('ProofUploadAction', () {
    test('payload + roundtrip JSON conserve les champs', () {
      final action = ProofUploadAction(
        id: 'u1',
        createdAt: DateTime.utc(2026, 6, 30),
        matchId: 'm1',
        streamId: 's1',
        playerId: 'p1',
        filePath: '/cache/m1.mp4',
      );

      expect(action.type, 'anticheat.upload');
      expect(action.payload, {
        'match_id': 'm1',
        'stream_id': 's1',
        'player_id': 'p1',
        'file_path': '/cache/m1.mp4',
      });

      final back = SyncAction.fromJson(action.toJson());
      expect(back, isA<ProofUploadAction>());
      final p = back! as ProofUploadAction;
      expect(p.matchId, 'm1');
      expect(p.streamId, 's1');
      expect(p.playerId, 'p1');
      expect(p.filePath, '/cache/m1.mp4');
    });

    test('execute drop si le fichier local est absent', () async {
      final action = ProofUploadAction(
        id: 'u1',
        createdAt: DateTime.utc(2026),
        matchId: 'm1',
        streamId: 's1',
        playerId: 'p1',
        filePath: '/does/not/exist_xyz.mp4',
      );
      // Fichier absent → drop (true) sans toucher au réseau (client jamais
      // utilisé avant le check d'existence).
      expect(await action.execute(_UnusedClient()), isTrue);
    });
  });
}

/// Client jamais réellement appelé — le test du fichier absent court-circuite
/// avant tout accès réseau.
class _UnusedClient implements SupabaseClient {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('SupabaseClient ne doit pas être utilisé');
}
