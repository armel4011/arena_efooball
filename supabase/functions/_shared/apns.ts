// Helper APNs — envoie un push VoIP (PushKit) à un device iOS. Requis
// pour réveiller l'app sur un appel entrant même app tuée : FCM ne sait
// pas envoyer de push VoIP, d'où cet appel direct à APNs.
//
// Auth token-based (.p8) : un JWT ES256 signé avec la clé APNs, réutilisé
// jusqu'à 1 h. Aucune dépendance npm — SubtleCrypto natif de Deno.
//
// Secrets EF requis (Dashboard → Edge Functions → Settings → Secrets) :
//   - APNS_KEY_P8    : contenu du fichier AuthKey_XXXX.p8 (PEM, clé privée)
//   - APNS_KEY_ID    : Key ID de la clé   (Apple Developer → Keys)
//   - APNS_TEAM_ID   : Team ID du compte  (Apple Developer → Membership)
//   - APNS_BUNDLE_ID : bundle id iOS      (déf. `com.arena.app`)
//   - APNS_ENV       : `production` (déf.) | `sandbox` (builds debug Xcode)
//
// Tant que ces secrets ne sont pas posés, `readApnsConfig()` renvoie
// `null` et l'appelant retombe sur FCM / skip — déploiement sûr sans
// compte Apple Developer.

const APNS_HOSTS = {
  production: 'https://api.push.apple.com',
  sandbox: 'https://api.sandbox.push.apple.com',
} as const;

export interface ApnsConfig {
  keyP8: string;
  keyId: string;
  teamId: string;
  bundleId: string;
  host: string;
}

/// Lit la config APNs depuis l'environnement. Renvoie `null` si l'un des
/// secrets obligatoires manque — l'appel VoIP est alors simplement
/// ignoré (pas d'échec dur).
export function readApnsConfig(): ApnsConfig | null {
  const keyP8 = Deno.env.get('APNS_KEY_P8');
  const keyId = Deno.env.get('APNS_KEY_ID');
  const teamId = Deno.env.get('APNS_TEAM_ID');
  if (!keyP8 || !keyId || !teamId) return null;
  const env = Deno.env.get('APNS_ENV') === 'sandbox' ? 'sandbox' : 'production';
  return {
    keyP8,
    keyId,
    teamId,
    bundleId: Deno.env.get('APNS_BUNDLE_ID') ?? 'com.arena.app',
    host: APNS_HOSTS[env],
  };
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

async function importP8Key(pem: string): Promise<CryptoKey> {
  const body = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '')
    .replace(/\s+/g, '');
  const binary = Uint8Array.from(atob(body), (c) => c.charCodeAt(0));
  return crypto.subtle.importKey(
    'pkcs8',
    binary.buffer,
    { name: 'ECDSA', namedCurve: 'P-256' },
    false,
    ['sign'],
  );
}

// APNs accepte un JWT jusqu'à 1 h et plafonne sa régénération ; on garde
// le même token ~50 min.
let cachedJwt: { token: string; issuedAt: number } | null = null;

async function getApnsJwt(cfg: ApnsConfig): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedJwt && now - cachedJwt.issuedAt < 3000) return cachedJwt.token;

  const header = base64url(JSON.stringify({ alg: 'ES256', kid: cfg.keyId }));
  const claims = base64url(JSON.stringify({ iss: cfg.teamId, iat: now }));
  const unsigned = `${header}.${claims}`;
  const key = await importP8Key(cfg.keyP8);
  // ECDSA via SubtleCrypto produit déjà une signature P1363 (r||s) —
  // exactement le format attendu par JWS ES256.
  const sig = await crypto.subtle.sign(
    { name: 'ECDSA', hash: 'SHA-256' },
    key,
    new TextEncoder().encode(unsigned),
  );
  const jwt = `${unsigned}.${base64url(new Uint8Array(sig))}`;
  cachedJwt = { token: jwt, issuedAt: now };
  return jwt;
}

export interface VoipPushOptions {
  deviceToken: string;
  callId: string;
  callerName: string;
  /// Données relayées jusqu'aux événements CallKit côté Dart
  /// (`event.body['extra']`) — scope, scope_id, caller_id…
  extra: Record<string, string>;
}

/// Signale qu'APNs a explicitement rejeté le device token (410 Gone,
/// 400 BadDeviceToken, 403 ExpiredProviderToken sur le token). L'appelant
/// doit clear `profiles.voip_token` côté DB et ne PAS retry. Causes
/// typiques :
///  - HTTP 410 → device a désinstallé l'app ou logout-out d'iCloud
///  - HTTP 400 reason `BadDeviceToken` → format invalide / mauvais env
///  - HTTP 400 reason `DeviceTokenNotForTopic` → token enregistré pour
///    un autre bundle (rare, mais permanent)
export class ApnsTokenInvalidError extends Error {
  constructor(public readonly reason: string, public readonly detail: string) {
    super(`apns_token_invalid:${reason}:${detail}`);
    this.name = 'ApnsTokenInvalidError';
  }
}

/// Envoie un push VoIP au device.
///  - Throws `ApnsTokenInvalidError` si APNs rejette le token (410, 400
///    BadDeviceToken / DeviceTokenNotForTopic). L'appelant clear voip_token.
///  - Throws une erreur générique sur toute autre erreur.
export async function sendApnsVoipPush(
  cfg: ApnsConfig,
  opts: VoipPushOptions,
): Promise<void> {
  const jwt = await getApnsJwt(cfg);

  // Payload lu par `pushRegistry(_:didReceiveIncomingPushWith:)` côté iOS.
  const payload = {
    id: opts.callId,
    nameCaller: opts.callerName,
    handle: opts.callerName,
    isVideo: false,
    extra: opts.extra,
  };

  // Expiration courte : un appel non délivré sous ~45 s est périmé —
  // inutile qu'APNs le rejoue plus tard.
  const expiry = Math.floor(Date.now() / 1000) + 45;

  const res = await fetch(`${cfg.host}/3/device/${opts.deviceToken}`, {
    method: 'POST',
    headers: {
      authorization: `bearer ${jwt}`,
      'apns-topic': `${cfg.bundleId}.voip`,
      'apns-push-type': 'voip',
      'apns-priority': '10',
      'apns-expiration': String(expiry),
      'content-type': 'application/json',
    },
    body: JSON.stringify(payload),
  });
  if (!res.ok) {
    const txt = await res.text();
    // APNs renvoie `{"reason":"BadDeviceToken"}` ou similaire en JSON.
    let reason = '';
    try {
      const json = JSON.parse(txt) as { reason?: string };
      reason = json.reason ?? '';
    } catch (_) {
      // not JSON, fallthrough
    }
    const tokenInvalid = res.status === 410 ||
        reason === 'BadDeviceToken' ||
        reason === 'DeviceTokenNotForTopic' ||
        reason === 'Unregistered';
    if (tokenInvalid) {
      throw new ApnsTokenInvalidError(
        reason || `HTTP_${res.status}`,
        txt,
      );
    }
    throw new Error(`apns_voip_failed: ${res.status} ${txt}`);
  }
}
