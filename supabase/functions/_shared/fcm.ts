// Helper FCM HTTP v1 — signe un JWT RS256 avec le service account
// Firebase, l'échange contre un OAuth token côté Google, puis envoie le
// message à FCM. Aucune dépendance npm — uniquement SubtleCrypto natif
// de Deno.
//
// Nécessite la variable d'environnement `FIREBASE_SERVICE_ACCOUNT_JSON`
// (contenu complet du JSON téléchargé depuis Firebase Console →
// Project Settings → Service Accounts → Generate new private key).

const TOKEN_URL = 'https://oauth2.googleapis.com/token';
const FCM_SCOPE = 'https://www.googleapis.com/auth/firebase.messaging';

interface ServiceAccount {
  project_id: string;
  private_key_id: string;
  private_key: string;
  client_email: string;
}

let cachedToken: { token: string; expiresAt: number } | null = null;

async function importPrivateKey(pem: string): Promise<CryptoKey> {
  const pemBody = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '')
    .replace(/\s+/g, '');
  const binary = Uint8Array.from(atob(pemBody), (c) => c.charCodeAt(0));
  return crypto.subtle.importKey(
    'pkcs8',
    binary.buffer,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );
}

function base64url(input: string | Uint8Array): string {
  const bytes = typeof input === 'string'
    ? new TextEncoder().encode(input)
    : input;
  let str = '';
  for (const b of bytes) str += String.fromCharCode(b);
  return btoa(str)
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');
}

async function getAccessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedToken && cachedToken.expiresAt > now + 60) {
    return cachedToken.token;
  }

  const header = base64url(JSON.stringify({
    alg: 'RS256',
    typ: 'JWT',
    kid: sa.private_key_id,
  }));
  const claims = base64url(JSON.stringify({
    iss: sa.client_email,
    scope: FCM_SCOPE,
    aud: TOKEN_URL,
    iat: now,
    exp: now + 3600,
  }));
  const unsigned = `${header}.${claims}`;
  const key = await importPrivateKey(sa.private_key);
  const sig = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    key,
    new TextEncoder().encode(unsigned),
  );
  const jwt = `${unsigned}.${base64url(new Uint8Array(sig))}`;

  const res = await fetch(TOKEN_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }).toString(),
  });
  if (!res.ok) {
    throw new Error(`token_exchange_failed: ${res.status} ${await res.text()}`);
  }
  const json = await res.json();
  cachedToken = {
    token: json.access_token,
    expiresAt: now + (json.expires_in ?? 3600),
  };
  return json.access_token;
}

export interface FcmPayload {
  fcmToken: string;
  title: string;
  body: string;
  data?: Record<string, string | number | boolean | null | undefined>;
  /// `true` → message DATA-only (pas de bloc `notification`). Utilisé
  /// pour les appels entrants : le handler background de l'app se
  /// déclenche même app tuée et affiche lui-même la notif plein écran.
  dataOnly?: boolean;
  /// URL publique d'une image à afficher dans la notif. Mappée sur
  /// `notification.image` (FCM v1 commun à Android/Web) + sur
  /// `android.notification.image` pour le big-picture style + sur
  /// `apns.fcm_options.image` pour iOS (NSE auto si l'app a un
  /// Notification Service Extension).
  imageUrl?: string;
}

/// Signale que FCM a explicitement rejeté le token : l'app a été
/// désinstallée, le token a été régénéré, ou le projet Firebase ne
/// reconnaît plus cet appareil. L'appelant doit clear le token côté
/// DB et ne PAS retry (sinon on inonde FCM en pure perte). Causes
/// typiques :
///  - HTTP 404 + errorCode `UNREGISTERED` → désinstallation / clear-data
///  - HTTP 400 + errorCode `INVALID_ARGUMENT` (sur le champ `token`)
///    → token mal formé ou pour un autre projet Firebase
///  - HTTP 403 + errorCode `SENDER_ID_MISMATCH` → token d'un autre projet
export class FcmTokenInvalidError extends Error {
  constructor(public readonly errorCode: string, public readonly detail: string) {
    super(`fcm_token_invalid:${errorCode}:${detail}`);
    this.name = 'FcmTokenInvalidError';
  }
}

