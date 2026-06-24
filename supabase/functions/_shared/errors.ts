// =============================================================================
// ARENA — Aide à la gestion d'erreur des Edge Functions (audit 2026-06-24).
// =============================================================================
// Les réponses d'erreur exposées au client (TOTP, register-admin, …) ne doivent
// pas renvoyer le message brut Postgres/Auth/Resend : il peut fuiter des noms de
// colonnes, de contraintes ou des fragments de config provider.
//
// `safeDetail(detail)` :
//   - en prod : journalise le détail côté serveur et renvoie `undefined`
//     (le champ `detail` disparaît du JSON via la sérialisation).
//   - avec ARENA_DEBUG=1 : renvoie le détail pour le diagnostic local.
//
// Usage :
//   return jsonResponse(
//     { error: "secret_persist_failed", detail: safeDetail(updateErr.message, "setup-totp") },
//     500,
//   );
// =============================================================================

export function safeDetail(
  detail: unknown,
  context = "edge-fn",
): string | undefined {
  const message = detail === undefined || detail === null ? "" : String(detail);
  if (Deno.env.get("ARENA_DEBUG") === "1") {
    return message;
  }
  // Toujours tracer côté serveur pour ne pas perdre l'info de diagnostic.
  if (message.length > 0) {
    console.error(`[${context}] error detail (masqué côté client):`, message);
  }
  return undefined;
}
