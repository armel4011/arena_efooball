# Audit complet ARENA — 2026-06-08

**Périmètre :** 335 fichiers Dart (~76 k lignes hors généré), 134 migrations SQL,
16 Edge Functions, 70 fichiers de test.
**Méthode :** `flutter analyze`, advisors Supabase (sécurité + performance),
5 agents d'audit spécialisés en lecture seule (architecture Dart, conformité UI,
Edge Functions, RLS/autorisation DB, secrets/config/CI).

## Note globale : **8.5 / 10** — mûr, prêt prod, dette maîtrisée

| Axe | Note | Verdict |
|---|---|---|
| Sécurité DB / RLS / autorisation | 9.5/10 | ✅ Excellent — 10/10 RPC argent gardées |
| Secrets / Config / CI / Build | 9/10 | ✅ Excellent — gitleaks bloquant |
| Edge Functions (sécurité) | 8/10 | 🟢 Bon — durcissements |
| Architecture / Qualité code | 7.8/10 | 🟢 Bon — fichiers god-file |
| Conformité UI (design system) | ~95% | 🟢 Forte conformité |
| Analyse statique (`lib/`) | 10/10 | ✅ 0 issue |

**Aucun finding 🔴 critique.**

---

## 1. Sécurité base de données (RLS / autorisation) — 9.5/10

Les **10 RPC manipulant argent ou verdicts** vérifient toutes l'autorisation en
interne :

| RPC | Migration | Garde |
|---|---|---|
| `claim_payout` | `20260605142815_payout_pipeline` | propriétaire (`auth.uid()`) + statut |
| `generate_payouts` | `20260605145904_f1_reliability` | `is_super_admin()` + idempotence |
| `mark_payout_paid` | `20260605145904_f1_reliability` | `is_super_admin()` |
| `mark_payment_refunded` | `20260605151304_refund_queue` | `is_super_admin()` |
| `cancel_competition` | `20260605151304_refund_queue` | `is_admin()` |
| `resolve_dispute` | `20260605154411_resolve_dispute_atomic` | `is_admin()` + justification |
| `finalize_match_score` | `20260605100000_secure_match_score_finalization` | joueur du match, score relu serveur-side, `FOR UPDATE` |
| `forfeit_match` | idem | joueur du match |
| `delete_competition_cascade` | `20260514100001_…` | `is_admin()` |
| `regenerate_competition` | `20260520120000_…` | `is_admin()` |

Toutes ont aussi `set search_path = public, pg_temp` (anti-injection de schéma)
et `revoke execute from anon, public`.

**Patterns dangereux : 0** — aucun `USING (true)` sur table sensible, aucun
`GRANT ALL`, aucun `for insert/update/delete to anon`.

**Advisors — analyse :**
- `public_profiles` (ERROR `security_definer_view`) = **faux positif assumé**.
  Colonnes exposées : id, username, avatar_color, country_code, stats, role,
  is_active, permanent_ban, totp_enabled, last_seen_at, created/updated_at.
  **Aucune PII** (ni email, whatsapp, fcm, solde, totp_secret). Le
  `security_invoker = false` est nécessaire pour les lectures cross-user
  (adversaire, bracket, classement). **Ne pas passer en `security_invoker = on`**
  — cela viderait tous les écrans cross-user.
