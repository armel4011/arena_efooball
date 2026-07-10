// =============================================================================
// ARENA — Edge Function : register-admin
// =============================================================================
// Crée un compte admin/super-admin à partir d'un code d'invitation
// généré par un super-admin existant (cf. SuperAdminInvitations, SA2).
//
// Auth : public (verify_jwt = false). L'authentification "implicite"
// vient du code d'invitation lui-même : il est révoqué après usage et
// peut être bloqué à un email cible. Anyone-with-link n'est PAS un
// risque — sans un code valide on retombe sur `invalid_invitation_code`.
//
// Inputs (POST JSON) :
//   { code, email, password, username, cguAcceptedAt, cguVersionAccepted }
//   `code` accepte les formats "ARENA-XXXX-XXXX-XXXX" (UI) ou
//   "XXXX-XXXX-XXXX" (valeur DB). Le préfixe est strippé côté EF.
//
// Output : { profile } — Profile complet (sans `totp_secret`), à
// hydrater côté Flutter via Profile.fromJson. La session Supabase doit
// être obtenue ensuite par un signInWithPassword classique.
// =============================================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.108.2";
import {
  rateLimitKey,
  isInvitationExpired,
  normalizeCode,
  validateRegisterFields,
} from "./logic.ts";
import { safeDetail } from "../_shared/errors.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

interface RegisterBody {
  code?: unknown;
  email?: unknown;
  password?: unknown;
  username?: unknown;
  cguAcceptedAt?: unknown;
  cguVersionAccepted?: unknown;
}

// Validation pure (mot de passe / code / champs) + clientIp + expiration :
// extraits dans ./logic.ts pour être testables hors `Deno.serve`.

// deno-lint-ignore no-explicit-any
type ServiceClient = any;

