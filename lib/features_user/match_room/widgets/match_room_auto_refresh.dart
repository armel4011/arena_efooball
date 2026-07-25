import 'package:arena/data/repositories/match_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Filet de secours à la fiabilité du Realtime dans la salle de match.
///
/// Le déroulé du match dépend d'événements Realtime Supabase (statut du match,
/// code de salle, soumissions de score). S'ils ne sont pas délivrés (canaux
/// saturés, WebSocket rétabli après une bascule réseau, app mise en veille par
/// l'OEM pendant qu'on est dans le jeu externe…), l'étape affichée restait
/// FIGÉE et il fallait quitter la page puis y revenir pour « débloquer » le
/// processus.
///
/// Ce widget INVISIBLE force un re-fetch du match (et des soumissions de score)
/// à chaque **retour au premier plan** — exactement le geste du joueur qui sort
/// d'eFootball pour revenir sur ARENA. `invalidate` re-souscrit le stream
/// `autoDispose`, donc récupère l'état serveur à jour ; le cache disque évite
/// tout spinner pendant le rechargement.
class MatchRoomAutoRefresh extends ConsumerStatefulWidget {
  const MatchRoomAutoRefresh({required this.matchId, super.key});

  final String matchId;

  @override
  ConsumerState<MatchRoomAutoRefresh> createState() =>
      _MatchRoomAutoRefreshState();
}

class _MatchRoomAutoRefreshState extends ConsumerState<MatchRoomAutoRefresh>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    ref
      ..invalidate(matchByIdProvider(widget.matchId))
      ..invalidate(matchScoreSubmissionsProvider(widget.matchId));
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
