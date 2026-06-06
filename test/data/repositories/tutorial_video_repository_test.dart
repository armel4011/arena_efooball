import 'package:arena/data/models/tutorial_video.dart';
import 'package:arena/data/repositories/tutorial_video_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '_supabase_mocks.dart';

void main() {
  late MockSupabaseClient client;
  late TutorialVideoRepository repo;

  setUp(() {
    client = MockSupabaseClient();
    repo = TutorialVideoRepository(client);
  });

  QueryProbe stub(String table, Object? result) =>
      stubFrom(client, table, result);

  Map<String, dynamic> videoRow({
    String id = 'v1',
    String title = 'Prise en main',
    String videoUrl = 'https://youtu.be/abc',
    bool isActive = true,
  }) =>
      {
        'id': id,
        'title': title,
        'video_url': videoUrl,
        'is_active': isActive,
        'updated_by': 'super1',
        'created_at': '2026-06-01T10:00:00.000Z',
        'updated_at': '2026-06-02T10:00:00.000Z',
      };

  group('getCurrent', () {
    test('order updated_at desc + limit 1 + parse la vidéo', () async {
      final from = stub('tutorial_video', [videoRow()]);
      final video = await repo.getCurrent();
      expect(video, isNotNull);
      expect(video!.id, 'v1');
      expect(video.title, 'Prise en main');
      expect(video.videoUrl, 'https://youtu.be/abc');
      expect(video.isActive, isTrue);
      expect(video.updatedBy, 'super1');
      expect(from.hasFilter('order', 'updated_at'), isTrue);
      expect(from.filters.any((f) => f == 'order:updated_at=false'), isTrue);
      expect(from.filters.any((f) => f == 'limit:_=1'), isTrue);
    });

    test('liste vide → null', () async {
      stub('tutorial_video', <Map<String, dynamic>>[]);
      expect(await repo.getCurrent(), isNull);
    });
  });

  group('saveActive', () {
    test('payload insert: title, video_url, is_active true, updated_by inclus',
        () async {
      final from = stub('tutorial_video', null);
      await repo.saveActive(
        title: 'Nouveau tuto',
        videoUrl: 'https://vimeo.com/123',
        updatedBy: 'super1',
      );
      // stubFrom renvoie le même builder pour les 2 appels : le dernier
      // (insert) écrase le probe → insertedValues contient le payload insert,
      // updatedValues contient le payload update.
      final ins = from.insertedValues! as Map<String, dynamic>;
      expect(ins['title'], 'Nouveau tuto');
      expect(ins['video_url'], 'https://vimeo.com/123');
      expect(ins['is_active'], true);
      expect(ins['updated_by'], 'super1');

      final upd = from.updatedValues!;
      expect(upd['is_active'], false);
      expect(upd['updated_at'], isA<String>());
      expect(from.filters.any((f) => f == 'eq:is_active=true'), isTrue);
    });

    test('updatedBy omis → pas de clé updated_by dans le payload insert',
        () async {
      final from = stub('tutorial_video', null);
      await repo.saveActive(
        title: 'Sans auteur',
        videoUrl: 'https://x.gg/v',
      );
      final ins = from.insertedValues! as Map<String, dynamic>;
      expect(ins.containsKey('updated_by'), isFalse);
      expect(ins['title'], 'Sans auteur');
    });
  });

  group('deactivate', () {
    test('update is_active=false + updated_at, filtre is_active=true', () async {
      final from = stub('tutorial_video', null);
      await repo.deactivate();
      final upd = from.updatedValues!;
      expect(upd['is_active'], false);
      expect(upd['updated_at'], isA<String>());
      expect(from.filters.any((f) => f == 'eq:is_active=true'), isTrue);
    });
  });

  group('fromJson', () {
    test('mappe snake_case → camelCase et parse les dates', () {
      final v = TutorialVideo.fromJson(videoRow(isActive: false));
      expect(v.isActive, isFalse);
      expect(v.createdAt, isA<DateTime>());
      expect(v.updatedAt, isA<DateTime>());
    });
  });
}
