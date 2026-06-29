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
}
