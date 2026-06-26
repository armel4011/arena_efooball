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
//     - `APNS_KEY_P8` / `APNS_KEY_ID` / `APNS_TEAM_ID` (optionnels) :
//       activent le push VoIP iOS. Absents → la branche VoIP est inerte
//       (cf. `_shared/apns.ts`).
//
// Flow :
//   webhook payload → check auth → fetch profile (fcm_token, voip_token)
//   → appel iOS + voip_token + APNs configuré ? push VoIP APNs
//                                       : sinon push FCM
//   → mark notifications.sent_at = now()
//
// Échecs gracieux : si le user n'a aucun token (jamais ouvert l'app sur
// mobile, OS notification permission refusée), on retourne 200 avec
// `no_token` plutôt que d'échouer — la ligne reste en `sent_at = null`
// et la prochaine fois où l'app s'ouvre, le token est enregistré et
// les notifs suivantes partent.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.108.2';
import type { ServiceClient } from '../_shared/db.ts';
import { FcmTokenInvalidError, sendFcmNotification } from '../_shared/fcm.ts';
import {
  ApnsTokenInvalidError,
  readApnsConfig,
  sendApnsVoipPush,
} from '../_shared/apns.ts';
import { timingSafeEqual } from '../_shared/timing.ts';
import { safeDetail } from '../_shared/errors.ts';

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

/// Stampe `notifications.sent_at = now()` pour que l'app ne ré-affiche
/// pas la notif en bandeau « non remis ». Best-effort — pas de retry V1.
async function markSent(
  sb: ServiceClient,
  id: string,
): Promise<void> {
  const { error } = await sb
    .from('notifications')
    .update({ sent_at: new Date().toISOString() })
    .eq('id', id);
  if (error && Deno.env.get('ARENA_DEBUG') === '1') {
    console.error('sent_at update failed:', error.message);
  }
}

