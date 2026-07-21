import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/core/utils/youtube_url.dart';
import 'package:arena/features_shared/widgets/arena_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

/// Ouvre une vidéo YouTube en PLEIN ÉCRAN (page dédiée) plutôt que dans un
/// lecteur embarqué. Une WebView pleine page se monte de façon plus fiable
/// qu'un lecteur DANS un dialogue overlay. No-op si l'URL n'est pas exploitable.
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

class _FullscreenYoutubePage extends StatelessWidget {
  const _FullscreenYoutubePage({required this.videoId});

  final String videoId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArenaColors.void_,
      appBar: const ArenaAppBar(title: 'GUIDE VIDÉO'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(ArenaSpacing.md),
          child: ArenaYoutubePlayer(videoId: videoId),
        ),
      ),
    );
  }
}

/// Ouvre la vidéo [videoId] dans l'app YouTube / le navigateur — filet de
/// sécurité fiable quand la WebView embarquée ne charge pas (réseau instable,
/// WebView MIUI/Xiaomi capricieuse…).
Future<void> _openYoutubeExternally(String videoId) async {
  final uri = Uri.parse('https://www.youtube.com/watch?v=$videoId');
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// Lecteur YouTube IN-APP, à partir d'un lien saisi par l'admin.
///
/// Rend `null` (via [maybe]) si le lien n'est pas exploitable : un admin peut
/// coller n'importe quoi, et un mauvais lien ne doit jamais casser l'écran.
///
/// Sous le lecteur, un lien **« Ouvrir dans YouTube »** est TOUJOURS proposé :
/// la WebView embarquée reste parfois noire (réseau/appareil), et ce filet
/// garantit que la vidéo est toujours regardable.
///
/// ⚠️ Repose sur une WebView, donc **Android/iOS/Web uniquement**. La console
/// admin desktop (Windows) ne LIT jamais de vidéo — le paquet y compile.
class ArenaYoutubePlayer extends StatefulWidget {
  const ArenaYoutubePlayer({required this.videoId, super.key});

  /// Identifiant déjà extrait — cf. [ArenaYoutubePlayer.maybe] pour partir
  /// d'une URL brute.
  final String videoId;

  /// Construit le lecteur depuis une URL admin, ou `null` si elle n'est pas
  /// exploitable. Point d'entrée qui absorbe les liens douteux.
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
      // Pas d'autoplay : un son surprise (salle de match / paiement) serait
      // hostile. Coupe les annotations/suggestions de fin.
      showFullscreenButton: true,
      showVideoAnnotations: false,
      enableCaption: false,
    ),
  )..loadVideoById(videoId: widget.videoId);

  @override
  void didUpdateWidget(ArenaYoutubePlayer old) {
    super.didUpdateWidget(old);
    // L'admin peut changer le lien (realtime) : recharger plutôt que recréer le
    // contrôleur (qui relancerait la WebView).
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(ArenaRadius.lg),
          child: ColoredBox(
            color: ArenaColors.void_,
            child: YoutubePlayer(
              controller: _controller,
              aspectRatio: 16 / 9,
            ),
          ),
        ),
        const SizedBox(height: ArenaSpacing.xs),
        // Filet de sécurité : si la WebView reste noire, ce bouton ouvre
        // toujours la vidéo dans YouTube.
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => _openYoutubeExternally(widget.videoId),
            icon: const Icon(Icons.open_in_new, size: 15),
            label: const Text('Ouvrir dans YouTube'),
            style: TextButton.styleFrom(
              foregroundColor: ArenaColors.signalBlue,
              visualDensity: VisualDensity.compact,
              textStyle: ArenaText.small,
            ),
          ),
        ),
      ],
    );
  }
}
