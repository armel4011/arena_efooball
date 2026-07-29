import 'dart:async';

import 'package:arena/data/models/arena_match.dart';
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
/// Ce widget INVISIBLE couvre DEUX trous :
///  1) **Retour au premier plan** (`resumed`) — le geste du joueur qui sort
///     d'eFootball pour revenir sur ARENA : `invalidate` re-souscrit le stream
///     `autoDispose` et récupère l'état serveur à jour.
///  2) **Attente au premier plan** — cas de l'EXTÉRIEUR qui RESTE sur ARENA à
///     attendre le code du DOMICILE : aucun nouveau `resumed` ne se déclenche,
///     donc si le socket est figé le code n'arrive jamais. Un sondage périodique
///     (8 s, uniquement au premier plan) fait un fetch PONCTUEL (REST, sans
///     canal) et ne re-synchronise le stream QUE si un champ du déroulé a bougé
///     — évite le churn de canaux Realtime (piège « Too many channels »).
///
/// Le cache disque évite tout spinner pendant le rechargement.
class MatchRoomAutoRefresh extends ConsumerStatefulWidget {
  const MatchRoomAutoRefresh({required this.matchId, super.key});

  final String matchId;

  @override
  ConsumerState<MatchRoomAutoRefresh> createState() =>
      _MatchRoomAutoRefreshState();
}

class _MatchRoomAutoRefreshState extends ConsumerState<MatchRoomAutoRefresh>
    with WidgetsBindingObserver {
  static const _pollInterval = Duration(seconds: 8);

  Timer? _poll;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startPolling();
  }

  @override
  void dispose() {
    _poll?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-souscrit immédiatement les streams (état serveur frais) et relance
      // le sondage périodique.
      _refetch();
      _startPolling();
    } else {
      // En arrière-plan : on coupe le sondage (batterie/données ; l'OS gèle de
      // toute façon les timers) — il repartira au prochain `resumed`.
      _poll?.cancel();
    }
  }

  void _startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(_pollInterval, (_) => _pollOnce());
  }

  /// Sondage léger : SELECT ponctuel (pas de canal Realtime) ; on ne
  /// re-synchronise les streams QUE si le déroulé a changé côté serveur —
  /// typiquement quand le socket est figé et n'a pas poussé la mise à jour.
  Future<void> _pollOnce() async {
    if (!mounted) return;
    try {
      final fresh =
          await ref.read(matchRepositoryProvider).fetchById(widget.matchId);
      if (!mounted || fresh == null) return;
      final current = ref.read(matchByIdProvider(widget.matchId)).valueOrNull;
      if (_flowSignature(current) != _flowSignature(fresh)) {
        _refetch();
      }
    } catch (_) {
      // Réseau indisponible / offline : on ne fait rien, le prochain tick
      // (ou le resume) réessaiera. Pas de bruit dans la room.
    }
  }

  void _refetch() {
    ref
      ..invalidate(matchByIdProvider(widget.matchId))
      ..invalidate(matchScoreSubmissionsProvider(widget.matchId));
  }

  /// Signature des SEULS champs qui pilotent le déroulé de la salle. Exclut les
  /// champs bruités (compteurs de vues, timestamps de heartbeat) pour ne pas
  /// re-synchroniser inutilement.
  String _flowSignature(ArenaMatch? m) =>
      '${m?.status}|${m?.roomCode}|${m?.homePlayerId}|${m?.score1}|'
      '${m?.score2}|${m?.winnerId}|${m?.player1TeamName}|${m?.player2TeamName}';

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
