# ARENA

Plateforme panafricaine de tournois e-sport mobile dédiée aux jeux de
football virtuel : **eFootball**, **FIFA Mobile**, **EA SPORTS FC Mobile**.

> Spécifications de référence : [`docs/ARENA_MASTER_PROMPT.md`](./docs/ARENA_MASTER_PROMPT.md)
> et [`docs/ARENA_FLUTTER_PROMPT.md`](./docs/ARENA_FLUTTER_PROMPT.md).
> Toute décision technique part de ces deux fichiers.

---

## Vue d'ensemble

ARENA est une **plateforme à 2 apps Flutter, 1 codebase** :

| App | Bundle ID | Cible | Distribution |
|---|---|---|---|
| **ARENA** (User) | `com.arena.app` | Joueurs | Play Store / App Store |
| **ARENA Admin** | `com.arena.admin` | Admins / super-admins | Sideload + web responsive |

Backend partagé sur **Supabase** (Postgres + Auth + Realtime + Storage +
Edge Functions + pg_cron). Stack temps réel : **Agora RTM** (présence /
typing du chat) + **Agora RTC** (streaming sélectif des finales et appels
audio 1v1 du chat). Notifications : **Firebase FCM** (push v1) + centre
in-app. Emails transactionnels : **Resend**.

**Paiements V1.0** : flux **P2P manuel** par mobile money (Orange Money /
MTN MoMo), validé un par un par un super-admin. L'intégration d'agrégateurs
automatiques (CinetPay, NowPayments) est reportée en V2.

Rollout progressif :

| Version | Région | Pays | Langues |
|---|---|---|---|
| **V1.0** | Afrique francophone | 13 pays | FR |
| **V1.1** | Afrique anglophone | +7 pays | EN |
| **V1.2** | Maghreb (RTL) | +4 pays | AR |

---

## État du projet

> Mis à jour le **2026-05-20**.
> **V1.0 fonctionnellement complète** — les 54 écrans sont livrés, les
> 14 Edge Functions déployées, le social V1 est en ligne. Le travail en
> cours porte sur le durcissement (audits de sécurité / perf), le polish
> du chat et la préparation du lancement.
>
> ⚠️ Les fonctionnalités **Agora RTC** — streaming live des finales et
> appels audio 1v1 du chat — n'ont jamais été validées en conditions
> réelles : le code est livré mais ces flux ne sont pas testés.

### ✅ Livré

