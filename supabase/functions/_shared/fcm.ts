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
}

/// Envoie une notification push via FCM HTTP v1. Throws sur erreur réseau
/// ou statut !=200 — l'appelant logge et marque la notif comme
/// `sent_at = null` (retry sur la prochaine insertion).
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
    message.notification = { title: opts.title, body: opts.body };
    message.android = { priority: 'HIGH', notification: { sound: 'default' } };
    message.apns = { payload: { aps: { sound: 'default' } } };
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
    throw new Error(`fcm_send_failed: ${res.status} ${txt}`);
  }
}
