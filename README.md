# ARENA

Plateforme panafricaine de tournois e-sport mobile dédiée aux jeux de
football virtuel : **eFootball**, **FIFA Mobile**, **EA SPORTS FC Mobile**.

> Spécifications de référence : [`ARENA_MASTER_PROMPT.md`](./ARENA_MASTER_PROMPT.md)
> et [`ARENA_FLUTTER_PROMPT.md`](./ARENA_FLUTTER_PROMPT.md).
> Toute décision technique part de ces deux fichiers.

---

## Vue d'ensemble

ARENA est une **plateforme à 2 apps Flutter, 1 codebase** :

| App | Bundle ID | Cible | Distribution |
|---|---|---|---|
| **ARENA** (User) | `com.arena.app` | Joueurs | Play Store / App Store |
| **ARENA Admin** | `com.arena.admin` | Admins / super-admins | Sideload + web responsive |

Backend partagé sur **Supabase** (Postgres + Auth + Realtime + Storage +
Edge Functions). Stack temps réel : Agora RTM (présence chat) + Agora RTC
(streaming finales sélectif). Paiements : CinetPay (MoMo), NowPayments
(crypto), Flutterwave (V1.1 anglophone).

Rollout progressif :

| Version | Région | Pays | Langues |
|---|---|---|---|
| **V1.0** | Afrique francophone | 13 pays | FR |
| **V1.1** | Afrique anglophone | +7 pays | EN |
| **V1.2** | Maghreb (RTL) | +4 pays | AR |

---

## État du projet

> Mis à jour le 2026-05-07 — phase 8 (anti-cheat recording + streaming Agora sélectif + auto-finals) terminée.

### ✅ Phases terminées

| Phase | Domaine | Statut |
|---|---|---|
| **0** | Setup + flavors `user`/`admin` + bootstrap | ✅ |
| **0.5** | Onboarding 4 slides (`onboarding_page/slide/gate`) | ✅ |
| **1** | Theme (`arena_colors/theme/typography`) + 7 widgets partagés | ✅ |
| **1bis** | i18n FR/EN/AR + currency + feature flags | ✅ |
| **0 backend** | 26 tables Supabase + RLS + indexes + seed config V1.0 | ✅ |
| **2** | Auth user (login, register, forgot/reset, link, CGU) + deep link `com.arena.app://reset-password` | ✅ |
| **2bis** | Auth admin (splash, login, invitation, TOTP setup/verify) — Flutter only, 4 Edge Functions différées en 12.5 | ✅ |
| **3** | Layout joueur (`MainLayout` + 4 tabs avec `IndexedStack`) + HomePage (header, sections phase-aware, stats depuis `profile.stats`, pull-to-refresh) | ✅ |
| **4** | Compétitions : modèles freezed (`Competition`, `ArenaMatch`, `Standings*`), repos Supabase, `CompetitionsListPage` filtrable, `CompetitionDetailPage` (4 tabs, CTA inscription), `BracketView` (matches par round) et `GroupStandingsView` (DataTable) | ✅ |
| **5** | Match Room (`MatchRoomPage` + route `/match/:id`) : 5.B nav depuis bracket, 5.C partage de code room (claim home seat) + clipboard, 5.D saisie collaborative du score (stream `match_events` + auto-commit/dispute). Migration RLS `20260506200001` qui autorise les joueurs participants à updater leur match en attendant les Edge Functions (12.5). | ✅ |
| **6** | Chat 1-on-1 par match : `ChatPage` + route `/chat/match/:id`, `ChatRepository` (`ensureMatchChannel`, `watchMessages`, `sendMessage`), bubbles WhatsApp-style (newest en bas, self à droite). Migration RLS `20260506200002` (player INSERT du channel + `chat_channels`/`chat_messages` ajoutés à la publication realtime). Agora RTM (présence/typing) reporté en 12.5. | ✅ |
| **8** | Anti-cheat + streaming Agora sélectif. **8.1** permissions natives (`permissions_service`) + manifest Android/iOS étendus. **8.2** `game_detector_service` (eFootball / EA FC, polling 2s via `installed_apps` + `app_usage`). **8.3** `recording_service` (auto-stop 25 min) + `recording_uploader` + `manual_video_upload_service` vers bucket privé `match-recordings/{matchId}/{playerId}/...mp4` (cap 500 MB). **8.4** overlay isolate (`flutter_overlay_window`) — bouton 72dp rouge, timer MM:SS, drag-to-side, IPC typé, tap court = MainActivity.bringMainActivityToFront() (Kotlin MethodChannel), tap long = 3 actions. **8.5** `match_recording_coordinator` orchestre la grace window (2 min) → `markForfeit()` (status=forfeited, winner_id=opponent, event logged). **8.7** streaming Agora sélectif : `agora_streaming_service` + `agora_token_client` + Edge Function `get_agora_token` (déployée — App Certificate jamais sur le client), `LiveStreamsPage` + `WatchStreamPage` + `StartStreamingBanner`, compteur viewers temps réel via Supabase Realtime presence. Auto-finals : trigger DB `auto_publish_final_match` (status→ongoing × `bracket_nodes.is_grand_final` ⇒ `is_streamed`/`auto_final` + flip `streams.is_public` HOME), trigger catch-up `auto_publish_late_stream` sur INSERT. Migrations `20260507100001` (storage bucket + 5 RLS), `20260507100002` (streams player RLS), `20260507100003` (auto-finals triggers). | ✅ |

