import 'dart:convert';

import 'package:arena/core/services/proof_file_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProofFileStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = ProofFileStore(await SharedPreferences.getInstance());
  });

  test('get retourne null pour un match inconnu', () {
    expect(store.get('absent'), isNull);
  });

  test('put puis get conserve chemin + joueur', () async {
    await store.put(matchId: 'm1', filePath: '/c/m1.mp4', playerId: 'p1');
    final e = store.get('m1');
    expect(e, isNotNull);
    expect(e!.filePath, '/c/m1.mp4');
    expect(e.playerId, 'p1');
  });

  test("put écrase l'entrée existante du même match", () async {
    await store.put(matchId: 'm1', filePath: '/c/a.mp4', playerId: 'p1');
    await store.put(matchId: 'm1', filePath: '/c/b.mp4', playerId: 'p1');
    expect(store.get('m1')!.filePath, '/c/b.mp4');
  });

  test('plusieurs matches coexistent', () async {
    await store.put(matchId: 'm1', filePath: '/c/m1.mp4', playerId: 'p1');
    await store.put(matchId: 'm2', filePath: '/c/m2.mp4', playerId: 'p1');
    expect(store.get('m1')!.filePath, '/c/m1.mp4');
    expect(store.get('m2')!.filePath, '/c/m2.mp4');
  });

  test("remove supprime l'entrée", () async {
    await store.put(matchId: 'm1', filePath: '/c/m1.mp4', playerId: 'p1');
    await store.remove('m1');
    expect(store.get('m1'), isNull);
  });

  test('put estampille une date (ts)', () async {
    await store.put(matchId: 'm1', filePath: '/c/m1.mp4', playerId: 'p1');
    final prefs = await SharedPreferences.getInstance();
    final map = jsonDecode(prefs.getString('arena.proof_files.v1')!) as Map;
    expect((map['m1'] as Map)['ts'], isA<int>());
  });

  group('purgeOlderThan', () {
    /// Réécrit le store brut pour injecter des dates contrôlées.
    Future<void> seed(Map<String, Map<String, Object?>> raw) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('arena.proof_files.v1', jsonEncode(raw));
    }

    int daysAgoMs(int d) => DateTime.now()
        .toUtc()
        .subtract(Duration(days: d))
        .millisecondsSinceEpoch;

    test('retire les entrées périmées, garde les récentes', () async {
      await seed({
        'old': {'path': '/c/old.mp4', 'player': 'p1', 'ts': daysAgoMs(40)},
        'fresh': {'path': '/c/fresh.mp4', 'player': 'p1', 'ts': daysAgoMs(2)},
      });
      final removed = await store.purgeOlderThan(const Duration(days: 30));
      expect(removed, 1);
      expect(store.get('old'), isNull);
      expect(store.get('fresh'), isNotNull);
    });

    test('conserve les entrées legacy sans ts', () async {
      await seed({
        'legacy': {'path': '/c/legacy.mp4', 'player': 'p1'},
      });
      final removed = await store.purgeOlderThan(const Duration(days: 30));
      expect(removed, 0);
      expect(store.get('legacy'), isNotNull);
    });

    test('store vide → 0', () async {
      expect(await store.purgeOlderThan(const Duration(days: 30)), 0);
    });
  });
}
