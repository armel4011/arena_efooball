import 'dart:io';

import 'package:arena/core/services/proof_commitment_service.dart';
import 'package:arena/core/services/proof_file_store.dart';
import 'package:arena/core/services/proof_transcoder.dart';
import 'package:arena/core/services/sync_queue_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  group('commitForMatch write-once', () {
    test('ignore un ré-enregistrement si une preuve existe déjà pour le match',
        () async {
      // Régression : un match ré-enregistré (ré-entrées dans la salle) doit
      // GARDER le 1er fichier engagé — sinon l'upload envoie un fichier dont le
      // hash ne correspond plus au commitment serveur (write-once) et
      // proof-verify le déclare « falsifié » à tort.
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = ProofFileStore(prefs);
      await store.put(
        matchId: 'm1',
        filePath: '/first/proof.mp4',
        playerId: 'p1',
      );

      final dir = await Directory.systemTemp.createTemp('commit_once');
      final second = File('${dir.path}/second.mp4')
        ..writeAsBytesSync(List<int>.filled(1024, 0x62));
      addTearDown(() => dir.delete(recursive: true));

      final spy = _SpyBackend();
      final container = ProviderContainer(
        overrides: [
          proofFileStoreProvider.overrideWithValue(store),
          proofTranscoderProvider.overrideWithValue(ProofTranscoder(spy)),
        ],
      );
      addTearDown(container.dispose);

      await container.read(proofCommitmentServiceProvider).commitForMatch(
            matchId: 'm1',
            filePath: second.path,
            playerId: 'p1',
          );

      // Court-circuit AVANT le transcodage → aucune tentative de ré-hash.
      expect(spy.calls, 0);
      // L'entrée d'origine (1er enregistrement) reste canonique.
      expect(store.get('m1')!.filePath, '/first/proof.mp4');
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

/// Backend de transcodage espion : compte les appels pour vérifier que la garde
/// write-once court-circuite AVANT toute tentative de transcodage.
class _SpyBackend implements VideoTranscoderBackend {
  int calls = 0;

  @override
  Future<String?> compressToLowRes(String inputPath) async {
    calls++;
    return null;
  }
}
