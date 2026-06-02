import 'package:arena/core/theme/arena_theme.dart';
import 'package:arena/data/models/competition_enums.dart';
import 'package:arena/data/models/match_status.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:google_fonts/google_fonts.dart';

/// Visuel d'un statut de compétition pour les écrans desktop : libellé
/// court + couleur d'accent. Mutualisé entre la liste, le détail et le
/// header pour garder une seule source de vérité.
class DesktopStatusVisual {
  const DesktopStatusVisual({required this.label, required this.color});

  final String label;
  final Color color;
}

/// Couleur + libellé pour un [CompetitionStatus].
DesktopStatusVisual competitionStatusVisual(CompetitionStatus status) {
  switch (status) {
    case CompetitionStatus.ongoing:
      return const DesktopStatusVisual(
        label: 'LIVE',
        color: ArenaColors.neonRed,
      );
    case CompetitionStatus.registrationOpen:
      return const DesktopStatusVisual(
        label: 'À VENIR',
        color: ArenaColors.signalBlue,
      );
    case CompetitionStatus.registrationClosed:
      return const DesktopStatusVisual(
        label: 'COMPLET',
        color: ArenaColors.statusWarn,
      );
    case CompetitionStatus.draft:
      return const DesktopStatusVisual(
        label: 'BROUILLON',
        color: ArenaColors.statusWarn,
      );
    case CompetitionStatus.completed:
      return const DesktopStatusVisual(
        label: 'TERMINÉ',
        color: ArenaColors.silver,
      );
    case CompetitionStatus.cancelled:
      return const DesktopStatusVisual(
        label: 'ANNULÉ',
        color: ArenaColors.neonRed,
      );
  }
}

/// Couleur + libellé pour un [MatchStatus].
DesktopStatusVisual matchStatusVisual(MatchStatus status) {
  switch (status) {
    case MatchStatus.inProgress:
    case MatchStatus.scorePending:
      return const DesktopStatusVisual(
        label: 'EN COURS',
        color: ArenaColors.neonRed,
      );
    case MatchStatus.completed:
      return const DesktopStatusVisual(
        label: 'VALIDÉ',
        color: ArenaColors.statusOk,
      );
    case MatchStatus.disputed:
      return const DesktopStatusVisual(
        label: 'LITIGE',
        color: ArenaColors.statusWarn,
      );
    case MatchStatus.cancelled:
    case MatchStatus.forfeited:
      return const DesktopStatusVisual(
        label: 'ANNULÉ',
        color: ArenaColors.silver,
      );
    case MatchStatus.awaitingValidation:
      return const DesktopStatusVisual(
        label: 'VALIDATION',
        color: ArenaColors.statusWarn,
      );
    case MatchStatus.pending:
    case MatchStatus.scheduled:
    case MatchStatus.ready:
      return const DesktopStatusVisual(
        label: 'EN ATTENTE',
        color: ArenaColors.silver,
      );
  }
}

/// Libellé humain d'un [TournamentFormat].
String competitionFormatLabel(TournamentFormat format) {
  switch (format) {
    case TournamentFormat.singleElimination:
      return 'Élimination directe';
    case TournamentFormat.groupsThenKnockout:
      return 'Poules puis KO';
    case TournamentFormat.roundRobin:
      return 'Round robin';
  }
}

/// Petit badge coloré (pastille + libellé) réutilisé dans les tableaux
/// desktop pour signaler le statut d'une ligne.
class DesktopStatusBadge extends StatelessWidget {
  const DesktopStatusBadge({required this.visual, super.key});

  final DesktopStatusVisual visual;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: visual.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: visual.color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: visual.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            visual.label,
            style: GoogleFonts.spaceGrotesk(
              color: visual.color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
