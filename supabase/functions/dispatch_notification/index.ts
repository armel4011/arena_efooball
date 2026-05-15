// Edge Function : dispatch d'une notification push FCM quand un row
// est inséré dans `public.notifications` (PHASE 12.5).
//
// Configuration :
//  1. Database Webhook Supabase pointant vers cette EF (Dashboard →
//     Database → Webhooks → New). Type : `INSERT`, table :
//     `notifications`. Auth : `Bearer ${WEBHOOK_SECRET}`.
//  2. Secrets EF (Dashboard → Edge Functions → Settings → Secrets) :
//     - `FIREBASE_SERVICE_ACCOUNT_JSON` : contenu du service account JSON
//     - `WEBHOOK_SECRET`               : token partagé avec le webhook
//     - `SUPABASE_URL` + `SUPABASE_SERVICE_ROLE_KEY` sont auto-injectés
//
// Flow :
//   webhook payload → check auth → fetch profile.fcm_token → sign FCM →
//   send → mark notifications.sent_at = now()
//
// Échecs gracieux : si le user n'a pas de fcm_token (jamais ouvert l'app
// sur mobile, OS notification permission refusée), on retourne 200 avec
// `no_token` plutôt que d'échouer — la ligne reste en `sent_at = null`
// et la prochaine fois où l'app s'ouvre, le token est enregistré et
// les notifs suivantes partent.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.4';
import { sendFcmNotification } from '../_shared/fcm.ts';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function jsonResponse(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

interface WebhookPayload {
  type: 'INSERT' | 'UPDATE' | 'DELETE';
  table: string;
  schema: string;
  record: {
    id: string;
    user_id: string;
    type: string;
    title: string;
    body: string | null;
    data: Record<string, unknown> | null;
    sent_at: string | null;
    created_at: string;
  };
  old_record: unknown;
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }
  if (req.method !== 'POST') {
    return jsonResponse({ error: 'method_not_allowed' }, 405);
  }

  // Auth : shared bearer secret entre le webhook DB et l'EF.
  const expected = `Bearer ${Deno.env.get('WEBHOOK_SECRET') ?? ''}`;
  const got = req.headers.get('authorization') ?? '';
  if (expected.length < 'Bearer '.length + 8 || got !== expected) {
    return jsonResponse({ error: 'unauthorized' }, 401);
  }

  let payload: WebhookPayload;
  try {
    payload = await req.json();
  } catch (_) {
    return jsonResponse({ error: 'invalid_json' }, 400);
  }

  if (payload.type !== 'INSERT' || payload.table !== 'notifications') {
    // Ignore silencieusement les autres événements — la webhook est
    // censée filtrer, mais on garde-fou si la config dérive.
    return jsonResponse({ ignored: true });
  }

  const r = payload.record;
  if (!r?.user_id) {
    return jsonResponse({ error: 'missing_user_id' }, 400);
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!supabaseUrl || !serviceKey) {
    return jsonResponse({ error: 'server_misconfigured' }, 500);
  }
  const sb = createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  // Récupère le token FCM du destinataire.
  const { data: profile, error: profileErr } = await sb
    .from('profiles')
    .select('fcm_token')
    .eq('id', r.user_id)
    .maybeSingle();

  if (profileErr) {
    return jsonResponse(
      { error: 'profile_lookup_failed', detail: profileErr.message },
      500,
    );
  }
  if (!profile?.fcm_token) {
    return jsonResponse({ skipped: 'no_token' });
  }

  // Envoi FCM. On stamp `sent_at` même si l'envoi échoue (l'erreur sera
  // remontée à l'appelant du webhook) — pas de retry pour V1.
  try {
    await sendFcmNotification({
      fcmToken: profile.fcm_token,
      title: r.title,
      body: r.body ?? '',
      data: {
        notification_id: r.id,
        notification_type: r.type,
        // Aplatit `data.route` si présent — utilisé côté app pour
        // router le tap (cf. ArenaNotification.route).
        route: (r.data?.['route'] as string | undefined) ?? '',
      },
    });
  } catch (e) {
    return jsonResponse(
      { error: 'fcm_send_failed', detail: String(e) },
      500,
    );
  }

  // Marque la notif comme envoyée pour que l'app n'essaye pas de la
  // ré-afficher en bandeau "non remis".
  const { error: updateErr } = await sb
    .from('notifications')
    .update({ sent_at: new Date().toISOString() })
    .eq('id', r.id);
  if (updateErr && Deno.env.get('ARENA_DEBUG') === '1') {
    console.error('sent_at update failed:', updateErr.message);
  }

  return jsonResponse({ ok: true });
});
