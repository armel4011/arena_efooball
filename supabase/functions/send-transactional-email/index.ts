// =============================================================================
// ARENA — Edge Function : send-transactional-email
// =============================================================================
// Dispatcher unique pour les emails transactionnels Arena. Le DB
// trigger appelant choisit un `kind` (admin_invitation / payout_validated)
// et passe les variables ; l'EF rend le template HTML+texte et POST sur
// l'API Resend.
//
// Auth : pas de JWT user (verify_jwt=false). Gate `WEBHOOK_SECRET`
// partagé avec les autres EFs cron/triggers.
//
// Config requise (secrets EF Dashboard) :
//   - `RESEND_API_KEY`     : clé Resend (re_xxx)
//   - `ARENA_EMAIL_FROM`   : adresse expéditeur vérifiée chez Resend
//     (par défaut "Arena <noreply@arena-skill.com>" si non set —
//     `arena-skill.com` est le domaine vérifié côté Resend pour V1).
//
// Inputs (POST JSON) :
//   {
//     kind: "admin_invitation" | "payout_validated",
//     recipient: string,
//     data: Record<string, unknown>
//   }
//
// Échec gracieux : si Resend renvoie un 4xx (clé invalide, domaine non
// vérifié, etc.), on log et renvoie 500. Si la table appelante a un
// rowstamp `email_sent_at` à update, c'est *son* trigger qui le gère
// (cf. dispatch_notification pattern). Ici on retourne juste un statut.
// =============================================================================

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

// ─────────────────────────────────────────────────────────────────────
// Templates
// ─────────────────────────────────────────────────────────────────────
// Conventions :
//   - HTML simple, inline CSS, pas de couleurs ARENA spécifiques sur
//     les fonds (compatibilité dark/light mode des clients mails).
//   - Plain text en fallback (Resend les expose côté webhook/inbox
//     preview, beaucoup de clients mail les utilisent encore).
//   - Toujours linker le support pour les cas de litige.

