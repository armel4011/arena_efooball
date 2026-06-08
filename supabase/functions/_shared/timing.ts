// =============================================================================
// ARENA — Comparaison de chaînes en temps constant (constant-time).
// =============================================================================
// Mutualise l'unique implémentation utilisée par :
//   * `totp.ts`            — comparaison de codes TOTP / hashes backup
//   * les 5 EF webhook     — comparaison du bearer `WEBHOOK_SECRET`
//     (dispatch_notification, cleanup-*, moderate-chat-message,
//      send-transactional-email)
//
// Une comparaison `a === b` classique court-circuite au premier octet
// différent : le temps de réponse fuit alors la longueur du préfixe correct,
// ce qui permet (en théorie, sur un canal à faible bruit) de reconstituer le
// secret octet par octet. On XOR tous les caractères et on n'évalue le
// résultat qu'à la fin → temps de comparaison indépendant du contenu.
//
// Note : on retourne quand même `false` immédiatement si les longueurs
// diffèrent. C'est le comportement standard (cf. `crypto.timingSafeEqual` de
// Node) — la longueur d'un bearer/hash n'est pas le secret à protéger.
// =============================================================================

export function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) {
    diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return diff === 0;
}
