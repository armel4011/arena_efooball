import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/features_user/competitions/game_store_links.dart';
import 'package:flutter_test/flutter_test.dart';

/// Liens store par jeu externe, affichés dans le dialogue de contrôle
/// d'installation avant inscription. Les Dames (in-app) n'en ont pas.
void main() {
  group('gameStoreUrl', () {
    test('eFootball → Play Store Konami', () {
      expect(
        gameStoreUrl(GameType.efootball),
        'https://play.google.com/store/apps/details?id=jp.konami.pesam',
      );
    });

    test('Mobile FC → Play Store EA', () {
      expect(
        gameStoreUrl(GameType.eaSportsFc),
        'https://play.google.com/store/apps/details?id=com.ea.gp.fifamobile',
      );
    });

    test('Dream League → Play Store First Touch', () {
      expect(
        gameStoreUrl(GameType.dreamLeague),
        'https://play.google.com/store/apps/details?id=com.firsttouchgames.dls8',
      );
    });

    test("Dames (in-app) → null (pas d'app externe)", () {
      expect(gameStoreUrl(GameType.draughts), isNull);
    });

    test('tout jeu EXTERNE a un lien store non vide', () {
      for (final g in GameType.values.where((g) => g.isExternal)) {
        final url = gameStoreUrl(g);
        expect(url, isNotNull, reason: '${g.value} devrait avoir un store');
        expect(url, startsWith('https://play.google.com/'));
      }
    });

    test("seul le jeu in-app (Dames) n'a pas de store", () {
      for (final g in GameType.values.where((g) => g.isInApp)) {
        expect(gameStoreUrl(g), isNull, reason: '${g.value} est in-app');
      }
    });
  });
}