function escape(s: unknown): string {
  return String(s ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

interface EmailPayload {
  subject: string;
  html: string;
  text: string;
}

function templateAdminInvitation(data: Record<string, unknown>): EmailPayload {
  const code = String(data.code ?? "????-????-????").toUpperCase();
  const role = data.role === "super_admin" ? "Super-admin" : "Admin";
  const expires = data.expires_at
    ? new Date(String(data.expires_at)).toLocaleDateString("fr-FR")
    : "jamais";
  const fullCode = `ARENA-${code}`;
  return {
    subject: `Invitation Arena — devenez ${role}`,
    html: `
<!DOCTYPE html>
<html><body style="font-family:system-ui,sans-serif;line-height:1.5;max-width:520px;margin:0 auto;padding:24px">
  <h1 style="margin:0 0 16px">🎟️ Vous êtes invité·e sur Arena</h1>
  <p>Vous avez été invité·e à rejoindre Arena en tant que <strong>${escape(role)}</strong>.</p>
  <p>Votre code d'invitation à usage unique :</p>
  <div style="background:#0F0F12;color:#fff;padding:18px;border-radius:8px;font-family:monospace;font-size:18px;letter-spacing:2px;text-align:center;margin:16px 0">
    ${escape(fullCode)}
  </div>
  <p>Téléchargez l'app <strong>Arena Admin</strong>, puis ouvrez l'écran "Code invitation" et saisissez ce code.</p>
  <p style="color:#888;font-size:13px">Expire le : ${escape(expires)}.<br/>Ce code est nominatif et ne peut être redeemé qu'une fois.</p>
</body></html>`.trim(),
    text:
      `Vous avez été invité·e sur Arena en tant que ${role}.\n\n` +
      `Code d'invitation : ${fullCode}\n` +
      `Expire le : ${expires}\n\n` +
      `Téléchargez l'app Arena Admin et saisissez ce code dans l'écran "Code invitation".`,
  };
}

function templatePayoutValidated(data: Record<string, unknown>): EmailPayload {
  const amount = Number(data.amount_local ?? data.amount_usd ?? 0);
  const currency = String(data.currency ?? "USD");
  const competitionName = data.competition_name
    ? String(data.competition_name)
    : "votre compétition";
  const formatted = new Intl.NumberFormat("fr-FR", {
    minimumFractionDigits: 0,
    maximumFractionDigits: 2,
  }).format(amount);
  const method = data.payout_method
    ? ` (${String(data.payout_method)})`
    : "";
  return {
    subject: `Votre gain Arena est validé — ${formatted} ${currency}`,
    html: `
<!DOCTYPE html>
<html><body style="font-family:system-ui,sans-serif;line-height:1.5;max-width:520px;margin:0 auto;padding:24px">
  <h1 style="margin:0 0 16px">💸 Votre gain est validé</h1>
  <p>Le super-admin a validé votre payout pour <strong>${escape(competitionName)}</strong>.</p>
  <div style="background:#F4F4F6;padding:18px;border-radius:8px;font-size:24px;text-align:center;margin:16px 0">
    <strong>${escape(formatted)} ${escape(currency)}</strong>${escape(method)}
  </div>
  <p>Le virement sera initié sous 48h ouvrées. Vous recevrez une notification dès qu'il sera complété.</p>
  <p style="color:#888;font-size:13px">Si vous avez une question, contactez le support depuis l'app (Profil → Aide).</p>
</body></html>`.trim(),
    text:
      `Votre payout Arena pour ${competitionName} est validé.\n\n` +
      `Montant : ${formatted} ${currency}${method}\n\n` +
      `Le virement sera initié sous 48h ouvrées.`,
  };
}

/// Template de diagnostic : envoi minimaliste plain-text, sans HTML
/// ni boutons / liens — moins susceptible d'être classé "Promotions"
/// ou "Spam" par Gmail/Outlook. Utilisé pour valider la propagation
/// DNS du domaine d'envoi quand un envoi richement formaté n'arrive
/// pas. `data.note` est optionnel et inclus dans le texte.
function templateTestPlain(data: Record<string, unknown>): EmailPayload {
  const note = data.note ? `\n\nNote : ${String(data.note)}` : "";
  return {
    subject: "Arena - test de connexion email",
    html: `<p>Ceci est un email de test envoye depuis l'infrastructure Arena.${
      data.note ? ` Note : ${escape(data.note)}.` : ""
    } Si tu le recois, le pipeline Resend fonctionne.</p>`,
    text:
      `Ceci est un email de test envoye depuis l'infrastructure Arena.\n` +
      `Si tu le recois, le pipeline Resend fonctionne correctement.${note}\n`,
  };
}

const TEMPLATES: Record<string, (d: Record<string, unknown>) => EmailPayload> = {
  admin_invitation: templateAdminInvitation,
  payout_validated: templatePayoutValidated,
  test_plain: templateTestPlain,
};

// ─────────────────────────────────────────────────────────────────────
// Resend
// ─────────────────────────────────────────────────────────────────────
async function sendViaResend(opts: {
  apiKey: string;
  from: string;
  to: string;
  subject: string;
  html: string;
  text: string;
}): Promise<{ ok: true; id: string } | { ok: false; status: number; body: string }> {
  const res = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${opts.apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from: opts.from,
      to: opts.to,
      subject: opts.subject,
      html: opts.html,
      text: opts.text,
    }),
  });
  if (!res.ok) {
    return { ok: false, status: res.status, body: await res.text() };
  }
  const body = await res.json() as { id?: string };
  return { ok: true, id: body.id ?? "" };
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405);
  }

  const expected = `Bearer ${Deno.env.get("WEBHOOK_SECRET") ?? ""}`;
  const got = req.headers.get("authorization") ?? "";
  if (expected.length < "Bearer ".length + 8 || got !== expected) {
    return jsonResponse({ error: "unauthorized" }, 401);
  }

  const apiKey = Deno.env.get("RESEND_API_KEY");
  const from = Deno.env.get("ARENA_EMAIL_FROM") ??
    "Arena <noreply@arena-skill.com>";
  if (!apiKey) {
    return jsonResponse({ error: "resend_not_configured" }, 500);
  }

  let body: { kind?: unknown; recipient?: unknown; data?: unknown };
  try {
    body = await req.json();
  } catch (_) {
    return jsonResponse({ error: "bad_json" }, 400);
  }
  const kind = typeof body.kind === "string" ? body.kind : "";
  const recipient = typeof body.recipient === "string"
    ? body.recipient.trim()
    : "";
  const data: Record<string, unknown> = (body.data && typeof body.data === "object")
    ? body.data as Record<string, unknown>
    : {};
  if (!kind || !recipient) {
    return jsonResponse({ error: "missing_fields" }, 400);
  }
  if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(recipient)) {
    return jsonResponse({ error: "bad_recipient" }, 400);
  }
  const renderer = TEMPLATES[kind];
  if (!renderer) {
    return jsonResponse({ error: "unknown_kind", kind }, 400);
  }

  const tpl = renderer(data);
  const result = await sendViaResend({
    apiKey,
    from,
    to: recipient,
    subject: tpl.subject,
    html: tpl.html,
    text: tpl.text,
  });
  if (!result.ok) {
    return jsonResponse(
      { error: "resend_send_failed", status: result.status, detail: result.body },
      502,
    );
  }
  return jsonResponse({ ok: true, providerId: result.id });
});
