import 'package:arena/data/models/tutorial_video.dart';
import 'package:arena/data/repositories/tutorial_video_repository.dart';
import 'package:arena/features_user/home/widgets/tutorial_video_section.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

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
    int displayDays = 14,
    String targetPage = 'home',
    String createdAt = '2026-06-01T10:00:00.000Z',
  }) =>
      {
        'id': id,
        'title': title,
        'video_url': videoUrl,
        'is_active': isActive,
        'display_days': displayDays,
        'target_page': targetPage,
        'updated_by': 'super1',
        'created_at': createdAt,
        'updated_at': '2026-06-02T10:00:00.000Z',
      };

  TutorialVideo banner({
    String id = 'v1',
    bool isActive = true,
    TutorialPage page = TutorialPage.home,
    String createdAt = '2026-06-01T10:00:00.000Z',
  }) =>
      TutorialVideo.fromJson(
        videoRow(
          id: id,
          isActive: isActive,
          targetPage: page.wire,
          createdAt: createdAt,
        ),
      );

  group('createBanner', () {
    test('payload insert: title, video_url, target_page, is_active true, '
        'display_days, updated_by', () async {
      final from = stub('tutorial_video', null);
      await repo.createBanner(
        title: 'Nouveau tuto',
        videoUrl: 'https://vimeo.com/123',
        targetPage: TutorialPage.competitions,
        displayDays: 21,
        updatedBy: 'super1',
      );
      final ins = from.insertedValues! as Map<String, dynamic>;
      expect(ins['title'], 'Nouveau tuto');
      expect(ins['video_url'], 'https://vimeo.com/123');
      expect(ins['target_page'], 'competitions');
      expect(ins['is_active'], true);
      expect(ins['display_days'], 21);
      expect(ins['updated_by'], 'super1');
    });

    test('updatedBy omis → pas de clé updated_by', () async {
      final from = stub('tutorial_video', null);
      await repo.createBanner(
        title: 'Sans auteur',
        videoUrl: 'https://x.gg/v',
        targetPage: TutorialPage.all,
        displayDays: 7,
      );
      final ins = from.insertedValues! as Map<String, dynamic>;
      expect(ins.containsKey('updated_by'), isFalse);
      expect(ins['target_page'], 'all');
    });

    test('vidéo contextuelle : game/country_code écrits (jeu pour la salle)',
        () async {
      final from = stub('tutorial_video', null);
      await repo.createBanner(
        title: 'Règles eFootball',
        videoUrl: 'https://youtu.be/abc',
        targetPage: TutorialPage.matchLocked,
        displayDays: 7,
        game: 'efootball',
      );
      final ins = from.insertedValues! as Map<String, dynamic>;
      expect(ins['target_page'], 'match_locked');
      expect(ins['game'], 'efootball');
      // country_code TOUJOURS présent (NULL) pour satisfaire le CHECK DB.
      expect(ins.containsKey('country_code'), isTrue);
      expect(ins['country_code'], isNull);
    });

    test('bannière de page : game/country_code présents mais NULL', () async {
      final from = stub('tutorial_video', null);
      await repo.createBanner(
        title: 'Tuto home',
        videoUrl: 'https://youtu.be/xyz',
        targetPage: TutorialPage.home,
        displayDays: 7,
      );
      final ins = from.insertedValues! as Map<String, dynamic>;
      expect(ins['game'], isNull);
      expect(ins['country_code'], isNull);
    });
  });

  group('updateBanner', () {
    test('update tous les champs éditables + filtre id', () async {
      final from = stub('tutorial_video', null);
      await repo.updateBanner(
        id: 'v9',
        title: 'Maj',
        videoUrl: 'https://y.gg/v',
        targetPage: TutorialPage.home,
        displayDays: 30,
        isActive: false,
        updatedBy: 'super1',
      );
      final upd = from.updatedValues!;
      expect(upd['title'], 'Maj');
      expect(upd['video_url'], 'https://y.gg/v');
      expect(upd['target_page'], 'home');
      expect(upd['display_days'], 30);
      expect(upd['is_active'], false);
      expect(upd['updated_at'], isA<String>());
      expect(from.filters.any((f) => f == 'eq:id=v9'), isTrue);
    });
  });

  group('setActive', () {
    test('update is_active + updated_at, filtre id', () async {
      final from = stub('tutorial_video', null);
      await repo.setActive('v3', true);
      final upd = from.updatedValues!;
      expect(upd['is_active'], true);
      expect(upd['updated_at'], isA<String>());
      expect(from.filters.any((f) => f == 'eq:id=v3'), isTrue);
    });
  });

  group('deleteBanner', () {
    test('delete + filtre id', () async {
      final from = stub('tutorial_video', null);
      await repo.deleteBanner('v4');
      expect(from.filters.any((f) => f == 'eq:id=v4'), isTrue);
    });
  });

  group('filterActiveForPage (filtre pur)', () {
    test('bannière all apparaît pour home ET competitions', () {
      final all = banner(id: 'a', page: TutorialPage.all);
      expect(
        TutorialVideoRepository.filterActiveForPage([all], TutorialPage.home)
            .map((b) => b.id),
        ['a'],
      );
      expect(
        TutorialVideoRepository.filterActiveForPage(
          [all],
          TutorialPage.competitions,
        ).map((b) => b.id),
        ['a'],
      );
    });

    test("bannière home n'apparaît PAS pour competitions", () {
      final home = banner(id: 'h', page: TutorialPage.home);
      expect(
        TutorialVideoRepository.filterActiveForPage(
          [home],
          TutorialPage.competitions,
        ),
        isEmpty,
      );
      expect(
        TutorialVideoRepository.filterActiveForPage([home], TutorialPage.home)
            .map((b) => b.id),
        ['h'],
      );
    });

    test('les inactives sont exclues', () {
      final inactive =
          banner(id: 'x', page: TutorialPage.home, isActive: false);
      expect(
        TutorialVideoRepository.filterActiveForPage([inactive], TutorialPage.home),
        isEmpty,
      );
    });

    test('tri par created_at croissant', () {
      final older = banner(
        id: 'old',
        page: TutorialPage.home,
        createdAt: '2026-06-01T00:00:00.000Z',
      );
      final newer = banner(
        id: 'new',
        page: TutorialPage.home,
        createdAt: '2026-06-03T00:00:00.000Z',
      );
      final out = TutorialVideoRepository.filterActiveForPage(
        [newer, older],
        TutorialPage.home,
      );
      expect(out.map((b) => b.id), ['old', 'new']);
    });
  });

  group('activeContextualVideo (filtre pur)', () {
    TutorialVideo ctx({
      required String id,
      required TutorialPage page,
      String? game,
      String? country,
      bool isActive = true,
    }) {
      final row = videoRow(id: id, isActive: isActive, targetPage: page.wire);
      row['game'] = game;
      row['country_code'] = country;
      return TutorialVideo.fromJson(row);
    }

    test('salle verrouillée : match sur (cible, jeu)', () {
      final efoot = ctx(id: 'e', page: TutorialPage.matchLocked, game: 'efootball');
      final dames = ctx(id: 'd', page: TutorialPage.matchLocked, game: 'draughts');
      final out = TutorialVideoRepository.activeContextualVideo(
        [dames, efoot],
        TutorialPage.matchLocked,
        gameWire: 'efootball',
      );
      expect(out?.id, 'e');
    });

    test('jeu sans vidéo → null', () {
      final efoot = ctx(id: 'e', page: TutorialPage.matchLocked, game: 'efootball');
      final out = TutorialVideoRepository.activeContextualVideo(
        [efoot],
        TutorialPage.matchLocked,
        gameWire: 'ea_sports_fc',
      );
      expect(out, isNull);
    });

    test('inactive exclue même si jeu correspond', () {
      final efoot = ctx(
        id: 'e',
        page: TutorialPage.matchLocked,
        game: 'efootball',
        isActive: false,
      );
      final out = TutorialVideoRepository.activeContextualVideo(
        [efoot],
        TutorialPage.matchLocked,
        gameWire: 'efootball',
      );
      expect(out, isNull);
    });

    test('ne confond pas les cibles (role_intro vs match_locked)', () {
      final locked = ctx(id: 'l', page: TutorialPage.matchLocked, game: 'efootball');
      final out = TutorialVideoRepository.activeContextualVideo(
        [locked],
        TutorialPage.matchRoleIntro,
        gameWire: 'efootball',
      );
      expect(out, isNull);
    });

    test('tuto paiement : match sur (cible, pays)', () {
      final cm = ctx(id: 'cm', page: TutorialPage.paymentTutorial, country: 'CM');
      final sn = ctx(id: 'sn', page: TutorialPage.paymentTutorial, country: 'SN');
      final out = TutorialVideoRepository.activeContextualVideo(
        [cm, sn],
        TutorialPage.paymentTutorial,
        countryCode: 'SN',
      );
      expect(out?.id, 'sn');
    });
  });

  group('fromJson', () {
    test('mappe snake_case → camelCase et parse les dates', () {
      final v = TutorialVideo.fromJson(videoRow(isActive: false));
      expect(v.isActive, isFalse);
      expect(v.createdAt, isA<DateTime>());
      expect(v.updatedAt, isA<DateTime>());
    });

    test('mappe display_days et round-trip toJson', () {
      final v = TutorialVideo.fromJson(videoRow(displayDays: 30));
      expect(v.displayDays, 30);
      final json = v.toJson();
      expect(json['display_days'], 30);
      expect(TutorialVideo.fromJson(json).displayDays, 30);
    });

    test('display_days absent → défaut 7', () {
      final row = videoRow()..remove('display_days');
      expect(TutorialVideo.fromJson(row).displayDays, 7);
    });

    test('mappe target_page et round-trip toJson', () {
      final v = TutorialVideo.fromJson(videoRow(targetPage: 'competitions'));
      expect(v.targetPage, TutorialPage.competitions);
      final json = v.toJson();
      expect(json['target_page'], 'competitions');
      expect(
        TutorialVideo.fromJson(json).targetPage,
        TutorialPage.competitions,
      );
    });

    test('target_page absent → défaut home', () {
      final row = videoRow()..remove('target_page');
      expect(TutorialVideo.fromJson(row).targetPage, TutorialPage.home);
    });
  });

  group('recordAndGetFirstView (RPC)', () {
    test('rpc renvoie une String ISO → DateTime correct', () async {
      when(
        () => client.rpc<dynamic>(
          'tutorial_record_and_get_view',
          params: any(named: 'params'),
        ),
      ).thenAnswer(
        (_) => FakeQueryChain<dynamic>(
          Future<dynamic>.value('2026-06-01T10:00:00.000Z'),
        ),
      );
      final seen = await repo.recordAndGetFirstView('v1');
      expect(seen, isNotNull);
      expect(seen, DateTime.parse('2026-06-01T10:00:00.000Z'));
      verify(
        () => client.rpc<dynamic>(
          'tutorial_record_and_get_view',
          params: {'p_tutorial_id': 'v1'},
        ),
      ).called(1);
    });

    test('rpc renvoie null → null', () async {
      when(
        () => client.rpc<dynamic>(
          'tutorial_record_and_get_view',
          params: any(named: 'params'),
        ),
      ).thenAnswer((_) => FakeQueryChain<dynamic>(Future<dynamic>.value(null)));
      expect(await repo.recordAndGetFirstView('v1'), isNull);
    });
  });

  group('shouldShowTutorialBanner (fenêtre = 1re impression)', () {
    final now = DateTime(2026, 6, 6, 12);

    test('firstSeen null → masqué (fallback sûr)', () {
      expect(
        shouldShowTutorialBanner(
          firstSeen: null,
          displayDays: 7,
          now: now,
        ),
        isFalse,
      );
    });

    test('1re impression plus récente que la durée → affiché', () {
      expect(
        shouldShowTutorialBanner(
          firstSeen: now.subtract(const Duration(days: 3)),
          displayDays: 7,
          now: now,
        ),
        isTrue,
      );
    });

    test('1re impression plus ancienne que la durée → masqué', () {
      expect(
        shouldShowTutorialBanner(
          firstSeen: now.subtract(const Duration(days: 10)),
          displayDays: 7,
          now: now,
        ),
        isFalse,
      );
    });

    test('âge égal à la durée (jours entiers) → masqué (strictement <)', () {
      expect(
        shouldShowTutorialBanner(
          firstSeen: now.subtract(const Duration(days: 7)),
          displayDays: 7,
          now: now,
        ),
        isFalse,
      );
    });
  });
}
