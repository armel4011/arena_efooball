import 'dart:io';

import 'package:arena/core/services/proof_archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Fake path_provider renvoyant un dossier temporaire réel comme stockage
/// applicatif — ProofArchive écrit/purge réellement sur disque.
class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProvider(this.supportPath);

  final String supportPath;

  @override
  Future<String?> getApplicationSupportPath() async => supportPath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;
  late Directory archiveDir;
  const archive = ProofArchive();

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('arena_proof_archive_test');
    PathProviderPlatform.instance = _FakePathProvider(tmp.path);
    archiveDir = Directory('${tmp.path}/arena_proofs');
  });

  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  File makeSource(String name, String content) {
    final f = File('${tmp.path}/$name')..writeAsStringSync(content);
    return f;
  }

  group('persist', () {
    test('copie la source dans le dossier persistant, octets préservés',
        () async {
      final src = makeSource('cap.mp4', 'VIDEO-BYTES');
      final dest = await archive.persist(matchId: 'm1', sourcePath: src.path);
      expect(dest, '${archiveDir.path}/proof_m1.mp4');
      expect(File(dest!).existsSync(), isTrue);
      expect(File(dest).readAsStringSync(), 'VIDEO-BYTES');
      // Copie (pas déplacement) : la source d'origine reste (galerie/replay).
      expect(src.existsSync(), isTrue);
    });

    test('source absente → null (garde-fou fallback appelant)', () async {
      final dest = await archive.persist(
        matchId: 'm1',
        sourcePath: '${tmp.path}/nope.mp4',
      );
      expect(dest, isNull);
    });

    test("source déjà dans l'archive → renvoie le chemin sans recopier",
        () async {
      final src = makeSource('cap.mp4', 'X');
      final first = await archive.persist(matchId: 'm2', sourcePath: src.path);
      // Rejeu du commit avec le chemin durable comme source.
      final second =
          await archive.persist(matchId: 'm2', sourcePath: first!);
      expect(second, first);
      expect(File(first).existsSync(), isTrue);
    });
  });

  group('purgeExpired', () {
    test('supprime les preuves > 30j, garde les récentes', () async {
      final old = await archive.persist(
        matchId: 'old',
        sourcePath: makeSource('old.mp4', 'A').path,
      );
      final fresh = await archive.persist(
        matchId: 'fresh',
        sourcePath: makeSource('fresh.mp4', 'B').path,
      );
      // Vieillit artificiellement le fichier « old » au-delà de la rétention.
      File(old!).setLastModifiedSync(
        DateTime.now().subtract(const Duration(days: 40)),
      );

      await archive.purgeExpired();

      expect(File(old).existsSync(), isFalse);
      expect(File(fresh!).existsSync(), isTrue);
    });

    test('dossier absent → ne lève pas', () async {
      expect(archive.purgeExpired(), completes);
    });
  });
}
