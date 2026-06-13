import 'dart:convert';
import 'dart:io';

import 'package:arena/data/repositories/export_user_data_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:functions_client/functions_client.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '_supabase_mocks.dart';

class MockFunctionsClient extends Mock implements FunctionsClient {}

/// Fake path_provider qui renvoie un répertoire temporaire réel, pour que
/// `exportToFile()` puisse réellement écrire le fichier JSON sur disque.
class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProvider(this.docsPath);

  final String docsPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => docsPath;
}

void main() {
  late MockSupabaseClient client;
  late MockFunctionsClient functions;
  late ExportUserDataRepository repo;
  late Directory tmpDir;

  setUp(() {
    client = MockSupabaseClient();
    functions = MockFunctionsClient();
    when(() => client.functions).thenReturn(functions);
    repo = ExportUserDataRepository(client);

    tmpDir = Directory.systemTemp.createTempSync('arena_export_test');
    PathProviderPlatform.instance = _FakePathProvider(tmpDir.path);
  });

  tearDown(() {
    if (tmpDir.existsSync()) {
      tmpDir.deleteSync(recursive: true);
    }
  });

  void stubInvoke(Object? data, {int status = 200}) {
    when(() => functions.invoke('export-user-data')).thenAnswer(
      (_) async => FunctionResponse(data: data, status: status),
    );
  }

  group('exportToFile', () {
    test('appelle la bonne Edge Function et écrit un fichier JSON valide',
        () async {
      stubInvoke(<String, dynamic>{
        'userId': 'u1',
        'matches': <Map<String, dynamic>>[
          {'id': 'm1'},
          {'id': 'm2'},
        ],
        'payments': <Map<String, dynamic>>[
          {'id': 'p1'},
        ],
      });

      final result = await repo.exportToFile();

      verify(() => functions.invoke('export-user-data')).called(1);

      final file = File(result.filePath);
      expect(file.existsSync(), isTrue);

      // Le fichier contient bien le JSON ré-encodé.
      final decoded =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(decoded['userId'], 'u1');
      expect(decoded['matches'] as List, hasLength(2));
    });

    test('byteSize correspond à la taille réelle écrite', () async {
      stubInvoke(<String, dynamic>{
        'userId': 'u1',
        'matches': <Map<String, dynamic>>[],
      });

      final result = await repo.exportToFile();
      final file = File(result.filePath);
      expect(result.byteSize, file.lengthSync());
      expect(result.byteSize, greaterThan(0));
    });

    test('recordCounts ne compte que les sections de type liste', () async {
      stubInvoke(<String, dynamic>{
        'userId': 'u1',
        'matches': <Map<String, dynamic>>[
          {'id': 'm1'},
          {'id': 'm2'},
          {'id': 'm3'},
        ],
        'payments': <Map<String, dynamic>>[
          {'id': 'p1'},
        ],
        'friends': <Map<String, dynamic>>[],
        // Champs scalaires → ignorés par le comptage.
        'exportedAt': '2026-06-05T10:00:00.000Z',
        'profile': {'username': 'arena'},
      });

      final result = await repo.exportToFile();

      expect(result.recordCounts['matches'], 3);
      expect(result.recordCounts['payments'], 1);
      expect(result.recordCounts['friends'], 0);
      expect(result.recordCounts.containsKey('userId'), isFalse);
      expect(result.recordCounts.containsKey('exportedAt'), isFalse);
      expect(result.recordCounts.containsKey('profile'), isFalse);
    });

    test('le nom de fichier intègre le userId du payload', () async {
      stubInvoke(<String, dynamic>{
        'userId': 'abc-123',
        'matches': <Map<String, dynamic>>[],
      });

      final result = await repo.exportToFile();
      expect(result.filePath, contains('arena-data-abc-123-'));
      expect(result.filePath, endsWith('.json'));
    });

    test('userId absent → fallback "unknown" dans le nom de fichier',
        () async {
      stubInvoke(<String, dynamic>{
        'matches': <Map<String, dynamic>>[],
      });

      final result = await repo.exportToFile();
      expect(result.filePath, contains('arena-data-unknown-'));
    });

    test('réponse non-Map (ex. null) → FormatException', () async {
      stubInvoke(null);
      expect(repo.exportToFile(), throwsA(isA<FormatException>()));
    });

    test('réponse de type liste → FormatException', () async {
      stubInvoke(<dynamic>['oops']);
      expect(repo.exportToFile(), throwsA(isA<FormatException>()));
    });

    test('payload sans aucune liste → recordCounts vide', () async {
      stubInvoke(<String, dynamic>{
        'userId': 'u1',
        'exportedAt': '2026-06-05T10:00:00.000Z',
      });

      final result = await repo.exportToFile();
      expect(result.recordCounts, isEmpty);
    });
  });
}