> **SSO Google/Apple** reportés en **PHASE 2.3** (libs `google_sign_in` /
> `sign_in_with_apple` commentées dans `pubspec.yaml`). La page
> `LinkExistingAccountPage` est wired mais inerte jusque-là.
>
> **Edge Functions admin** différées en **PHASE 12.5** :
> `register-admin`, `setup-totp`, `verify-totp-setup`, `admin-verify-totp`.
> Sans elles, l'invitation et le TOTP affichent un message "feature
> pending" via `BackendUnavailableFailure`.
>
> **Phase 4 / 5 — dettes assumées** : les tabs *Participants* et *Prix*
> du détail compétition affichent encore un placeholder, et le bracket /
> classement / match-room affichent les joueurs sous forme
> `Joueur abc123…`. La jointure `profiles` (nom + avatar) est reportée
> à la phase 13 (polish). Le bracket reste sur `FutureProvider` +
> pull-to-refresh + invalidation au retour de la match-room (le
> `StreamProvider` triggerait un ANR sur émulateur Android x86 vu les
> 3 channels Realtime simultanés). Un seed dev
> `supabase/seeds/dev_phase5_match_room.sql` crée 2 comptes test et
> 7 matches couvrant chaque écran phase 5.
>
> **Phase 8 — dettes assumées** : (a) **8.6 iOS Live Activity** reportée
> en **PHASE 8b** (lib `live_activities` commentée — requiert un compte
> Apple Developer pour signer le widget Dynamic Island). (b) **Compteur
> viewers DB-side** : les colonnes `matches.current_viewers_count` /
> `peak_viewers_count` restent à 0 ; la projection admin sera mise à
> jour par une Edge Function en **PHASE 12.5**. Côté joueur, le compteur
> live affiché sur `WatchStreamPage` vient de Supabase Realtime presence,
> donc fonctionne sans dépendre de cette projection. (c) **Notification
> HOME quand son match est sélectionné** reportée en **PHASE 10** (FCM).
> (d) Tests sur device physique (Android avec eFootball installé)
> obligatoires avant V1.0 — l'émulateur ne reproduit pas les permissions
> MEDIA_PROJECTION / SYSTEM_ALERT_WINDOW à l'identique.

### ⏭️ Phases à venir

| Phase | Domaine | Estimation |
|---|---|---|
| **8b** | iOS Live Activity (Dynamic Island) — Apple Dev requis | 1h |
| **9** | Profil + settings + suppression compte (RGPD) | 3h |
| **10** | Notifications push (FCM) — inclut notif HOME "ton match est en live" | 2h |
| **11** | Espace admin (dashboard, comp, matchs, bracket, disputes) | 4-5h |
| **11bis** | Paiements CinetPay + NowPayments + payouts | 5-6h |
| **12** | Espace super-admin | 2h |
| **12.5** | Edge Functions (16) + pg_cron + automatisation | 10-12h |
| **13** | Polish + tests + lancement V1.0 | 5-6h |

**Total V1.0 restant** : ~22h (incluant 4 Edge Functions admin reportées en 12.5, les 4 Edge Functions match-room que la phase 5 contourne via RLS dev, `moderate_chat_message` que la phase 6 contourne aussi, et la projection viewers count que la phase 8.7 contourne via presence). Voir le master prompt section "ROADMAP" pour le détail.

---

## Architecture

```
lib/
├── main_user.dart           # Entry point app User
├── main_admin.dart          # Entry point app Admin
│
├── core/                    # 🔧 SHARED (theme, router, services, i18n, flavors)
├── data/                    # 🔧 SHARED (modèles freezed + repositories)
├── features_shared/         # 🔧 SHARED (widgets, pages communes)
├── features_user/           # 📱 USER ONLY (28 écrans)
├── features_admin/          # 🛡️ ADMIN ONLY (19 écrans)
└── l10n/generated/          # ARB compilés (FR / EN / AR)

supabase/
├── migrations/              # 13 migrations SQL (26 tables, RLS, indexes, phase-5/6 player-write RLS + realtime publication, phase-8 storage bucket + streams RLS + auto-finals triggers)
├── seeds/                   # Dev fixtures (ex. dev_phase5_match_room.sql)
└── functions/               # Edge Functions (1 déployée — `get_agora_token` ; les 16 autres en Phase 12.5)
```

