import 'package:arena/features_shared/widgets/arena_youtube_player.dart';
import 'package:flutter_test/flutter_test.dart';

/// `ArenaYoutubePlayer.maybe` est le point d'entrée qui absorbe les liens
/// douteux saisis par l'admin : il ne doit JAMAIS casser l'écran d'un joueur —
/// un mauvais lien rend `null` (le lecteur disparaît), un bon lien rend le
/// lecteur avec l'identifiant extrait.
///
/// On teste uniquement la construction (retour de `maybe`) : le contrôleur
/// WebView n'est créé qu'au `build` du State, donc aucun canal plateforme
/// n'est touché ici.
void main() {
  group('ArenaYoutubePlayer.maybe', () {
    test('url null → null', () {
      expect(ArenaYoutubePlayer.maybe(null), isNull);
    });

    test('url vide → null', () {
      expect(ArenaYoutubePlayer.maybe(''), isNull);
    });

    test('texte quelconque (pas un lien) → null, pas de crash', () {
      expect(ArenaYoutubePlayer.maybe('coucou les amis'), isNull);
    });

    test('lien non-YouTube → null', () {
      expect(ArenaYoutubePlayer.maybe('https://vimeo.com/123456'), isNull);
    });

    test('youtu.be/<id> valide → lecteur avec le bon videoId', () {
      final w = ArenaYoutubePlayer.maybe('https://youtu.be/dQw4w9WgXcQ');
      expect(w, isA<ArenaYoutubePlayer>());
      expect((w! as ArenaYoutubePlayer).videoId, 'dQw4w9WgXcQ');
    });

    test('watch?v=<id> (copier-coller navigateur) → lecteur', () {
      final w = ArenaYoutubePlayer.maybe(
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=42s',
      );
      expect(w, isA<ArenaYoutubePlayer>());
      expect((w! as ArenaYoutubePlayer).videoId, 'dQw4w9WgXcQ');
    });

    test('shorts/<id> → lecteur', () {
      final w = ArenaYoutubePlayer.maybe(
        'https://www.youtube.com/shorts/dQw4w9WgXcQ',
      );
      expect(w, isA<ArenaYoutubePlayer>());
      expect((w! as ArenaYoutubePlayer).videoId, 'dQw4w9WgXcQ');
    });
  });
}
