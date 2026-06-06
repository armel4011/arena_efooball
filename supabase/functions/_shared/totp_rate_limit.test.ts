// Tests du rate-limit TOTP (_shared/totp_rate_limit.ts). Le module enrobe des
// RPC SQL atomiques ; on injecte un faux client `service` pour valider le
// mapping des réponses ET le comportement fail-open (un rate-limit en panne ne
// doit pas bloquer un admin légitime).
//
// Lancer : deno test --allow-all  (depuis supabase/functions/)

import { assert, assertEquals, assertFalse } from "jsr:@std/assert@1";
import {
  checkTotpLock,
  lockedBody,
  recordTotpFailure,
  recordTotpSuccess,
  type TotpLockState,
} from "./totp_rate_limit.ts";

interface RpcResult {
  data?: unknown;
  error?: { message: string } | null;
}

/** Faux ServiceClient : enregistre les appels et renvoie une réponse scriptée. */
function fakeService(impl: (name: string, params: unknown) => RpcResult) {
  const calls: Array<{ name: string; params: unknown }> = [];
  return {
    calls,
    rpc(name: string, params: unknown): Promise<RpcResult> {
      calls.push({ name, params });
      return Promise.resolve(impl(name, params));
    },
  };
}

Deno.test("lockedBody → corps 429 uniforme", () => {
  const state: TotpLockState = {
    locked: true,
    retryAfterSeconds: 1800,
    attemptsRemaining: 0,
  };
  assertEquals(lockedBody(state), {
    error: "admin_locked",
    retry_after_seconds: 1800,
  });
});

Deno.test("checkTotpLock → mappe l'état verrouillé renvoyé par la RPC", async () => {
  const svc = fakeService(() => ({
    data: { locked: true, retry_after_seconds: 120 },
  }));
  const state = await checkTotpLock(svc, "user-1");
  assert(state.locked);
  assertEquals(state.retryAfterSeconds, 120);
  assertEquals(svc.calls[0].name, "totp_check_lock");
  assertEquals(svc.calls[0].params, { p_user_id: "user-1" });
});

Deno.test("checkTotpLock → non verrouillé quand la RPC le dit", async () => {
  const svc = fakeService(() => ({ data: { locked: false } }));
  const state = await checkTotpLock(svc, "user-1");
  assertFalse(state.locked);
  assertEquals(state.retryAfterSeconds, 0);
});

Deno.test("checkTotpLock → fail-open si la RPC échoue", async () => {
  const svc = fakeService(() => ({ error: { message: "db down" } }));
  const state = await checkTotpLock(svc, "user-1");
  // Fail-open : on n'empêche pas la connexion, le code TOTP reste vérifié.
  assertFalse(state.locked);
  assertEquals(state.attemptsRemaining, 3);
});

Deno.test("recordTotpFailure → verrou détecté via locked_until", async () => {
  const svc = fakeService(() => ({
    data: { locked_until: "2026-06-06T12:00:00Z", attempts_remaining: 0 },
  }));
  const state = await recordTotpFailure(svc, "user-1");
  assert(state.locked);
  assertEquals(state.retryAfterSeconds, 30 * 60);
  assertEquals(svc.calls[0].name, "totp_record_failure");
});

Deno.test("recordTotpFailure → pas encore verrouillé, attempts_remaining mappé", async () => {
  const svc = fakeService(() => ({ data: { attempts_remaining: 2 } }));
  const state = await recordTotpFailure(svc, "user-1");
  assertFalse(state.locked);
  assertEquals(state.retryAfterSeconds, 0);
  assertEquals(state.attemptsRemaining, 2);
});

Deno.test("recordTotpFailure → fail-open si la RPC échoue", async () => {
  const svc = fakeService(() => ({ error: { message: "db down" } }));
  const state = await recordTotpFailure(svc, "user-1");
  assertFalse(state.locked);
  assertEquals(state.attemptsRemaining, 0);
});

Deno.test("recordTotpSuccess → appelle la RPC et avale l'erreur", async () => {
  const ok = fakeService(() => ({ error: null }));
  await recordTotpSuccess(ok, "user-1");
  assertEquals(ok.calls[0].name, "totp_record_success");
  assertEquals(ok.calls[0].params, { p_user_id: "user-1" });

  // Même en cas d'erreur RPC, ne doit pas jeter.
  const failing = fakeService(() => ({ error: { message: "db down" } }));
  await recordTotpSuccess(failing, "user-1");
  assertEquals(failing.calls.length, 1);
});
