// Tests de la classe d'erreur FCM (_shared/fcm.ts). `sendFcmNotification`
// dépend de l'env + réseau (échange OAuth Google) donc n'est pas unit-testé
// ici ; on couvre l'invariant exposé à l'appelant : FcmTokenInvalidError
// (utilisé pour décider de clear `profiles.fcm_token` sans retry).
//
// Lancer : deno test --allow-all  (depuis supabase/functions/)

import { assert, assertEquals } from "jsr:@std/assert@1";
import { FcmTokenInvalidError } from "./fcm.ts";

Deno.test("FcmTokenInvalidError → expose errorCode, detail et message", () => {
  const err = new FcmTokenInvalidError("UNREGISTERED", "404");
  assert(err instanceof Error);
  assertEquals(err.name, "FcmTokenInvalidError");
  assertEquals(err.errorCode, "UNREGISTERED");
  assertEquals(err.detail, "404");
  assertEquals(err.message, "fcm_token_invalid:UNREGISTERED:404");
});
