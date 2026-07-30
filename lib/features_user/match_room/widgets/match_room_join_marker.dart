import 'package:arena/data/repositories/match_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Widget INVISIBLE : trace une fois que l'EXTÉRIEUR a rejoint la salle du
/// match (event persistant `room_joined`). C'est un signal d'engagement pour
/// l'arbitrage automatique du no-show : l'away s'est présenté dans la salle,
/// même s'il n'a pas (encore) démarré l'enregistrement.
///
/// À monter UNIQUEMENT pour le joueur EXTÉRIEUR d'un match football. L'insert
/// est idempotent côté repo (pas de doublon au remount / changement d'étape).
class MatchRoomJoinMarker extends ConsumerStatefulWidget {
  const MatchRoomJoinMarker({required this.matchId, super.key});

  final String matchId;

  @override
  ConsumerState<MatchRoomJoinMarker> createState() =>
      _MatchRoomJoinMarkerState();
}

class _MatchRoomJoinMarkerState extends ConsumerState<MatchRoomJoinMarker> {
  bool _done = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_done || !mounted) return;
      _done = true;
      // Fire-and-forget : une trace best-effort, on n'interrompt pas la salle
      // si l'insert échoue (offline, etc.).
      ref.read(matchRepositoryProvider).markRoomJoined(widget.matchId);
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
