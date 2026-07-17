/// Extraction de l'identifiant d'une vidéo YouTube depuis une URL.
///
/// Les liens sont saisis à la main par l'admin : on ne peut pas supposer une
/// forme canonique. Les 4 formes rencontrées en pratique — partage mobile
/// (`youtu.be`), copier-coller navigateur (`watch?v=`), Shorts, et embed —
/// mènent toutes au même identifiant.
library;

/// Identifiant YouTube : 11 caractères, alphanumériques + `-` et `_`.
final _idPattern = RegExp(r'^[A-Za-z0-9_-]{11}$');

/// Rend l'identifiant de la vidéo pointée par [url], ou `null` si l'URL n'est
/// pas un lien YouTube exploitable.
///
/// Renvoyer `null` plutôt que de lever : un lien mal saisi par l'admin ne doit
/// pas faire planter l'écran d'un joueur — le caller masque le lecteur.
///
/// Formes reconnues :
///  * `https://youtu.be/<id>`
///  * `https://www.youtube.com/watch?v=<id>` (paramètres additionnels tolérés)
///  * `https://www.youtube.com/shorts/<id>`
///  * `https://www.youtube.com/embed/<id>`
///  * l'identifiant nu (`<id>`), pour un admin qui colle juste l'ID
String? youtubeVideoId(String? url) {
  final raw = url?.trim() ?? '';
  if (raw.isEmpty) return null;

  // Identifiant collé nu.
  if (_idPattern.hasMatch(raw)) return raw;

  final uri = Uri.tryParse(raw);
  if (uri == null || !uri.hasAuthority) return null;

  final host = uri.host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
  final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();

  // youtu.be/<id> — le lien de partage mobile, le plus courant.
  if (host == 'youtu.be') {
    return segments.isEmpty ? null : _validated(segments.first);
  }

  if (host != 'youtube.com' && host != 'm.youtube.com' &&
      host != 'music.youtube.com') {
    return null;
  }

  // watch?v=<id> — le copier-coller navigateur, souvent avec &t=, &list=…
  final v = uri.queryParameters['v'];
  if (v != null) return _validated(v);

  // shorts/<id> et embed/<id>.
  if (segments.length >= 2 &&
      (segments.first == 'shorts' || segments.first == 'embed')) {
    return _validated(segments[1]);
  }

  return null;
}

/// `true` si [url] mène à une vidéo YouTube exploitable — pour valider la
/// saisie admin AVANT d'enregistrer un lien que les joueurs ne pourraient pas
/// lire.
bool isPlayableYoutubeUrl(String? url) => youtubeVideoId(url) != null;

String? _validated(String candidate) =>
    _idPattern.hasMatch(candidate) ? candidate : null;
