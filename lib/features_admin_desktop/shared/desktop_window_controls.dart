import 'package:arena/core/theme/arena_theme.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:window_manager/window_manager.dart';

/// Boutons de fenêtre Windows (réduire / agrandir / fermer) pour l'app
/// desktop.
///
/// La barre de titre native est masquée (`TitleBarStyle.hidden` dans le
/// bootstrap) : c'est le `TitleBar` Fluent (shell) ou le
/// [DesktopWindowDragStrip] (écrans d'auth) qui fournit ces contrôles.
///
/// Implémentation 100 % Fluent (icônes `FluentIcons.chrome_*`) — on
/// n'utilise PAS `WindowCaptionButton` de window_manager : ses icônes
/// sont des images de package non déclarées comme assets dans son
/// pubspec, donc invisibles à l'exécution.
class DesktopWindowCaption extends StatefulWidget {
  const DesktopWindowCaption({super.key});

  @override
  State<DesktopWindowCaption> createState() => _DesktopWindowCaptionState();
}

class _DesktopWindowCaptionState extends State<DesktopWindowCaption>
    with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _syncMaximized();
  }

  Future<void> _syncMaximized() async {
    final maximized = await windowManager.isMaximized();
    if (mounted && maximized != _isMaximized) {
      setState(() => _isMaximized = maximized);
    }
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  // Suit l'état agrandi/restauré (y compris via Win+flèches ou double-clic).
  @override
  void onWindowMaximize() => setState(() => _isMaximized = true);

  @override
  void onWindowUnmaximize() => setState(() => _isMaximized = false);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CaptionButton(
          icon: FluentIcons.chrome_minimize,
          tooltip: 'Réduire',
          onPressed: windowManager.minimize,
        ),
        _CaptionButton(
          icon: _isMaximized
              ? FluentIcons.chrome_restore
              : FluentIcons.square_shape,
          tooltip: _isMaximized ? 'Restaurer' : 'Agrandir',
          onPressed: toggleMaximize,
        ),
        _CaptionButton(
          icon: FluentIcons.chrome_close,
          tooltip: 'Fermer',
          isClose: true,
          onPressed: windowManager.close,
        ),
      ],
    );
  }
}

/// Bouton de barre de titre style Windows 11 : 46 px de large, fond
/// transparent, surbrillance au survol (rouge Arena pour Fermer).
class _CaptionButton extends StatelessWidget {
  const _CaptionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isClose = false,
  });

  final IconData icon;
  final String tooltip;
  final Future<void> Function() onPressed;
  final bool isClose;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: HoverButton(
        onPressed: onPressed,
        builder: (context, states) {
          final hovered = states.isHovered || states.isPressed;
          final background = !hovered
              ? null
              : isClose
                  ? ArenaColors.neonRed
                  : ArenaColors.borderHi;
          return Container(
            width: 46,
            color: background,
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 10,
              color: ArenaColors.bone,
            ),
          );
        },
      ),
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
/// bande en haut de l'écran qui permet de déplacer la fenêtre et héberge
/// les boutons de fenêtre à droite.
class DesktopWindowDragStrip extends StatelessWidget {
  const DesktopWindowDragStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
