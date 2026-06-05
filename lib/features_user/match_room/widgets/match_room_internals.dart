import 'package:arena/data/models/arena_match.dart';
import 'package:arena/data/repositories/match_repository.dart';

/// Helpers internes au flow match-room. Sortis du fichier `match_room_page`
/// pour que les vues extraites (outcome views, score flow) puissent en
/// dépendre sans avoir à passer les fonctions en paramètres.

/// Picks the most recent `score_submitted` event per player from a
/// flat list of events. Sorted by `created_at` ascending so the last
/// write to the map is the latest event — Supabase realtime returns
/// in arrival order and we can't rely on that being insertion order
/// when the dispute view triggers a resubmit.
Map<String, Map<String, dynamic>> latestSubmissionPerPlayer(
  List<Map<String, dynamic>> submissions,
) {
  final sorted = [...submissions]..sort((a, b) {
    final ta = DateTime.tryParse(a['created_at']?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final tb = DateTime.tryParse(b['created_at']?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    return ta.compareTo(tb);
  });
  final byPlayer = <String, Map<String, dynamic>>{};
  for (final s in sorted) {
    final by = s['created_by'] as String?;
    if (by != null) byPlayer[by] = s;
  }
  return byPlayer;
}

/// Compares two submitted score payloads and either commits the match
/// (concordant) or flips it to disputed. Partagé entre le ScoreFlowView
/// (premier soumission concordante) et le DisputedView (resubmit après
/// correction).
Future<void> resolveSubmissions({
  required ArenaMatch match,
  required Map<String, dynamic> p1Submission,
  required Map<String, dynamic> p2Submission,
  required MatchRepository repo,
  required void Function(Object error) onError,
}) async {
  final pl1 = (p1Submission['payload'] as Map?)?.cast<String, dynamic>() ?? {};
  final pl2 = (p2Submission['payload'] as Map?)?.cast<String, dynamic>() ?? {};
  final s1A = pl1['score1'] as int?;
  final s2A = pl1['score2'] as int?;
  final s1B = pl2['score1'] as int?;
  final s2B = pl2['score2'] as int?;
  if (s1A == null || s2A == null || s1B == null || s2B == null) return;

  final viaPenA = pl1['via_penalties'] == true;
  final viaPenB = pl2['via_penalties'] == true;
  final pen1A = pl1['penalty1'] as int?;
  final pen2A = pl1['penalty2'] as int?;
  final pen1B = pl2['penalty1'] as int?;
  final pen2B = pl2['penalty2'] as int?;

  final regulationConcordant = s1A == s1B && s2A == s2B;
  final penaltiesConcordant = viaPenA == viaPenB &&
      (!viaPenA || (pen1A == pen1B && pen2A == pen2B));
  final concordant = regulationConcordant && penaltiesConcordant;

  try {
    if (concordant) {
      // Le vainqueur et le score sont (re)calculés côté serveur par
      // `finalize_match_score`, qui revérifie la concordance des deux
      // soumissions — le client n'envoie que l'id du match.
      await repo.commitScore(matchId: match.id);
    } else {
      await repo.flagDisputed(match.id);
    }
  } catch (e) {
    onError(e);
  }
}
