import 'package:fluent_ui/fluent_ui.dart';
import 'package:window_manager/window_manager.dart';

/// Boutons de fenêtre Windows (réduire / agrandir / fermer) pour l'app
/// desktop.
///
/// La barre de titre native est masquée (`TitleBarStyle.hidden` dans le
/// bootstrap) : c'est le `TitleBar` Fluent qui occupe le haut de la
/// fenêtre, et ce widget lui fournit les contrôles natifs via
/// `captionControls`. Les boutons viennent de window_manager
/// ([WindowCaptionButton]) : rendu identique aux boutons Windows 11
/// (le bouton fermer passe au rouge au survol).
class DesktopWindowCaption extends StatefulWidget {
  const DesktopWindowCaption({super.key});

  @override
  State<DesktopWindowCaption> createState() => _DesktopWindowCaptionState();
}

class _DesktopWindowCaptionState extends State<DesktopWindowCaption>
    with WindowListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  // Rafraîchit l'icône agrandir/restaurer quand l'état change (y compris
  // via double-clic sur la barre ou Win+flèches).
  @override
  void onWindowMaximize() => setState(() {});

  @override
  void onWindowUnmaximize() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        WindowCaptionButton.minimize(
          brightness: Brightness.dark,
          onPressed: windowManager.minimize,
        ),
        FutureBuilder<bool>(
          future: windowManager.isMaximized(),
          builder: (context, snapshot) {
            if (snapshot.data ?? false) {
              return WindowCaptionButton.unmaximize(
                brightness: Brightness.dark,
                onPressed: windowManager.unmaximize,
              );
            }
            return WindowCaptionButton.maximize(
              brightness: Brightness.dark,
              onPressed: windowManager.maximize,
            );
          },
        ),
        WindowCaptionButton.close(
          brightness: Brightness.dark,
          onPressed: windowManager.close,
        ),
      ],
    );
  }
}

/// Bascule agrandir ↔ restaurer (utilisée par le double-clic sur la
/// barre de titre).
Future<void> toggleMaximize() async {
  if (await windowManager.isMaximized()) {
    await windowManager.unmaximize();
  } else {
    await windowManager.maximize();
  }
}

/// Zone de drag de fenêtre pour les écrans HORS shell (login, TOTP) :
/// bande invisible en haut de l'écran qui permet de déplacer la fenêtre
/// et héberge les boutons de fenêtre à droite.
class DesktopWindowDragStrip extends StatelessWidget {
  const DesktopWindowDragStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Row(
        children: [
          // Zone draggable (tout sauf les boutons).
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: (_) => windowManager.startDragging(),
              onDoubleTap: toggleMaximize,
            ),
          ),
          const DesktopWindowCaption(),
        ],
      ),
    );
  }
}
