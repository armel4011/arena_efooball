import 'package:arena/core/theme/arena_fluent_theme.dart';
import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/features_admin_desktop/shared/desktop_window_controls.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:google_fonts/google_fonts.dart';

/// Gabarit commun des écrans d'auth desktop : fond void Arena, carte
/// Fluent centrée avec le branding ARENA ADMIN en tête.
class DesktopAuthScaffold extends StatelessWidget {
  const DesktopAuthScaffold({
    required this.title,
    required this.child,
    this.subtitle,
    super.key,
  });

  /// Titre affiché sous le logo (ex. « Connexion »).
  final String title;

  /// Sous-titre optionnel (instructions).
  final String? subtitle;

  /// Contenu du formulaire.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: ArenaColors.void_,
      child: Column(
        children: [
          // Barre de fenêtre (drag + réduire/agrandir/fermer) — la barre
          // native est masquée, ces écrans vivent hors du shell Fluent.
          const DesktopWindowDragStrip(),
          Expanded(child: _buildBody(context)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(ArenaDesktop.pagePadding),
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: ArenaDesktop.formMaxWidth),
          child: Card(
            backgroundColor: ArenaColors.carbon,
            borderRadius: BorderRadius.circular(12),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── Branding ────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'ARENA',
                      style: GoogleFonts.bebasNeue(
                        color: ArenaColors.bone,
                        fontSize: 36,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ADMIN',
                      style: GoogleFonts.bebasNeue(
                        color: ArenaColors.neonRed,
                        fontSize: 36,
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    color: ArenaColors.bone,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtitle!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceGrotesk(
                      color: ArenaColors.silver,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
