// =============================================================================
// ARENA — Edge Function : moderate-chat-message
// =============================================================================
// Invoquée par trigger Postgres AFTER INSERT sur `chat_messages`. Cherche
// les `banned_words` dans le contenu, et si match :
//   1. Marque le row `is_moderated=true` + `moderated_reason="banned_word:..."`
//      + remplace les mots interdits par "***" de même longueur.
//   2. Log un `anti_cheat_events` (type='chat_abuse') si severity ≥ 2
//      — la modération chat alimente le compteur d'abus utilisé par le
//      super-admin (cf. RPC admin_filter_users dans [[admin-broadcast]]).
//
// Auth : pas de JWT (verify_jwt=false). Re-check du `WEBHOOK_SECRET`
// pour empêcher qu'un curl anonyme déclenche n'importe quoi sur un
// arbitrary chat_message.id.
//
// Inputs : payload Database Webhook standard `{type, table, schema,
// record, old_record}` — on s'attend uniquement à `INSERT chat_messages`.
// =============================================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

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

interface ChatMessageRecord {
  id: string;
  channel_id: string;
  sender_id: string | null;
  content: string;
  type: string;
  is_moderated: boolean;
  created_at: string;
}

interface WebhookPayload {
  type: "INSERT" | "UPDATE" | "DELETE";
  table: string;
  schema: string;
  record: ChatMessageRecord;
  old_record: unknown;
}

/// Normalise pour la recherche de mots interdits :
///  - lowercase
///  - retire les accents (NFKD + strip diacritics)
///  - garde les caractères alphanumériques + espaces (l'ASCII art passe
///    si le user remplace `o` par `0` etc., on prend ce risque V1 ;
///    pour la phase 2 on pourra ajouter un mapping leet→latin).
function normalize(text: string): string {
  return text
    .toLowerCase()
    .normalize("NFKD")
    .replace(/[̀-ͯ]/g, "");
}

/// Cherche `needle` (déjà normalisé) dans `haystack` en respectant les
/// frontières de mot. Retourne l'index de match dans `haystack` ou -1.
/// On évite des faux positifs type "scunthorpe" (mais un user qui
/// concatène volontairement reste détectable via leet, hors scope V1).
function findWord(haystack: string, needle: string): number {
  const re = new RegExp(
    `(^|[^\\p{L}\\p{N}])${
      needle.replace(/[-/\\^$*+?.()|[\]{}]/g, "\\$&")
    }($|[^\\p{L}\\p{N}])`,
    "u",
  );
  const m = re.exec(haystack);
  return m ? m.index + (m[1]?.length ?? 0) : -1;
}

interface BannedWord {
  word: string;
  language: string;
  severity: number;
  category: string | null;
}

interface Match {
  word: string;
  severity: number;
  start: number; // index in normalized content
  end: number;
}

/// Caviarde l'occurrence dans la string originale `content`. On part de
/// l'index dans la version normalisée — comme `NFKD` peut introduire
/// des codepoints supplémentaires (combining marks), on retombe sur une
/// recherche directe et on remplace toutes les occurrences case-
/// insensitive du mot dans la chaîne d'origine.
function redact(content: string, words: string[]): string {
  let out = content;
  for (const w of words) {
    const re = new RegExp(
      `(?<=^|[^\\p{L}\\p{N}])${
        w.replace(/[-/\\^$*+?.()|[\]{}]/g, "\\$&")
      }(?=$|[^\\p{L}\\p{N}])`,
      "giu",
    );
    out = out.replace(re, "*".repeat(w.length));
  }
  return out;
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

  let payload: WebhookPayload;
  try {
    payload = await req.json();
  } catch (_) {
    return jsonResponse({ error: "bad_json" }, 400);
  }

  if (payload.type !== "INSERT" || payload.table !== "chat_messages") {
    return jsonResponse({ ignored: true });
  }

  const msg = payload.record;
  if (!msg?.id || !msg.content || msg.is_moderated) {
    // Déjà modéré (rare — collision avec un autre handler) ou payload
    // foireux ; on no-op pour rester idempotent.
    return jsonResponse({ ignored: true });
  }
  if (msg.type !== "text") {
    // Seul le texte passe par la liste de mots. Les messages 'system'
    // viennent du backend (résultats matchs, etc.) et 'image' n'a pas
    // de payload texte à filtrer.
    return jsonResponse({ skipped: "non_text" });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceKey) {
    return jsonResponse({ error: "server_misconfigured" }, 500);
  }
  const sb = createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  // On charge tous les banned_words. V1 = quelques dizaines max ;
  // si on dépasse 1000 il faudra passer à une lookup indexée trigram
  // côté Postgres ou un Bloom filter en mémoire.
  const { data: bannedRows, error: bannedErr } = await sb
    .from("banned_words")
    .select("word, language, severity, category");
  if (bannedErr) {
    return jsonResponse(
      { error: "banned_words_lookup_failed", detail: bannedErr.message },
      500,
    );
  }
  const banned: BannedWord[] = bannedRows ?? [];
  if (banned.length === 0) {
    return jsonResponse({ skipped: "empty_dictionary" });
  }

  const normalized = normalize(msg.content);
  const matches: Match[] = [];
  for (const b of banned) {
    const needle = normalize(b.word);
    if (!needle) continue;
    const idx = findWord(normalized, needle);
    if (idx >= 0) {
      matches.push({
        word: b.word,
        severity: b.severity,
        start: idx,
        end: idx + needle.length,
      });
    }
  }
  if (matches.length === 0) {
    return jsonResponse({ clean: true });
  }

  const maxSeverity = Math.max(...matches.map((m) => m.severity));
  const offendingWords = matches.map((m) => m.word);
  const redacted = redact(msg.content, offendingWords);

  // UPDATE message — `is_moderated` true pour que l'UI puisse afficher
  // un badge "modéré" et éviter la re-modération en boucle si on
  // ré-insert (cf. guard plus haut).
  const reason = `banned_word(${maxSeverity}):${offendingWords.join(",")}`;
  const { error: updateErr } = await sb
    .from("chat_messages")
    .update({
      content: redacted,
      is_moderated: true,
      moderated_at: new Date().toISOString(),
      moderated_reason: reason,
    })
    .eq("id", msg.id);
  if (updateErr) {
    return jsonResponse(
      { error: "moderation_update_failed", detail: updateErr.message },
      500,
    );
  }

  // anti_cheat_events seulement si severity ≥ 2 — sinon on noierait
  // le super-admin sous des "merde" et autres jurons mineurs.
  if (maxSeverity >= 2 && msg.sender_id) {
    const { error: aceErr } = await sb.from("anti_cheat_events").insert({
      profile_id: msg.sender_id,
      type: "chat_abuse",
      severity: maxSeverity,
      data: {
        message_id: msg.id,
        channel_id: msg.channel_id,
        words: offendingWords,
        original_excerpt: msg.content.slice(0, 200),
      },
    });
    if (aceErr && Deno.env.get("ARENA_DEBUG") === "1") {
      console.error("anti_cheat_events insert failed:", aceErr.message);
    }
  }

  return jsonResponse({
    moderated: true,
    matchedWords: offendingWords,
    maxSeverity,
  });
});