- `totp_attempts` + `match_reminders_sent` (INFO `rls_enabled_no_policy`) =
  **faux positifs assumés** : RLS deny-all + `revoke all` volontaires → tables
  internes service_role uniquement (anti-bruteforce non manipulable par l'user).

---

## 2. Secrets / Config / CI / Build — 9/10

- **Aucun `service_role` ni JWT/clé Firebase dans `lib/`.**
- **Aucun fichier sensible tracké** (keystore, `.env`, `google-services.json`,
  `.mcp.json`) — uniquement des `.example`.
- CI : **gitleaks bloquant** + OSV, build APK 2 flavors, build Windows, job Deno
  (lint/check/test). Aucun secret en clair dans les workflows.
- Permissions Android toutes justifiées (`<queries>` ciblée vs `QUERY_ALL_PACKAGES`),
  services `exported="false"`.
- Signing : fallback debug documenté ; keystore release prod **à générer** (dette
  connue).

**Point traité ici (A4) :** `SUPABASE_ACCESS_TOKEN` (PAT MCP `sbp_…`) était présent
dans `.env`, lui-même **bundlé comme asset Flutter** (`pubspec.yaml`) → embarqué
dans l'APK. Le PAT n'est utilisé que par `.mcp.json` (qui le détient en propre).
Retiré du `.env` + `.env.example` durci. **⚠️ Régénérer le PAT** (Dashboard →
Account → Access Tokens) car il a été distribué dans les binaires précédents.

---

## 3. Edge Functions — 8/10 (axe approfondi)

### Posture
14 fonctions + `_shared`. Identité toujours dérivée du JWT (`getUser`) pour les
fonctions client-facing ; aucun secret en dur ; pattern « user-client pour
l'identité + service-role pour l'écriture avec re-filtrage manuel » cohérent.
TOTP exemplaire (comparaison constant-time, backup codes hashés HMAC-SHA256,
génération sans biais modulo, rate-limit partagé).

### Tableau

| Fonction | Auth | Appelant | Verdict |
|---|---|---|---|
| `register-admin` | code invitation (public) | client | 🟠→✅ rate-limit ajouté (A1) |
| `export-user-data` | JWT user | client | 🟡 detail leak |
| `setup-totp` / `verify-totp-setup` | JWT + rôle | client admin | 🟡 detail leak |
| `admin-verify-totp` / `admin-stepup-totp` | JWT + rôle + rate-limit | client admin | 🟢 |
| `get_agora_token` / `get-agora-call-token` | JWT + gate | client | 🟡 405 |
| `get-agora-rtm-token` | JWT | client | 🟢 |
| `dispatch_notification` | WEBHOOK_SECRET | trigger | 🟠→✅ constant-time (A3) |
| `moderate-chat-message` | WEBHOOK_SECRET | trigger | 🟠→✅ A3 + 🟡 ReDoS |
| `cleanup-deleted-accounts` / `cleanup-streams` | WEBHOOK_SECRET | cron | 🟠→✅ A3 |
| `send-transactional-email` | WEBHOOK_SECRET | trigger | 🟠→✅ A3 + 🟠 A2 (relais + test_plain) |

### Findings résiduels (non traités dans cette PR)
- **A2** — `WEBHOOK_SECRET` historiquement exposé en clair dans Git ; template
  `test_plain` de `send-transactional-email` = relais d'email depuis le domaine
  vérifié. → **Confirmer la rotation du secret** + retirer `test_plain` de la prod.
- **J-1** — fuite de `detail: …message` (erreurs Postgres/Resend) vers le client.
  → généraliser le pattern `ARENA_DEBUG` (log serveur, code stable client).
- **J-2** — CORS `*` sur routes admin/TOTP : acceptable en mobile (auth par
  header, pas cookie) ; restreindre si front web ajouté.
- **J-4** — `moderate-chat-message` : regex construite depuis `banned_words` sans
  timeout (ReDoS théorique, table super-admin only).

---

## 4. Architecture / Qualité Dart — 7.8/10

- `flutter analyze` : **0 issue dans `lib/`** (18 lints cosmétiques dans `test/`).
- 0 `print()`, 0 vrai TODO/FIXME, tous les `StreamSubscription` annulés, Riverpod
  sain, 0 route dupliquée.
- **🟠 12 fichiers god-file > 800 lignes** : `desktop_create_competition` (1187),
  `messages_inbox` (1074), `chat_page` (1030), `super_admin_broadcast` (978),
  `admin_bracket_management` (974)… → découper (modèle `match_room/widgets/`).
- **🟠 Duplication mobile ↔ desktop** (création compétition, broadcast) → mutualiser
  la logique dans des Notifiers `features_shared/`.
- **🟡** `desktop_chat_thread_page.dart:127` recrée un stream Realtime à chaque
  build → `StreamProvider`. `TextEditingController` non disposé
  (`super_admin_reintegration_requests.dart:281`). 157 casts `as` non-nullables
  sur JSON DB (fragiles aux migrations).

---

## 5. Conformité UI — ~95%

- **Typographie : 100%** (aucun `GoogleFonts`/`fontFamily` inline).
- **AppBar : 100%** en prod (3 `AppBar` bruts uniquement dans `lib/dev/`).
- **Couleurs : ~93%** — ~70 littéraux résiduels côté mobile (splash_screen 9×,
  payment_history 5×, live_streams 4×) à mapper sur `ArenaColors`.
- Desktop (Fluent UI) exempté (système propre).

---

## Correctifs appliqués dans cette PR

| # | Fix | Fichiers |
|---|---|---|
| **A1** | Rate-limit IP `register-admin` (5 échecs / 15 min → verrou 30 min) anti-énumération | `migrations/20260608120000_register_admin_rate_limit.sql`, `functions/register-admin/index.ts` |
| **A3** | Comparaison constant-time des bearers webhook (5 fonctions) + helper partagé | `functions/_shared/timing.ts`, `_shared/totp.ts` (DRY), `dispatch_notification`, `cleanup-*`, `moderate-chat-message`, `send-transactional-email` |
| **A4** | PAT Supabase retiré du `.env` bundlé ; `.env.example` durci | `.env.example` (+ `.env` local) |

**Déploiement requis (action user) :**
1. `supabase db push` (ou `apply_migration`) pour la migration A1.
2. Re-déployer les 6 Edge Functions modifiées.
3. **Régénérer le PAT Supabase** (A4) et **confirmer la rotation du `WEBHOOK_SECRET`** (A2).

## Suivi recommandé (hors PR)
1. A2 — purger `test_plain`, restreindre les destinataires de `send-transactional-email`.
2. J-1 — masquer les `detail` d'erreur côté client (pattern `ARENA_DEBUG`).
3. Découper les 4 plus gros écrans + mutualiser logique mobile/desktop.
4. Basculer le job OSV en bloquant ; pinner les GitHub Actions par SHA.
5. Générer le keystore release prod.
