import 'package:arena/core/utils/youtube_url.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const id = 'dQw4w9WgXcQ'; // 11 caractères, forme réelle d'un ID YouTube.

  group("youtubeVideoId — formes que l'admin colle vraiment", () {
    test('youtu.be/<id> (partage mobile)', () {
      expect(youtubeVideoId('https://youtu.be/$id'), id);
      expect(youtubeVideoId('http://youtu.be/$id'), id);
    });

    test('watch?v=<id> (copier-coller navigateur)', () {
      expect(youtubeVideoId('https://www.youtube.com/watch?v=$id'), id);
      expect(youtubeVideoId('https://youtube.com/watch?v=$id'), id);
      expect(youtubeVideoId('https://m.youtube.com/watch?v=$id'), id);
    });

    test('paramètres additionnels tolérés (&t=, &list=…)', () {
      expect(youtubeVideoId('https://www.youtube.com/watch?v=$id&t=42s'), id);
      expect(
        youtubeVideoId('https://www.youtube.com/watch?v=$id&list=PL123&index=2'),
        id,
      );
    });

    test('shorts/<id> et embed/<id>', () {
      expect(youtubeVideoId('https://www.youtube.com/shorts/$id'), id);
      expect(youtubeVideoId('https://www.youtube.com/embed/$id'), id);
    });

    test('identifiant collé nu', () {
      expect(youtubeVideoId(id), id);
    });

    test('espaces autour du lien (copier-coller humain)', () {
      expect(youtubeVideoId('  https://youtu.be/$id  '), id);
    });
  });

  group('youtubeVideoId — refus', () {
    test('null / vide → null', () {
      expect(youtubeVideoId(null), isNull);
      expect(youtubeVideoId(''), isNull);
      expect(youtubeVideoId('   '), isNull);
    });

    test('autre domaine → null', () {
      expect(youtubeVideoId('https://vimeo.com/123456'), isNull);
      expect(youtubeVideoId('https://example.com/watch?v=$id'), isNull);
    });

    test('lien YouTube SANS vidéo → null', () {
      // Le placeholder en dur de la page de paiement était exactement ça :
      // une URL de RECHERCHE, pas une vidéo — donc rien à lire in-app.
      expect(
        youtubeVideoId(
          'https://www.youtube.com/results?search_query=arena+paiement',
        ),
        isNull,
      );
      expect(youtubeVideoId('https://www.youtube.com/'), isNull);
    });

    test('identifiant de longueur invalide → null', () {
      expect(youtubeVideoId('https://youtu.be/tropcourt'), isNull);
      expect(youtubeVideoId('https://youtu.be/${id}TROPLONG'), isNull);
    });

    test('texte quelconque → null (pas de crash)', () {
      expect(youtubeVideoId('bonjour'), isNull);
      expect(youtubeVideoId('http://'), isNull);
    });
  });

  group('isPlayableYoutubeUrl', () {
    test('valide la saisie admin avant enregistrement', () {
      expect(isPlayableYoutubeUrl('https://youtu.be/$id'), isTrue);
      expect(isPlayableYoutubeUrl('https://vimeo.com/123'), isFalse);
      expect(isPlayableYoutubeUrl(null), isFalse);
    });
  });
}