/// Set `profiles.fcm_token = null` (ou `voip_token`) quand le service
/// push a explicitement rejeté le token. Évite de spammer FCM/APNs sur
/// des tokens morts à chaque insert. Le prochain cold start de l'app
/// re-enregistrera un nouveau token via NotificationService.attach.
async function clearDeadToken(
  sb: ServiceClient,
  userId: string,
  column: 'fcm_token' | 'voip_token',
): Promise<void> {
  const { error } = await sb
    .from('profiles')
    .update({ [column]: null })
    .eq('id', userId);
  if (error && Deno.env.get('ARENA_DEBUG') === '1') {
    console.error(`clear ${column} failed:`, error.message);
  }
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
    image_url: string | null;
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
  if (expected.length < 'Bearer '.length + 8 || !timingSafeEqual(got, expected)) {
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

  // Récupère les tokens push du destinataire (FCM Android + VoIP iOS).
  const { data: profile, error: profileErr } = await sb
    .from('profiles')
    .select('fcm_token, voip_token')
    .eq('id', r.user_id)
    .maybeSingle();

  if (profileErr) {
    return jsonResponse(
      { error: 'profile_lookup_failed', detail: safeDetail(profileErr.message, 'dispatch_notification') },
      500,
    );
  }
  const isCall = r.type === 'call_invite';
  const callId = (r.data?.['call_id'] as string | undefined) ?? '';
  const callerName = (r.data?.['caller_name'] as string | undefined) ?? '';

  // ─── iOS : appel entrant → push VoIP APNs ─────────────────────────
  // PushKit réveille l'app (même tuée) et présente l'UI CallKit par-
  // dessus le verrou. FCM ne peut pas livrer de push VoIP — d'où
  // l'appel direct à APNs.
  if (isCall && profile?.voip_token) {
    const apns = readApnsConfig();
    if (apns) {
      try {
        await sendApnsVoipPush(apns, {
          deviceToken: profile.voip_token,
          callId,
          callerName,
          extra: {
            call_id: callId,
            scope: (r.data?.['scope'] as string | undefined) ?? '',
            scope_id: (r.data?.['scope_id'] as string | undefined) ?? '',
            caller_id: (r.data?.['caller_id'] as string | undefined) ?? '',
            caller_name: callerName,
          },
        });
        await markSent(sb, r.id);
        return jsonResponse({ ok: true, channel: 'voip' });
      } catch (e) {
        // Token VoIP mort (410 Gone, BadDeviceToken…) : clear côté DB
        // pour ne pas resoumettre indéfiniment. Si l'utilisateur a aussi
        // un fcm_token (rare mais possible), on fallback dessous.
        if (e instanceof ApnsTokenInvalidError) {
          await clearDeadToken(sb, r.user_id, 'voip_token');
          if (Deno.env.get('ARENA_DEBUG') === '1') {
            console.warn(
              `voip_token cleared (${e.reason}) for user ${r.user_id}`,
            );
          }
          if (!profile.fcm_token) {
            return jsonResponse({
              skipped: 'voip_token_cleared',
              reason: e.reason,
            });
          }
          // sinon → fall through vers la branche FCM ci-dessous
        } else {
          return jsonResponse(
            { error: 'apns_send_failed', detail: safeDetail(String(e), 'dispatch_notification') },
            500,
          );
        }
      }
    }
    // APNs pas encore configuré (clé .p8 absente) : on retombe sur FCM
    // si un fcm_token existe, sinon on skip juste en dessous.
    if (Deno.env.get('ARENA_DEBUG') === '1') {
      console.warn('voip_token présent mais APNs non configuré — fallback FCM');
    }
  }

  // ─── Android (et fallback) : push FCM ─────────────────────────────
  if (!profile?.fcm_token) {
    return jsonResponse({ skipped: 'no_token' });
  }

  // Envoi FCM. On stamp `sent_at` même si l'envoi échoue (l'erreur sera
  // remontée à l'appelant du webhook) — pas de retry pour V1.
  // Les appels entrants partent en message DATA-only haute priorité :
  // le handler background de l'app se déclenche (même app tuée) et
  // déclenche l'UI d'appel native (CallKit).
  try {
    await sendFcmNotification({
      fcmToken: profile.fcm_token,
      title: r.title,
      body: r.body ?? '',
      dataOnly: isCall,
      imageUrl: isCall ? undefined : (r.image_url ?? undefined),
      data: isCall
        ? {
            notification_type: 'call_invite',
            call_id: callId,
            scope: (r.data?.['scope'] as string | undefined) ?? '',
            scope_id: (r.data?.['scope_id'] as string | undefined) ?? '',
            caller_id: (r.data?.['caller_id'] as string | undefined) ?? '',
            caller_name: callerName,
          }
        : {
            notification_id: r.id,
            notification_type: r.type,
            // Aplatit `data.route` si présent — utilisé côté app pour
            // router le tap (cf. ArenaNotification.route).
            route: (r.data?.['route'] as string | undefined) ?? '',
            // Aplatit l'image_url dans `data` aussi — sert de fallback
            // au foreground handler (cf. NotificationService._handleForeground)
            // au cas où `RemoteMessage.notification.android.imageUrl` ne
            // serait pas remonté par certains OEM Android.
            image_url: r.image_url ?? '',
          },
    });
  } catch (e) {
    // Token FCM mort (404 UNREGISTERED, SENDER_ID_MISMATCH, INVALID_ARGUMENT)
    // : clear côté DB et retourne 200 pour ne pas que le webhook DB
    // retry indéfiniment sur un token qui ne reviendra jamais.
    if (e instanceof FcmTokenInvalidError) {
      await clearDeadToken(sb, r.user_id, 'fcm_token');
      if (Deno.env.get('ARENA_DEBUG') === '1') {
        console.warn(
          `fcm_token cleared (${e.errorCode}) for user ${r.user_id}`,
        );
      }
      return jsonResponse({
        skipped: 'fcm_token_cleared',
        errorCode: e.errorCode,
      });
    }
    return jsonResponse(
      { error: 'fcm_send_failed', detail: safeDetail(String(e), 'dispatch_notification') },
      500,
    );
  }

  await markSent(sb, r.id);
  return jsonResponse({ ok: true });
});
