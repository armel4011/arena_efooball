import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/utils/youtube_url.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

/// Ouvre une vidéo YouTube en PLEIN ÉCRAN (page dédiée) plutôt que dans un
/// lecteur embarqué. Une WebView pleine page se monte de façon fiable, alors
/// qu'un lecteur DANS un dialogue overlay (surtout affiché pendant une
/// transition de route) reste noir/vide de façon intermittente sur Android.
/// No-op si l'URL n'est pas exploitable.
Future<void> openFullscreenYoutube(BuildContext context, String? url) async {
  final id = youtubeVideoId(url);
  if (id == null) return;
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => _FullscreenYoutubePage(videoId: id),
    ),
  );
}

class _FullscreenYoutubePage extends StatefulWidget {
  const _FullscreenYoutubePage({required this.videoId});

  final String videoId;

  @override
  State<_FullscreenYoutubePage> createState() => _FullscreenYoutubePageState();
}

class _FullscreenYoutubePageState extends State<_FullscreenYoutubePage> {
  late final YoutubePlayerController _controller = YoutubePlayerController(
    params: const YoutubePlayerParams(
      showFullscreenButton: true,
      showVideoAnnotations: false,
      enableCaption: false,
    ),
  )..loadVideoById(videoId: widget.videoId);

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArenaColors.void_,
      appBar: const ArenaAppBar(title: 'GUIDE VIDÉO'),
      body: Center(
        child: YoutubePlayer(
          controller: _controller,
          aspectRatio: 16 / 9,
        ),
      ),
    );
  }
}

/// Lecteur YouTube IN-APP, à partir d'un lien saisi par l'admin.
///
/// Le joueur reste dans ARENA : jusqu'ici toutes les vidéos partaient dans
/// l'app YouTube via `url_launcher`, ce qui sort l'utilisateur de son parcours —
/// inacceptable quand la vidéo explique une règle ou un paiement en cours.
///
/// Rend `null` (SizedBox.shrink via [maybe]) si le lien n'est pas exploitable :
/// un admin peut coller n'importe quoi, et un mauvais lien ne doit jamais
/// casser l'écran d'un joueur — il disparaît, simplement.
///
/// ⚠️ Repose sur une WebView, donc **Android/iOS/Web uniquement**. La console
/// admin desktop (Windows) ne LIT jamais de vidéo — elle ne fait que saisir des
/// liens — mais le paquet y compile (vérifié : build Windows OK).
class ArenaYoutubePlayer extends StatefulWidget {
  const ArenaYoutubePlayer({required this.videoId, super.key});

  /// Identifiant déjà extrait — cf. [ArenaYoutubePlayer.maybe] pour partir
  /// d'une URL brute.
  final String videoId;

  /// Construit le lecteur depuis une URL admin, ou `null` si elle n'est pas
  /// exploitable. À utiliser partout : c'est le point d'entrée qui absorbe les
  /// liens douteux.
  static Widget? maybe(String? url, {Key? key}) {
    final id = youtubeVideoId(url);
    if (id == null) return null;
    return ArenaYoutubePlayer(videoId: id, key: key);
  }

  @override
  State<ArenaYoutubePlayer> createState() => _ArenaYoutubePlayerState();
}

class _ArenaYoutubePlayerState extends State<ArenaYoutubePlayer> {
  late final YoutubePlayerController _controller = YoutubePlayerController(
    params: const YoutubePlayerParams(
      // Pas d'autoplay : la vidéo se déclenche sur une salle de match ou une
      // page de paiement, où un son surprise serait hostile.
      showFullscreenButton: true,
      // Coupe les suggestions de fin : on ne renvoie pas le joueur vers
      // YouTube au milieu de son inscription.
      showVideoAnnotations: false,
      enableCaption: false,
    ),
  )..loadVideoById(videoId: widget.videoId);

  @override
  void didUpdateWidget(ArenaYoutubePlayer old) {
    super.didUpdateWidget(old);
    // L'admin peut changer le lien en cours de route (realtime) : recharger
    // plutôt que de recréer le contrôleur (qui relancerait la WebView).
    if (old.videoId != widget.videoId) {
      _controller.loadVideoById(videoId: widget.videoId);
    }
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(ArenaRadius.lg),
      child: ColoredBox(
        color: ArenaColors.void_,
        child: YoutubePlayer(
          controller: _controller,
          aspectRatio: 16 / 9,
        ),
      ),
    );
  }
}
