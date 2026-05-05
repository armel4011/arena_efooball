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

> Mis à jour le 2026-05-06 — phase 2 (auth user) terminée.

### ✅ Phases terminées

| Phase | Domaine | Statut |
|---|---|---|
| **0** | Setup + flavors `user`/`admin` + bootstrap | ✅ |
| **0.5** | Onboarding 4 slides (`onboarding_page/slide/gate`) | ✅ |
| **1** | Theme (`arena_colors/theme/typography`) + 7 widgets partagés | ✅ |
| **1bis** | i18n FR/EN/AR + currency + feature flags | ✅ |
| **0 backend** | 26 tables Supabase + RLS + indexes + seed config V1.0 | ✅ |
| **2** | Auth user (login, register, forgot/reset, link, CGU) + deep link `com.arena.app://reset-password` | ✅ |

> SSO Google/Apple reportés en **PHASE 2.3** (libs `google_sign_in` /
> `sign_in_with_apple` commentées dans `pubspec.yaml`). La page
> `LinkExistingAccountPage` est wired mais inerte jusque-là.

### ⏭️ Phases à venir

| Phase | Domaine | Estimation |
|---|---|---|
| **2bis** | Auth admin (splash, login, invitation, TOTP setup/verify) | 4-5h |
| **3** | Layout + HomePage joueur | 1-2h |
| **4** | Compétitions (liste + détail + bracket) | 3-4h |
| **5** | Match Room (code → config → score → validation) | 2-3h |
| **6** | Chat hybride (Supabase Realtime + Agora RTM) | 3-4h |
| **8** | Anti-cheat (recording + bouton flottant) + streaming Agora | 6-7h |
| **9** | Profil + settings + suppression compte (RGPD) | 3h |
| **10** | Notifications push (FCM) | 2h |
| **11** | Espace admin (dashboard, comp, matchs, bracket, disputes) | 4-5h |
| **11bis** | Paiements CinetPay + NowPayments + payouts | 5-6h |
| **12** | Espace super-admin | 2h |
| **12.5** | Edge Functions (16) + pg_cron + automatisation | 10-12h |
| **13** | Polish + tests + lancement V1.0 | 5-6h |

**Total V1.0 restant** : ~45h. Voir le master prompt section "ROADMAP" pour le détail.

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
├── migrations/              # 6 migrations SQL (26 tables, RLS, indexes)
└── functions/               # Edge Functions (à venir Phase 12.5)
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

Couverture actuelle (51 tests) : modèles freezed, widgets partagés,
services i18n, router redirect (onboarding → splash → home), et les
4 pages auth de la phase 2 (`forgot/reset/link/cgu`). Auth admin (TOTP,
invitation) à couvrir en phase 2bis.

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
