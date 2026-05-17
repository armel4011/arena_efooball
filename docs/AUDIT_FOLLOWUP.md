# Audit follow-up — checklist 2026-05-17

Restant après la session d'audit du 2026-05-17 (commits `d0e43ea` → `482ea83`).
Cocher au fil de l'avancement.

## P0 — action manuelle bloquante

- [ ] **Activer Leaked Password Protection** (Supabase Auth)
  - Dashboard : https://supabase.com/dashboard/project/mamfuexzadeejtjrtzrq/auth/policies
  - Section *Password Strength* → cocher *Prevent use of leaked passwords*
  - Pas exposé via MCP, ~30 s manuel.
  - Doc : https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection

## P1 — chantiers > 1 session

### Refacto fichiers monstres
Découpage en widgets / sous-pages, pas un refactor mécanique.

- [ ] `lib/features_user/match_room/match_room_page.dart` — **1602 lignes** (déjà 2038→1602, cf. memory `refactor_progress`)
- [x] `lib/features_user/home/home_page.dart` — 961 → **96** lignes (2026-05-17, commit `<pending>`). Découpé en 7 widgets sous `home/widgets/` : `home_header`, `pending_payment_banner`, `upcoming_matches_section`, `live_streams_section`, `active_competitions_section`, `stat_grid`, `home_error_row` (partagé). Aucun fichier extrait > 230 lignes.
- [ ] `lib/features_admin/competitions_admin/admin_competition_detail_page.dart` — 907 lignes
- [x] `lib/features_user/competitions/competitions_list_page.dart` — 842 → **226** lignes (2026-05-17, commit `<pending>`). Découpé en 4 widgets sous `competitions/widgets/` : `competition_filter_chips` (enums + 3 chip rows), `free_competition_card`, `paid_competition_card`, `competition_list_card` (dispatcher).

### 21 issues `flutter analyze` restantes
Toutes manuelles (non couvertes par `dart fix`). Listées par règle :

- [ ] `use_build_context_synchronously` — `lib/features_user/payments/payment_processing_page.dart:217`
  (critique : payment flow, vérifier `if (!mounted)` autour de la nav)
- [ ] `cascade_invocations` (~4 occurrences) — `payment_processing_page.dart:91`, `edit_profile_page.dart:74`, `match_recording_lifecycle.dart:207`, etc.
- [ ] `comment_references` — `lib/features_user/onboarding/onboarding_slide.dart:4`
- [ ] Reste : voir `flutter analyze --no-pub --no-fatal-infos` pour la liste à jour

## P2 — hygiène diffuse

### Couleurs hardcodées résiduelles
Audit ciblé après commit `482ea83` : la majorité des `Colors.white|black` restants sont justifiés (contraste sur gradient, overlay scrim semi-transparent, brand externe). Seuls **2 FIX directs** et **~5 EXTEND** (palette à enrichir) sont de vrais TODO.

**Décision préalable à prendre :**
- [ ] **Option A** — lint custom qui interdit `Color(0xFF…)` / `Colors.xxx` hors `lib/core/theme/` (réactivation `custom_lint` quand analyzer 7.7+ disponible).
- [ ] **Option B** — passe manuelle fichier par fichier après enrichissement palette.

**FIX immédiat (tokens déjà disponibles) :**
- [x] `lib/features_shared/widgets/arena_phone_frame.dart:22` — `Color(0xFF1A1A22)` → `ArenaColors.carbon2` (commit `69011db`).
- [x] `lib/features_user/profile/avatar_palette.dart:33,35` — `Color(0xFF4C7AFF)` → `ArenaColors.signalBlue` (commit `69011db`).