/// Envoie une notification push via FCM HTTP v1.
///  - Throws `FcmTokenInvalidError` si FCM rejette explicitement le
///    token (404 UNREGISTERED, 400 INVALID_ARGUMENT, 403 SENDER_ID_MISMATCH).
///    L'appelant doit clear `profiles.fcm_token` et ne PAS retry.
///  - Throws une erreur générique sur tout autre échec (réseau, 5xx) —
///    l'appelant peut retenter plus tard.
export async function sendFcmNotification(opts: FcmPayload): Promise<void> {
  const saJson = Deno.env.get('FIREBASE_SERVICE_ACCOUNT_JSON');
  if (!saJson) {
    throw new Error('FIREBASE_SERVICE_ACCOUNT_JSON env var missing');
  }
  const sa: ServiceAccount = JSON.parse(saJson);
  const accessToken = await getAccessToken(sa);

  // FCM v1 exige que tous les champs `data` soient des strings.
  const stringData: Record<string, string> = {};
  for (const [k, v] of Object.entries(opts.data ?? {})) {
    if (v !== undefined && v !== null) stringData[k] = String(v);
  }

  const message: Record<string, unknown> = {
    token: opts.fcmToken,
    data: stringData,
    android: { priority: 'HIGH' },
  };
  if (!opts.dataOnly) {
    const notif: Record<string, string> = {
      title: opts.title,
      body: opts.body,
    };
    if (opts.imageUrl) notif.image = opts.imageUrl;
    message.notification = notif;
    const androidNotif: Record<string, string> = { sound: 'default' };
    if (opts.imageUrl) androidNotif.image = opts.imageUrl;
    message.android = {
      priority: 'HIGH',
      notification: androidNotif,
    };
    const apns: Record<string, unknown> = {
      payload: { aps: { sound: 'default' } },
    };
    if (opts.imageUrl) {
      apns.fcm_options = { image: opts.imageUrl };
    }
    message.apns = apns;
  }

  const sendUrl =
    `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`;
  const res = await fetch(sendUrl, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ message }),
  });
  if (!res.ok) {
    const txt = await res.text();
    // Parse l'errorCode FCM v1 (cf. https://firebase.google.com/docs/
    // reference/fcm/rest/v1/ErrorCode) — il vit dans error.details[].errorCode.
    let errorCode = '';
    try {
      const json = JSON.parse(txt) as {
        error?: {
          message?: string;
          status?: string;
          details?: Array<{ errorCode?: string }>;
        };
      };
      errorCode = json.error?.details?.[0]?.errorCode ??
          json.error?.status ?? '';
    } catch (_) {
      // Pas du JSON : on regarde le texte brut pour les codes connus.
      if (/UNREGISTERED|NotRegistered/i.test(txt)) errorCode = 'UNREGISTERED';
      else if (/SenderIdMismatch|SENDER_ID_MISMATCH/i.test(txt)) {
        errorCode = 'SENDER_ID_MISMATCH';
      } else if (/InvalidRegistration|INVALID_ARGUMENT/i.test(txt)) {
        errorCode = 'INVALID_ARGUMENT';
      }
    }
    // Token mort : 404 UNREGISTERED est le cas classique post-désinstall.
    // INVALID_ARGUMENT côté token (mauvais format) et SENDER_ID_MISMATCH
    // (token d'un autre projet Firebase) sont aussi définitifs.
    const tokenInvalid = res.status === 404 ||
        errorCode === 'UNREGISTERED' ||
        errorCode === 'SENDER_ID_MISMATCH' ||
        (res.status === 400 && errorCode === 'INVALID_ARGUMENT');
    if (tokenInvalid) {
      throw new FcmTokenInvalidError(errorCode || `HTTP_${res.status}`, txt);
    }
    throw new Error(`fcm_send_failed: ${res.status} ${txt}`);
  }
}
