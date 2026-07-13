// Logique de résolution de litige partagée entre les consoles admin mobile et
// desktop (l'UI — Material vs Fluent — reste propre à chacune).

/// Score du « tapis vert » : le favorisé gagne **3-0**.
///
/// Oriente le 3-0 selon le vainqueur désigné, pour l'affichage et l'audit —
/// le serveur (`resolve_dispute`) force ce score de toute façon (cf.
/// migration `dispute_walkover_3_0`). Extrait ici pour que les deux consoles
/// calculent le score **identiquement** (source unique).
({int scoreP1, int scoreP2}) disputeWalkoverScore({
  required String? winnerId,
  required String? player1Id,
}) {
  final winsP1 = winnerId == player1Id;
  return (scoreP1: winsP1 ? 3 : 0, scoreP2: winsP1 ? 0 : 3);
}