| Domaine | Détail | Statut |
|---|---|---|
| **Fondations** | Setup, flavors `user`/`admin`, thème `ArenaColors`/`ArenaText`, 10 widgets partagés, i18n FR/EN/AR, feature flags | ✅ |
| **Auth** | Login / register / forgot-reset (OTP) / lier compte / CGU, deep link `com.arena.app://reset-password`, **Google SSO natif**, numéro WhatsApp requis | ✅ |
| **Auth admin** | Splash, login, onboarding par code d'invitation `ARENA-XXXX-XXXX-XXXX`, **TOTP** (Google Authenticator) avec backup codes | ✅ |
| **Compétitions** | Liste filtrable, détail 4 tabs, inscription + confirmation, bracket (single-elim / round-robin / groupes→KO), classements, modèle financier (frais, distribution Top 4) | ✅ |
| **Match Room** | Partage de code room, saisie collaborative du score, dispute, preuve image, forfait sur fenêtre de grâce | ✅ |
| **Chat** | 1v1 par match + canaux d'amis, médias, emoji, suppression style WhatsApp, badges non-lus, inbox (Direct / Compétitions / Amis) | ✅ |
| **Appels audio** | Appels 1v1 dans le chat via Agora RTC — code livré, **jamais testé end-to-end** | ⚠️ |
| **Anti-cheat** | Permissions natives, détection du jeu, enregistrement d'écran (overlay flottant), upload vers bucket privé, coordinateur forfait | ✅ |
| **Streaming** | Agora RTC sélectif sur les finales, auto-publication via triggers DB, compteur viewers temps réel — code livré, **jamais testé end-to-end** | ⚠️ |
| **Profil & RGPD** | Profil joueur + stats, édition, paramètres, suppression de compte (soft-delete), **export des données** (Edge Function) | ✅ |
| **Notifications** | FCM (trigger pg_net → Edge Function → FCM v1) + centre in-app, broadcast admin ciblé (5 filtres d'activité) | ✅ |
| **Espace admin** | 10 écrans (dashboard KPI, compétitions, matchs, bracket, payouts, disputes, modération streams, audit log) + 3 générateurs de bracket | ✅ |
| **Espace super-admin** | Dashboard live (MAU/DAU/marge), revenus + export CSV, gestion des codes d'invitation, gestion des utilisateurs (ban / KYC) | ✅ |
| **Paiements P2P** | Mobile money manuel Orange/MTN, validation 1×1 ou batch anti-erreur, historique paiements & gains, page KYC payout | ✅ |
| **Modération** | Règle 3-strikes (ban à vie au 3e verdict coupable), canal de réintégration « Arena Requête » (SLA 48h), filtre de mots bannis sur le chat | ✅ |
| **Social V1** | Système d'amis (`friendships` + RPC), profil public, recherche par username, blocages (RLS chat bloque les paires bloquées) | ✅ |
| **Parrainage** | Codes de parrainage, gating d'inscription, règle « tout invité actif compte » | ✅ |

### 🔧 Backend déployé

- **65 migrations SQL** — schéma Postgres complet, RLS sur toutes les
  tables, triggers (auto-bracket, auto-finals, FCM dispatch, emails,
  stats, modération chat, 3-strikes), index, publication Realtime.
- **14 Edge Functions** déployées :
  - `get_agora_token`, `get-agora-rtm-token` — tokens streaming / chat
  - `get-agora-call-token` — token RTC des appels audio 1v1 (chat)
  - `setup-totp`, `verify-totp-setup`, `admin-stepup-totp`, `admin-verify-totp` — TOTP admin
  - `register-admin` — onboarding admin par code d'invitation
  - `dispatch_notification` — push FCM v1
  - `send-transactional-email` — dispatcher Resend
  - `moderate-chat-message` — filtre de mots bannis + log anti-cheat
  - `export-user-data` — droit RGPD à la portabilité
  - `cleanup-deleted-accounts` — cron RGPD (hard-delete à J+30)
  - `cleanup-streams` — cron horaire (streams périmés + storage 30j)
- **2 crons pg_cron** : `cleanup-deleted-accounts` (03:15 quotidien) et
  `cleanup-streams` (horaire).

### 🛡️ Durcissement (en cours)

Plusieurs vagues d'audit sécurité / perf ont été passées :

- ACL des RPC `SECURITY DEFINER` (REVOKE anon ciblé), consolidation des
  policies RLS PERMISSIVE/RESTRICTIVE, `search_path` immuable.
- Préparation au scaling ~1M users : refresh JWT propagé au client
  Realtime, bornes sur les requêtes, `autoDispose` sur les providers,
  dégradation Realtime → polling sur les écrans non-critiques.
- Observabilité Sentry (traces custom sur les chemins critiques).
- CI durcie : `flutter analyze` à 0 issue, codecov, Dependabot.

Le suivi détaillé est dans [`docs/AUDIT_FOLLOWUP.md`](./docs/AUDIT_FOLLOWUP.md).

### ⏭️ Reste avant le lancement V1.0

| Sujet | Note |
|---|---|
| **Tests sur device physique** | Android avec un jeu installé — l'émulateur ne reproduit pas `MEDIA_PROJECTION` / `SYSTEM_ALERT_WINDOW`. |
| **Validation des flux Agora RTC** | Le streaming live (diffusion d'une finale + visionnage spectateur) et les appels audio 1v1 du chat n'ont jamais été testés en conditions réelles. À valider avant le lancement. |
| **Keystore release Android** | Infra de signature prête ; le keystore reste à générer côté équipe (sa perte = perte de l'identité Play Store). |
| **Tests d'intégration** | `integration_test/` encore vide — le golden path est couvert par les widget tests. |
| **Documents légaux** | CGU, Privacy Policy, mentions par pays (voir « Conformité légale »). |

### 📦 Reporté en V2

- **Apple SSO** (`sign_in_with_apple`) et **iOS Live Activity / Dynamic
  Island** (`live_activities`) — requièrent un compte Apple Developer actif.
- **Paiements automatiques** : intégration CinetPay (MoMo) et NowPayments
  (crypto) en remplacement du flux P2P manuel.
- Pagination des endpoints admin et dégradation Realtime supplémentaire
  (à activer avec la traction réelle).

---

## Architecture

```
lib/
├── main_user.dart           # Entry point app User
├── main_admin.dart          # Entry point app Admin
│
├── core/                    # 🔧 SHARED — theme, router, services, i18n, flavors, utils
├── data/                    # 🔧 SHARED — modèles freezed + repositories
├── features_shared/         # 🔧 SHARED — widgets & pages communes
├── features_user/           # 📱 USER — auth, onboarding, home, competitions,
│                            #   bracket, match_room, chat, recording, streaming,
│                            #   payments, payouts, profile, notifications
├── features_admin/          # 🛡️ ADMIN — auth_admin, dashboard, competitions_admin,
│                            #   matches_admin, bracket_admin, disputes_admin,
│                            #   payouts_admin, streams_admin, audit, super_admin
└── l10n/generated/          # ARB compilés (FR / EN / AR)

supabase/
├── migrations/              # 65 migrations SQL (schéma, RLS, triggers, index, crons)
├── seeds/                   # Fixtures dev (dev_phase5_match_room.sql, dev_super_admin.sql)
└── functions/               # 14 Edge Functions Deno + dossier _shared
```

Convention de nommage et stack technique imposée :
voir [`docs/ARENA_MASTER_PROMPT.md`](./docs/ARENA_MASTER_PROMPT.md) — section
« Architecture technique complète ».

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

**182 tests** couvrent les modèles freezed, les widgets partagés, les
services i18n, le router (redirects onboarding → splash → home / gates
CGU & ban), les pages auth, le shell joueur, les compétitions, le
bracket, le chat, l'anti-cheat (machine d'état recording, coordinateur
forfait, overlay, détecteur de jeu, streaming Agora), les stats joueur
et les helpers neufs (mapping d'erreurs, `pollStream`, wizard de
compétition). `test/golden_path_test.dart` couvre les routes principales.

Le dossier `integration_test/` est encore vide — les tests sur device
physique (Android + jeu installé) restent obligatoires avant V1.0.

---

## Lints

```bash
flutter analyze   # 0 issue
```

Règles via `very_good_analysis` (`analysis_options.yaml`). Un script de
garde `scripts/check_colors.{sh,ps1}` interdit les couleurs hardcodées
hors allowlist. `custom_lint` + `riverpod_lint` désactivés temporairement
(incompatibilité analyzer 7.x).

---

## CI

GitHub Actions vert sur PR / push `main` : `flutter analyze` + `flutter
test` (+ coverage codecov) + `build_runner` + garde-fous couleurs /
espacement. Dependabot actif (pub hebdo, github-actions hebdo, gradle
mensuel).

---

## Workflow Claude Code

Ce projet est piloté avec **Claude Code** comme assistant. Les règles
non-négociables :

1. Avant de coder une phase, lire la section correspondante de
   `docs/ARENA_MASTER_PROMPT.md`.
2. Pas de substitution de libs — la stack est imposée (cf. master).
3. Code commenté en anglais, échanges en français.
4. Validation phase par phase, sous-étapes courtes, demande de tests
   après chaque sous-étape.
5. Si doute sur une API : `web_search` plutôt qu'inventer.

Voir le master prompt section « Workflow Claude Code + Cursor » pour le
détail des prompts à copier-coller.

---

## Conformité légale

ARENA n'est pas un jeu d'argent au sens strict (compétences, pas de
hasard) mais collecte des frais d'inscription et redistribue des gains.
Documents à préparer avant lancement V1.0 (Cameroun + 12 pays
francophones) :

- CGU + Privacy Policy (FR)
- Conformité RGPD — suppression de compte et export des données déjà
  implémentés côté app (Edge Function `export-user-data` + cron
  `cleanup-deleted-accounts`)
- Mentions légales par pays
- Régime fiscal (commission 12-15% imposable)

Détails dans `docs/ARENA_MASTER_PROMPT.md` — partie « Conformité légale ».

---

## Liens internes

- [`docs/ARENA_MASTER_PROMPT.md`](./docs/ARENA_MASTER_PROMPT.md) — vision, architecture, roadmap, 54 écrans, 21 phases
- [`docs/ARENA_FLUTTER_PROMPT.md`](./docs/ARENA_FLUTTER_PROMPT.md) — détails techniques, SQL complet, Edge Functions, Freezed, RLS
- [`docs/AUDIT_FOLLOWUP.md`](./docs/AUDIT_FOLLOWUP.md) — checklist de durcissement sécurité / perf
- [`docs/ARENA_54_ECRANS.md`](./docs/ARENA_54_ECRANS.md) — inventaire des écrans
