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

/// Intitulé du sélecteur de coupable (verdict « 3 strikes »).
///
/// Partagé pour que les deux consoles énoncent EXACTEMENT la même conséquence :
/// désigner un coupable n'est pas trancher un score, c'est armer un
/// bannissement à vie au 3e verdict. Une console qui le dirait plus doucement
/// que l'autre ferait cliquer un admin sans qu'il mesure la portée.
const String disputeGuiltyLabel = 'Coupable de triche (strike)';

/// Rappel de la conséquence, affiché sous le sélecteur.
const String disputeGuiltyHint =
    'Facultatif et indépendant du vainqueur : perdre un litige n’est pas '
    'tricher. 3 verdicts de culpabilité = bannissement à vie du compte. '
    'Réservé au super-admin.';

/// Libellé de l’option « personne n’a triché » — le défaut.
const String disputeGuiltyNoneLabel = 'Aucun';
