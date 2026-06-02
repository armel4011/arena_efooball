import 'package:arena/core/theme/arena_theme.dart';
import 'package:fluent_ui/fluent_ui.dart';

/// Page temporaire pour les écrans desktop pas encore portés.
///
/// Chaque vague du chantier desktop remplace progressivement ces
/// placeholders par de vrais écrans Fluent. Le [waveLabel] indique à
/// quelle vague l'écran est prévu.
class DesktopPlaceholderPage extends StatelessWidget {
  const DesktopPlaceholderPage({
    required this.title,
    required this.waveLabel,
    super.key,
  });

  /// Titre de l'écran (ex. « Modération des streams »).
  final String title;

  /// Vague de livraison prévue (ex. « Vague 5 »).
  final String waveLabel;

  @override
  Widget build(BuildContext context) {
    final typography = FluentTheme.of(context).typography;
    return ScaffoldPage(
      header: PageHeader(title: Text(title.toUpperCase())),
      content: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              FluentIcons.processing,
              size: 56,
              color: ArenaColors.silver,
            ),
            const SizedBox(height: 16),
            Text('Bientôt disponible sur desktop', style: typography.subtitle),
            const SizedBox(height: 8),
            Text(
              'Cet écran arrive dans la $waveLabel du chantier Windows.\n'
              "En attendant, il reste accessible depuis l'app mobile ARENA "
              'Admin.',
              textAlign: TextAlign.center,
              style: typography.body?.copyWith(color: ArenaColors.silver),
            ),
          ],
        ),
      ),
    );
  }
}
