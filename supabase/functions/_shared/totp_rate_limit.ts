// =============================================================================
// ARENA — Rate-limit TOTP partagé (admin-verify-totp + admin-stepup-totp)
// =============================================================================
// 3 échecs consécutifs → verrou 30 minutes (compteur partagé entre les deux
// EF — même surface d'attaque). Backend : table `totp_attempts` + fonctions
// SQL atomiques (service_role only), migration `20260602100000_totp_rate_limit`.
//
// Usage dans une EF :
//   const lock = await checkTotpLock(service, user.id);
//   if (lock.locked) return jsonResponse(lockedBody(lock), 429);
//   ... vérification du code ...
//   if (!ok) {
//     const failure = await recordTotpFailure(service, user.id);
//     if (failure.locked) return jsonResponse(lockedBody(failure), 429);
//     return jsonResponse({ error: "invalid_code",
//                           attempts_remaining: failure.attemptsRemaining }, 401);
//   }
//   await recordTotpSuccess(service, user.id);
// =============================================================================

// deno-lint-ignore no-explicit-any
type ServiceClient = any;

export interface TotpLockState {
  locked: boolean;
  retryAfterSeconds: number;
  attemptsRemaining: number;
}

/** Corps de réponse 429 uniforme pour les deux EF. */
export function lockedBody(state: TotpLockState): Record<string, unknown> {
  return {
    error: "admin_locked",
    retry_after_seconds: state.retryAfterSeconds,
  };
}

/** Lit l'état du verrou AVANT de vérifier le code (pas d'oracle TOTP). */
export async function checkTotpLock(
  service: ServiceClient,
  userId: string,
): Promise<TotpLockState> {
  const { data, error } = await service.rpc("totp_check_lock", {
    p_user_id: userId,
  });
  if (error) {
    // Fail-open contrôlé : si le rate-limit est indisponible on n'empêche
    // pas un admin légitime de se connecter — le code TOTP reste vérifié.
    console.error("[totp-rate-limit] check_lock failed:", error.message);
    return { locked: false, retryAfterSeconds: 0, attemptsRemaining: 3 };
  }
  return {
    locked: data?.locked === true,
    retryAfterSeconds: typeof data?.retry_after_seconds === "number"
      ? data.retry_after_seconds
      : 0,
    attemptsRemaining: 3,
  };
}

/** Enregistre un échec ; verrouille au 3e (atomique côté SQL). */
export async function recordTotpFailure(
  service: ServiceClient,
  userId: string,
): Promise<TotpLockState> {
  const { data, error } = await service.rpc("totp_record_failure", {
    p_user_id: userId,
  });
  if (error) {
    // Fail-CLOSED (audit 2026-06-24) : si l'enregistrement de l'échec est
    // indisponible, on NE PEUT PAS prouver que le compteur anti-bruteforce
    // s'incrémente. Renvoyer un verrou plutôt que `locked:false` évite qu'un
    // attaquant neutralise le rate-limit en saturant `totp_attempts` pour
    // tenter les codes sans limite. Un faux verrou transitoire (30 min) sur un
    // admin légitime est préférable à un bruteforce illimité.
    console.error("[totp-rate-limit] record_failure failed:", error.message);
    return { locked: true, retryAfterSeconds: 30 * 60, attemptsRemaining: 0 };
  }
  const lockedUntil = data?.locked_until;
  const locked = typeof lockedUntil === "string" && lockedUntil.length > 0;
  return {
    locked,
    retryAfterSeconds: locked ? 30 * 60 : 0,
    attemptsRemaining: typeof data?.attempts_remaining === "number"
      ? data.attempts_remaining
      : 0,
  };
}

/** Succès : remet le compteur à zéro. */
export async function recordTotpSuccess(
  service: ServiceClient,
  userId: string,
): Promise<void> {
  const { error } = await service.rpc("totp_record_success", {
    p_user_id: userId,
  });
  if (error) {
    console.error("[totp-rate-limit] record_success failed:", error.message);
  }
}