Convention de nommage et stack technique imposée :
voir [`ARENA_MASTER_PROMPT.md`](./ARENA_MASTER_PROMPT.md) — section
"Architecture technique complète".

---

## Setup local

### Pré-requis

- Flutter SDK ≥ 3.24, Dart ≥ 3.5
- Android Studio (SDK Android API 23+)
- Xcode 15+ (si build iOS, macOS uniquement)
- Compte Supabase (URL + anon key)

### Installation

```bash
# 1. Récupérer les dépendances
flutter pub get

# 2. Copier le template d'environnement
cp .env.example .env
# → renseigner SUPABASE_URL, SUPABASE_ANON_KEY, AGORA_APP_ID, etc.

# 3. Générer les fichiers freezed/json + l10n
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n

# 4. Appliquer les migrations Supabase
# (via supabase CLI ou MCP supabase tools)
```

### Lancer l'app

```bash
# App utilisateur (joueur)
flutter run --flavor user --target lib/main_user.dart

# App admin
flutter run --flavor admin --target lib/main_admin.dart
```

### Build release

```bash
flutter build apk --flavor user  --target lib/main_user.dart  --release
flutter build apk --flavor admin --target lib/main_admin.dart --release
```

VS Code / Cursor : configurations `Run user` et `Run admin` disponibles
dans `.vscode/launch.json` (à créer si absent).

---

## Tests

```bash
# Tests unitaires + widgets
flutter test

# Tests d'intégration (émulateur requis)
flutter test integration_test
```

Couverture actuelle (143 tests) : modèles freezed, widgets partagés,
services i18n, router redirect (onboarding → splash → home), 4 pages
auth user (`forgot/reset/link/cgu`), 4 écrans admin
(`login/invitation/totp_setup/totp_verify`), shell joueur phase 3
(`MainLayout` + `HomePage`), phase 4 (`CompetitionsListPage` filtre +
cards, `CompetitionDetailPage` tabs + CTA, `BracketView` groupage par
round, `GroupStandingsView` DataTable), phase 6 (`ChatPage`), et phase
8 (recording state machine, coordinator pause/forfeit grace,
overlay controller IPC, manual upload, game detector, agora streaming
state machine, permissions service). Le happy-path complet d'invitation
admin sera couvert via test d'intégration une fois l'Edge Function
`register-admin` livrée (PHASE 12.5). Tests sur device physique
(Android + jeu installé) obligatoires en phase 13 avant lancement.

---

## Lints

```bash
flutter analyze
```

Règles via `very_good_analysis` (`analysis_options.yaml`). `custom_lint`
+ `riverpod_lint` désactivés temporairement (incompatibilité analyzer 7.x).

---

## Workflow Claude Code

Ce projet est piloté avec **Claude Code** comme assistant. Les règles
non-négociables :

1. Avant de coder une phase, lire la section correspondante de
   `ARENA_MASTER_PROMPT.md`.
2. Pas de substitution de libs — la stack est imposée (cf. master).
3. Code commenté en anglais, échanges en français.
4. Validation phase par phase, sous-étapes courtes, demande de tests
   après chaque sous-étape.
5. Si doute sur une API : `web_search` plutôt qu'inventer.

Voir le master prompt section "Workflow Claude Code + Cursor" pour le
détail des prompts à copier-coller.

---

## Conformité légale

ARENA n'est pas un jeu d'argent au sens strict (compétences, pas de
hasard) mais collecte des frais d'inscription et redistribue des gains.
Documents à préparer avant lancement V1.0 (Cameroun + 12 pays
francophones) :

- CGU + Privacy Policy (FR)
- Conformité RGPD (suppression compte, export données)
- Mentions légales par pays
- Régime fiscal (commission 12-15% imposable)

Détails dans `ARENA_MASTER_PROMPT.md` — partie "Conformité légale".

---

## Liens internes

- [`ARENA_MASTER_PROMPT.md`](./ARENA_MASTER_PROMPT.md) — vision, architecture, roadmap, 47 écrans, 21 phases
- [`ARENA_FLUTTER_PROMPT.md`](./ARENA_FLUTTER_PROMPT.md) — détails techniques, SQL complet, Edge Functions, Freezed, RLS