// Enregistre un échec de redeem (code refusé) pour l'IP. Fail-open : si le
// backend rate-limit est indisponible, on n'empêche pas un admin légitime —
// on log seulement.
async function recordFailure(
  service: ServiceClient,
  ip: string,
): Promise<void> {
  try {
    await service.rpc("register_admin_record_failure", { p_ip: ip });
  } catch (e) {
    if (Deno.env.get("ARENA_DEBUG") === "1") {
      console.error("[register-admin] record_failure failed:", e);
    }
  }
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceKey) {
    return jsonResponse({ error: "server_misconfigured" }, 500);
  }

  let body: RegisterBody;
  try {
    body = await req.json();
  } catch (_) {
    return jsonResponse({ error: "bad_json" }, 400);
  }

  const rawCode = typeof body.code === "string" ? body.code : "";
  const email = typeof body.email === "string"
    ? body.email.trim().toLowerCase()
    : "";
  const password = typeof body.password === "string" ? body.password : "";
  const username = typeof body.username === "string"
    ? body.username.trim()
    : "";
  const cguAcceptedAt = typeof body.cguAcceptedAt === "string"
    ? body.cguAcceptedAt
    : "";
  const cguVersionAccepted = typeof body.cguVersionAccepted === "string"
    ? body.cguVersionAccepted.trim()
    : "";

  // Validation rapide côté serveur (séquence pure → register-admin/logic.ts).
  // Messages peu bavards : pas d'oracle sur quelle partie a échoué.
  const fieldError = validateRegisterFields({
    rawCode,
    email,
    password,
    username,
  });
  if (fieldError) {
    return jsonResponse({ error: fieldError }, 400);
  }
  const code = normalizeCode(rawCode);

  const service = createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  // 0. Rate-limit par IP (anti-énumération de codes). Lu AVANT toute requête
  //    sur `invitation_codes` → un attaquant verrouillé n'obtient aucun signal
  //    sur l'existence/état d'un code. Fail-open : si le backend est indispo on
  //    laisse passer (un admin légitime ne doit pas être bloqué par une panne).
  // Clé de rate-limit = email cible (non-spoofable) plutôt que l'IP seule —
  // le header x-forwarded-for est partiellement contrôlé par le client.
  const ip = rateLimitKey(email, req);
  try {
    const { data: lock } = await service.rpc("register_admin_check_lock", {
      p_ip: ip,
    });
    if (lock?.locked === true) {
      return jsonResponse(
        {
          error: "too_many_attempts",
          retry_after_seconds: lock.retry_after_seconds ?? 1800,
        },
        429,
      );
    }
  } catch (e) {
    if (Deno.env.get("ARENA_DEBUG") === "1") {
      console.error("[register-admin] check_lock failed:", e);
    }
  }

  // 1. Charge le code d'invitation. On lit *sans* gate uses_count pour
  //    pouvoir donner des messages d'erreur distincts (already_used vs
  //    expired vs invalid).
  const { data: invite, error: inviteErr } = await service
    .from("invitation_codes")
    .select(
      "id, code, role, target_email, expires_at, uses_count, max_uses, used_at, allowed_country_codes, allowed_sections",
    )
    .eq("code", code)
    .maybeSingle();
  if (inviteErr) {
    return jsonResponse(
      {
        error: "invitation_lookup_failed",
        detail: safeDetail(inviteErr.message, "register-admin"),
      },
      500,
    );
  }
  // Chaque code refusé compte comme une tentative pour l'IP. Les codes
  // d'erreur restent distincts (l'UI s'appuie dessus) mais le rate-limit borne
  // le nombre de probes possibles → l'oracle d'énumération devient inexploitable.
  if (!invite) {
    await recordFailure(service, ip);
    return jsonResponse({ error: "invalid_invitation_code" }, 404);
  }
  if (invite.uses_count >= invite.max_uses) {
    await recordFailure(service, ip);
    return jsonResponse({ error: "invitation_already_used" }, 409);
  }
  if (isInvitationExpired(invite.expires_at, Date.now())) {
    await recordFailure(service, ip);
    return jsonResponse({ error: "invitation_expired" }, 410);
  }
  if (invite.target_email && invite.target_email !== email) {
    // Code émis pour une adresse précise — l'admin l'a saisie côté SA2,
    // on bloque toute tentative de redeem avec une autre boîte.
    await recordFailure(service, ip);
    return jsonResponse({ error: "invitation_email_mismatch" }, 403);
  }

  // 1bis. RÉSERVATION ATOMIQUE du slot (ferme la race condition).
  //   On incrémente `uses_count` sous deux conditions : qu'il n'ait pas bougé
  //   depuis la lecture ci-dessus (compare-and-swap via `.eq(uses_count, …)`)
  //   et qu'il reste de la place (`.lt(uses_count, max_uses)`). Postgres
  //   sérialise les UPDATE concurrents sur la même ligne : deux redeems
  //   simultanés du même code à usage unique → un seul gagne le slot, l'autre
  //   reçoit 0 ligne → 409. Sans ça, deux requêtes lisaient `uses_count` en
  //   parallèle, passaient toutes deux le check, et créaient chacune un compte.
  const { data: claimed, error: claimErr } = await service
    .from("invitation_codes")
    .update({ uses_count: invite.uses_count + 1 })
    .eq("id", invite.id)
    .eq("uses_count", invite.uses_count)
    .lt("uses_count", invite.max_uses)
    .select("id")
    .maybeSingle();
  if (claimErr) {
    return jsonResponse(
      {
        error: "invitation_claim_failed",
        detail: safeDetail(claimErr.message, "register-admin"),
      },
      500,
    );
  }
  if (!claimed) {
    // Un redeem concurrent a pris le dernier slot entre la lecture et ici.
    return jsonResponse({ error: "invitation_already_used" }, 409);
  }

  // Libère le slot réservé si une étape suivante échoue (best-effort). Le
  // `.eq(uses_count, invite.uses_count + 1)` garantit qu'on ne décrémente que
  // notre propre incrément, jamais celui d'un redeem concurrent légitime.
  const releaseSlot = async () => {
    try {
      await service
        .from("invitation_codes")
        .update({ uses_count: invite.uses_count })
        .eq("id", invite.id)
        .eq("uses_count", invite.uses_count + 1);
    } catch (_) {
      // best-effort : pire cas, un slot reste consommé (refus côté sûreté).
    }
  };

  // 2. Crée le compte auth.users via l'admin API. `email_confirm: true`
  //    skippe l'OTP : le super-admin a déjà délivré le canal de
  //    confiance (l'invitation), pas la peine de re-confirmer.
  const { data: created, error: createErr } = await service.auth.admin
    .createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: { username },
    });
  if (createErr || !created.user) {
    // Échec création : on rend le slot qu'on avait réservé.
    await releaseSlot();
    // Supabase renvoie un message du type "User already registered"
    // qu'on remappe pour l'UI.
    const msg = createErr?.message ?? "";
    if (/already/i.test(msg) || /exists/i.test(msg)) {
      return jsonResponse({ error: "email_already_registered" }, 409);
    }
    if (/password/i.test(msg)) {
      return jsonResponse({ error: "password_rejected", detail: msg }, 400);
    }
    return jsonResponse(
      {
        error: "auth_create_failed",
        detail: safeDetail(msg, "register-admin"),
      },
      500,
    );
  }
  const userId = created.user.id;

  // 3. Insert le profile avec le rôle dérivé de l'invitation.
  //    `country_code` n'est pas demandé par le form admin V1 — on default
  //    sur "CM" (cf. seed dev super-admin) ; l'admin pourra l'éditer
  //    depuis son écran profil.
  //    Scope (volet 3) : le code d'invitation peut restreindre le futur admin
  //    à certains pays / sections. On propage tel quel (null = aucun scope).
  const { data: profile, error: profileErr } = await service
    .from("profiles")
    .insert({
      id: userId,
      username,
      email,
      country_code: "CM",
      role: invite.role,
      admin_allowed_countries: invite.allowed_country_codes ?? null,
      admin_allowed_sections: invite.allowed_sections ?? null,
      auth_provider: "email",
      cgu_accepted_at: cguAcceptedAt || new Date().toISOString(),
      cgu_version_accepted: cguVersionAccepted || "2026-05-01",
      privacy_policy_accepted_at: cguAcceptedAt || new Date().toISOString(),
    })
    .select("*")
    .single();
  if (profileErr || !profile) {
    // Rollback du auth user pour éviter un orphan — un super-admin
    // pourrait avoir du mal à diagnostiquer "email pris mais pas de
    // profile". L'erreur la plus fréquente ici est `username` déjà
    // pris (contrainte unique côté DB).
    await service.auth.admin.deleteUser(userId).catch(() => {});
    await releaseSlot();
    const detail = profileErr?.message ?? "";
    if (/username/i.test(detail) && /unique/i.test(detail)) {
      return jsonResponse({ error: "username_already_taken" }, 409);
    }
    return jsonResponse(
      { error: "profile_insert_failed", detail: safeDetail(detail, "register-admin") },
      500,
    );
  }

  // 4. Stampe l'audit du redeem. `uses_count` a DÉJÀ été incrémenté
  //    atomiquement à l'étape 1bis (réservation) — ici on ne pose plus que
  //    l'horodatage et l'auteur. Échec non bloquant : le compte est créé,
  //    le slot est déjà consommé, seule la traçabilité used_at/used_by manque.
  const { error: stampErr } = await service
    .from("invitation_codes")
    .update({
      used_at: new Date().toISOString(),
      used_by: userId,
    })
    .eq("id", invite.id);
  if (stampErr && Deno.env.get("ARENA_DEBUG") === "1") {
    console.error("invitation stamp failed:", stampErr.message);
  }

  // 4bis. Inscription réussie → on nettoie le compteur de tentatives de l'IP
  //        (best-effort, non bloquant).
  try {
    await service.rpc("register_admin_record_success", { p_ip: ip });
  } catch (_) {
    // best-effort : au pire le compteur expirera tout seul (fenêtre 15 min).
  }

  // 5. Retourne le profil au client (le freezed Profile lit ces champs).
  //    Pas de session ici — le client appelle ensuite
  //    signInWithPassword pour obtenir le JWT.
  const safeProfile: Record<string, unknown> = { ...profile };
  delete safeProfile.totp_secret;
  delete safeProfile.backup_codes;
  return jsonResponse({ profile: safeProfile });
});