**EXTEND `ArenaColors` (tokens ajoutés + usages remplacés) :**
- [x] **Gold premium** — tokens `tierGold` (#FFD700, super-admin), `tierGoldWarm` (#FFC93C, competition card), `tierGoldDeep` (#CB9A1F, gradient compagnon). Appliqué à `competitions_list_page.dart:602-603`, `super_admin_dashboard.dart:18`, `super_admin_invitations.dart:33,217`.
- [x] **Brand mobile money** — tokens `brandMtnMomo` (#FFA500), `brandOrangeMoney` (#FF6B00). Appliqué à `payment_method.dart:16,24` et `payment_history_page.dart:245`.
- [x] **Status variants** — tokens `statusOkDeep` (#00A878), `statusDangerDeep` (#8B0020). Appliqué aux gradients de `payment_success_page.dart:138` et `payment_failed_page.dart:190`.
- [x] **Stream moderation gradients** — tokens `streamSlot1..4Gradient` (blue/green/orange/purple). Appliqué à `admin_stream_moderation_page.dart:24-29`.

**KEEP (pas un TODO)** — `arena_avatar.dart`, `arena_badge.dart`, `arena_banner.dart`, `arena_button.dart`, `arena_dialog.dart`, `arena_glass_card.dart`, `admin_bracket_management_page.dart`, `admin_competition_detail_page.dart`, `totp_setup_screen.dart`, `chat_page.dart`, `competition_detail_page.dart`, `edit_profile_page.dart`, `friends_page.dart`, `friends_search_page.dart`, `main_layout.dart`, `payment_method_picker_page.dart`, `player_profile_page.dart`, `public_profile_page.dart`, `recording_overlay.dart`, `google_sign_in_button.dart` (brand Google).
Raisons : `Colors.white` sur gradient pour contraste, `Colors.black.withValues(alpha:…)` overlay scrim, hairlines `Colors.white.withValues(alpha: 0.06)`, ou brand externe protégé.

### TextStyle inline (51 occurrences)
- [ ] Inventaire complet avec `Grep "TextStyle("` hors `lib/core/theme/`
- [ ] Mapper chaque occurrence sur `ArenaText.*` (potentiellement enrichir `ArenaText` avec les variantes manquantes)

### Gestion d'erreurs faiblement typée
- [ ] **82 % des `catch` sont génériques** (84/102). Les bons patterns existent dans `auth_repository.dart` et `admin_auth_providers.dart` (`on PostgrestException`, `on SocketException`, `on AuthException`, `on FunctionException`).
- [ ] Propager le typage dans les repositories restants : `chat_repository`, `match_repository`, `notification_repository`, `payment_repository`, `friends_repository`, `standings_repository`, `reintegration_requests_repository`, `competition_repository`, `profile_repository`, `export_user_data_repository`, repos admin.
- [ ] Décider : conserver le `catch (e)` final comme filet de sécurité avec `Sentry.captureException` ou re-throw ?

## INFO — quick wins SQL

### Indexes inutilisés (advisor performance INFO)

**Audit du 2026-05-17** : les 26 indexes flaggés ne sont pas du débris. L'app est en V1 fraîche (4-6 rows par table), donc le planner Postgres préfère `seq_scan` — les indexes ne sont pas sollicités mais leur design est sain. Le seul **vrai débris** trouvé est l'index obsolète remplacé par la migration Phase 12.5.

- [x] **`idx_invitation_codes_unused`** — drop le 2026-05-17, migration `20260517110005`. Indexait `(code) WHERE used_at IS NULL` ; la sémantique a été refactorée vers `uses_count`/`max_uses` dans `20260516100001`, le successeur `invitation_codes_code_active_idx` reste.

**À conserver pour l'instant (defensive / V2-deferred) :** les 25 indexes restants. Coût total ~290 KB. Revoir après ~1 mois de traction réelle :
- Reset les stats : `SELECT pg_stat_reset();`
- Attendre une fenêtre représentative (4 semaines + données réelles)
- Re-mesurer via `pg_stat_user_indexes` et l'advisor MCP

Détail des 25 conservés (18 defensive, 6 V2-deferred, 1 historique trace) :
- **Defensive (deviendront utiles à la traction)** : `idx_profiles_country`, `idx_profiles_deleted`, `idx_profiles_permanent_ban`, `idx_competitions_dates`, `idx_competitions_game`, `idx_matches_status`, `idx_matches_streamed_live`, `idx_matches_group`, `idx_matches_home_player`, `idx_matches_winner`, `idx_matches_streaming_admin`, `idx_bracket_nodes_parent`, `idx_bracket_nodes_next_node`, `idx_streams_active_public`, `idx_match_events_created_by`, `idx_banned_words_language`, `idx_reintegration_status_created`, `idx_auto_actions_function`.
- **V2-deferred (feature pas encore active)** : `idx_payouts_admin_validation`, `idx_exchange_rates_pair`, `idx_payments_provider_tx`, `idx_payments_validated_at`, `idx_webhook_log_provider`, `idx_memberships_group`.
- **Audit trail** : `invitation_codes_code_active_idx` (Phase 12.5, conservé).

### FK non indexées (2 — advisor performance INFO)
- [x] `friendships.blocked_by_fkey` → `idx_friendships_blocked_by` partiel (WHERE blocked_by IS NOT NULL) — migration `20260517110006`.
- [x] `reintegration_requests.resolved_by_fkey` → `idx_reintegration_resolved_by` partiel (WHERE resolved_by IS NOT NULL) — migration `20260517110006`.

## CI & qualité

- [ ] **0 test d'intégration** — créer `integration_test/` avec au moins le golden path (login → home → join competition → match flow). Cible de couverture : 50 %.
- [ ] **Pas de codecov dans CI** — ajouter step `flutter test --coverage` + upload codecov dans `.github/workflows/ci.yml`.
- [ ] **`custom_lint` / `riverpod_lint` désactivés** — surveiller la sortie d'analyzer 7.7+ pour réactiver (cf. `analysis_options.yaml`).
- [x] **15 `authenticated_security_definer_function_executable` (WARN)** — par design (RPC user-actionnable, checks internes en place). `COMMENT ON FUNCTION` ajouté à chacune avec intent + autorisation interne (migration `20260517110007`). L'advisor restera WARN ; les commentaires servent à un futur reviewer humain. (Le compte est passé de 17 à 15 entre-temps : `delete_competition_cascade` n'était plus comptée 2× par l'advisor après le REVOKE anon de `20260517110003`.)

## Notes pour la prochaine session

- `chat_messages_no_blocked_pair` est passé en `RESTRICTIVE` dans `20260517110004` — **fix de bug** (auparavant en PERMISSIVE, la policy n'avait aucun effet à cause du OR Postgres). À garder en tête pour toute future policy `no_xxx` / `deny_xxx` : doit être `RESTRICTIVE`.
- Les migrations RLS A-D ont éliminé 50 `multiple_permissive_policies`, 2 `auth_rls_initplan`, 1 `anon_security_definer`. Le schéma `public` n'a plus aucun warning perf actif.
- Aucun secret côté client (`SERVICE_ROLE_KEY`, `RESEND_API_KEY` introuvables dans `lib/`).
- iOS deployment target = 13.0 (EOL Apple 2023) — bump à 14+ à considérer.
- `firebase_options.dart` absent côté Flutter (init Firebase par `google-services.json` seul, Android-only OK ; pour iOS lancer `flutterfire configure`).
