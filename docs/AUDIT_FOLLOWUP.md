# Audit follow-up — checklist 2026-05-17

Restant après la session d'audit du 2026-05-17 (commits `d0e43ea` → `482ea83`).
Cocher au fil de l'avancement.

## P0 — action manuelle bloquante

- [x] **Activer Leaked Password Protection** (Supabase Auth) — activé manuellement par le user le 2026-05-17. Advisor `auth_leaked_password_protection` ne flagge plus le projet ; tous les nouveaux mots de passe sont désormais vérifiés contre HaveIBeenPwned côté Auth.

## P1 — chantiers > 1 session

### Refacto fichiers monstres
Découpage en widgets / sous-pages, pas un refactor mécanique.

- [x] `lib/features_user/match_room/match_room_page.dart` — 2038 → 1602 → **170** lignes (2026-05-17, commit `<pending>`). Découpé en 9 nouveaux fichiers : `match_room_providers` (3 providers + `MatchPlayers`), `widgets/match_step_indicator`, `widgets/cyan_dashed_container`, `widgets/forfeit_timer_card`, `widgets/open_chat_link`, `widgets/match_players_header`, `widgets/share_code_form`, `widgets/room_ready_view`, `widgets/score_flow_view`, `widgets/match_step_body`. Page restante : `MatchRoomPage` + `MatchRole` enum + `_MatchRoomBody`. Score flow view reste à 576 lignes (formulaire dense + preuve d'image, cohérent).
- [x] `lib/features_user/home/home_page.dart` — 961 → **96** lignes (2026-05-17, commit `<pending>`). Découpé en 7 widgets sous `home/widgets/` : `home_header`, `pending_payment_banner`, `upcoming_matches_section`, `live_streams_section`, `active_competitions_section`, `stat_grid`, `home_error_row` (partagé). Aucun fichier extrait > 230 lignes.
- [x] `lib/features_admin/competitions_admin/admin_competition_detail_page.dart` — 907 → **94** lignes (2026-05-17, commit `<pending>`). Découpé en 6 widgets sous `competitions_admin/widgets/` : `admin_competition_header`, `admin_competition_infos_tab`, `admin_competition_registrants_tab` (exporte `registrantAvatarColor`), `admin_competition_matches_tab`, `admin_competition_ranking_tab`, `admin_competition_actions_tab`. 1 fichier = 1 onglet.
- [x] `lib/features_user/competitions/competitions_list_page.dart` — 842 → **226** lignes (2026-05-17, commit `<pending>`). Découpé en 4 widgets sous `competitions/widgets/` : `competition_filter_chips` (enums + 3 chip rows), `free_competition_card`, `paid_competition_card`, `competition_list_card` (dispatcher).

### 21 issues `flutter analyze` restantes
- [x] **Résolu le 2026-05-17, commit `98ba7e9`** — `flutter analyze` passe à `No issues found!` (re-vérifié 2026-05-19, toujours 0 issue).

Catégories traitées : `use_build_context_synchronously` (1, payment-critique),
`cascade_invocations` (6), `avoid_equals_and_hash_code_on_mutable_classes`
(6 via `@immutable`), `avoid_dynamic_calls` (4 via cast en amont),
`no_default_cases` (3 switchs `MatchStatus` rendus exhaustifs),
`eol_at_end_of_file` (1).

## P2 — hygiène diffuse

### Couleurs hardcodées résiduelles
Audit ciblé après commit `482ea83` : la majorité des `Colors.white|black` restants sont justifiés (contraste sur gradient, overlay scrim semi-transparent, brand externe). Seuls **2 FIX directs** et **~5 EXTEND** (palette à enrichir) sont de vrais TODO.

**Décision préalable à prendre :**
- [x] **Option A** — script guard `scripts/check_colors.{sh,ps1}` + allowlist `scripts/colors_allowlist.txt` (commit `<pending>`, 2026-05-19). Miroir de `check_spacing` ; `--strict` exit 1 si régression hors allowlist. 81 KEEPs catalogués (gradient contrast / brand-protected Google / overlay isolate `recording_overlay` / scrim semi-transparent). `custom_lint` natif reste à activer si/quand `very_good_analysis` 10.x supporte analyzer 7.7+ — pour l'instant le script couvre la même finalité.
- [ ] **Option B** — passe manuelle fichier par fichier après enrichissement palette. (Non choisie : 81 violations actuelles sont KEEP justifiés ; Option A préventive suffit.)

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
- [x] **Liens docs du README** — les 4 liens internes du README (`docs/ARENA_MASTER_PROMPT.md`, `docs/ARENA_FLUTTER_PROMPT.md`, `docs/AUDIT_FOLLOWUP.md`, `docs/ARENA_54_ECRANS.md`) vérifiés fonctionnels sur GitHub le 2026-05-20 (API GitHub OK, casse de chemin exacte, dépôt public). Liens corrigés vers `docs/` dans le commit `0896a14`.

## Notes pour la prochaine session

- `chat_messages_no_blocked_pair` est passé en `RESTRICTIVE` dans `20260517110004` — **fix de bug** (auparavant en PERMISSIVE, la policy n'avait aucun effet à cause du OR Postgres). À garder en tête pour toute future policy `no_xxx` / `deny_xxx` : doit être `RESTRICTIVE`.
- Les migrations RLS A-D ont éliminé 50 `multiple_permissive_policies`, 2 `auth_rls_initplan`, 1 `anon_security_definer`. Le schéma `public` n'a plus aucun warning perf actif.
- Aucun secret côté client (`SERVICE_ROLE_KEY`, `RESEND_API_KEY` introuvables dans `lib/`).
- iOS deployment target = 13.0 (EOL Apple 2023) — bump à 14+ à considérer.
- `firebase_options.dart` absent côté Flutter (init Firebase par `google-services.json` seul, Android-only OK ; pour iOS lancer `flutterfire configure`).

## Préparation scale 1M users (2026-05-19, sessions 23281e4 → ce commit)

Plan en 4 phases lancé suite aux screenshots WhatsApp 13:46 (Realtime
errors + question scale). Status :

- [x] **Phase 1 — Realtime JWT refresh** — commit `23281e4`. Sans listener
  `onAuthStateChange` → `client.realtime.setAuth(token)`, les 22 streams
  `from(t).stream(...)` échouent après chaque refresh JWT (~60 min).
- [x] **Phase 2 — Bornes + autoDispose** — commit `239c315`. 5 endpoints
  unbounded plafonnés (`competitions.list`, `match_stats.getForPlayer`,
  `friends.list*`×4) + 8 family providers passés en `.autoDispose`
  (mémoire + WebSocket count).
- [x] **Phase 3 — DB hardening** — ce commit. `search_path` immutable
  sur les 3 functions restantes (`next_power_of_two`, `gen_referral_code`,
  `ensure_referral_code`).
- [ ] **Phase 4 — Observability** — Sentry custom traces + cadrage.

### Actions manuelles côté Supabase Dashboard (pas SQL)

- [ ] **Auth DB Connection Strategy = absolute** (advisor INFO,
  cache_key `auth_db_connections_absolute`) — actuel : Auth limité à 10
  connexions absolues. À 1M users, l'upgrade de l'instance ne propage
  pas automatiquement plus de connexions. Action : Supabase Dashboard →
  Settings → Auth → Connection strategy → `Percentage based`. Cf.
  https://supabase.com/docs/guides/deployment/going-into-prod.
- [ ] **Realtime channels limit** — Supabase Pro plan = 500 channels
  concurrents par projet. Pour 1M users actifs (~5% concurrent = 50k),
  passer en Realtime Enterprise OU dégrader les `.stream()` en poll
  pour les écrans non-critiques (cf. dette Phase 2.5 ci-dessous).
- [ ] **Storage cache-control** — vérifier que `match-recordings`,
  `avatars/`, `banners/` ont `cache-control: public, max-age=86400`
  pour profiter du CDN edge. Action : Supabase Dashboard → Storage →
  Configuration bucket → Cache-control.

### Dettes assumées Phase 2.5 (V2, traction-dependent)

- [ ] **Pagination admin endpoints** (`admin_matches.watchAll`,
  `admin_competitions.watch`, `admin_disputes.watchAll`) — fetchent
  toute la table puis filtrent client-side. OK à <100 admins, problème
  à 100k+ rows. À paginer via `.range(start, end)` + `FutureProvider
  .family` quand le DB grossit.
- [ ] **Realtime → Poll** sur écrans non-critiques (`competition
  _repository.watch`, `watchMyRegisteredCompetitionIds`, `friends
  _repository.watchIncomingPendingCount`, `match_stream_repository
  .watchActivePublic`, `payment_repository.watchMine`). Économise 1
  WebSocket par stream et par client à scale. Audit explore dans
  l'historique session 2026-05-19.
- [ ] **Index composite `matches(player1_id, status, finished_at DESC)`**
  + symmetric pour `player2_id` — accélère `match_stats.getForPlayer`
  qui devient critique sur power users (10k+ matches). Pas créé V1 :
  3 indexes supplémentaires sont coûteux en INSERT. À ajouter quand
  P95 de la query dépasse 200 ms.

### Indexes inutilisés (advisor INFO — re-audit pending)

26 unused indexes flaggés au 2026-05-19 (idem audit 2026-05-17). Aucune
suppression : tous restent `defensive` jusqu'à 4 semaines de traction
réelle avec >10k users actifs. Re-audit après `SELECT pg_stat_reset()`
+ 1 mois de prod.

## Audit complet 2026-05-19 — wave 1 (ce commit)

### Sécurité backend

- [x] **Migration RPC ACL** — `20260519160000_rpc_acl_revoke_anon_security_definer.sql`. REVOKE EXECUTE FROM anon sur 20 fonctions SECURITY DEFINER (triggers, bracket generators, super-admin RPC, helpers). Bonus : `_require_super_admin()` ajouté à `get_monthly_revenue` et `get_monthly_signups` qui n'avaient AUCUN gate auth. Advisor `anon_security_definer_function_executable` : 20 → 0. Les 24 `authenticated_*` restants sont documentés intentionnels (cf. `20260517110007`).
- [x] **Phase 3 search_path** — `20260519133930_harden_search_path_3_remaining_functions.sql` poussée sur remote.

### Perf

- [x] **#3 .limit(5000)** — `admin_kpis_repository.dart:38` (+ les 3 autres queries du dashboard KPI). Cap défensif contre les scans massifs `matches`/`competitions`/`disputes`/`payouts` à scale.
- [x] **#6 .autoDispose** — 14 family providers patchés : `matchPlayersProvider`, `matchChannelProvider`, `channelMessagesProvider`, `competitionRankingProvider`, `adminAuditLogProvider`, `userNotificationsProvider`, `unreadNotificationCountProvider`, `adminCompetitionsProvider`, `adminCompetitionRegistrantsProvider`, `adminMatchesProvider`, `competitionStandingsProvider`, `adminDisputeByMatchProvider`, `adminUsersProvider`, `_opponentProvider` (chat). `pendingScoreSubmissionProvider` + `pendingRoomCodeProvider` volontairement conservés (commentaire "survit aux remounts" intentionnel).

### Hygiène code

- [x] **#9 Helper `arenaErrorMessage(Object e)`** — `lib/core/utils/arena_error_message.dart`. Mappe `AuthFailure` / `AuthException` / `PostgrestException` (codes 23505/23503/42501/PGRST301) / `FunctionException` / `SocketException` → message FR. Appliqué aux 11 catches de 6 pages admin/super-admin (users, payments_validation, invitations, payouts, reintegration, disputes, bracket_management). Les autres `'Échec : $e'` peuvent migrer incrémentalement. Note : les 14 repositories de `lib/data/repositories/` n'ont déjà aucun catch générique — ils bubble up les erreurs natives (pattern correct). Le typing dette était surévaluée par l'audit initial.

## Audit complet 2026-05-19 — wave 2 (ce commit)

### Refacto

- [x] **#4 create_competition_page.dart 1254 → 791 lignes** (-37 %, sous 800 ✓). Extrait `WizardStepFees` (274 l.) et `WizardStepFormat` (194 l.) en widgets indépendants sous `widgets/`. Les 3 classes privées chip (`_MatchIntervalPicker`, `_ModeChip`, `_IntervalChip`) déplacées dans `competition_form_widgets.dart` (réutilisables). Les step builders `_buildInfosStep`/`_buildPrizesStep`/`_buildReviewStep` restent inline (couplage state fort, retour `List<Widget>`).

### Perf scaling

- [x] **#8 Downgrade Realtime → poll** sur 3 streams non-critiques :
  - `competitionsListProvider` (4 variants par filtre game) → poll 60s
  - `myPaymentsProvider` (P6 historique) → poll 60s
  - `activePublicStreamsProvider` (live streams page) → poll 45s
  Helper `lib/core/utils/poll_stream.dart` réutilisable (`Stream<T> pollStream(Duration, Future<T> Function())`). Libère ~5-6 channels Realtime par client actif, soulage la limite Pro = 500 channels concurrents.

### CI

- [x] **#7 Codecov** ajouté à `.github/workflows/ci.yml` (step `flutter test --coverage` + `codecov-action@v4`, `continue-on-error: true` pour ne pas bloquer si CODECOV_TOKEN absent).
- [x] **Dependabot** : `.github/dependabot.yml` créé (pub weekly, github-actions weekly, gradle monthly).
- [x] **golden_toolkit ^0.15.0** ajouté en dev_dependency (la suite golden existe déjà via `test/golden_path_test.dart`, le toolkit servira aux prochains goldens visuels).

### Observability

- [x] **#11 Phase 4 Sentry traces** : helpers `traceAsync<T>` et `traceSpan<T>` (`lib/core/utils/sentry_trace.dart`) appliqués à 2 chemins critiques (create competition + validate payment). `SentryProviderObserver` câblé dans `bootstrap.dart` — toute exception qui throw depuis un Riverpod provider est désormais capturée avec breadcrumb + tag `riverpod.provider`.

### Tests (couverture)

- [x] **#5 Tests unitaires + widget** : `arena_error_message_test` (8 tests), `poll_stream_test` (2 tests), `wizard_step_fees_test` (3 tests). **+13 tests → 182 total** (de 169). Ratio reste bas (~2 %) mais le runway des helpers neufs est verrouillé.

### Restant

- [ ] **iOS deployment target 13 → 14** (P3).
- [ ] **Tests intégration** `integration_test/` toujours vide (golden_path_test couvre la majorité des routes côté unit).
- [ ] Étendre `arenaErrorMessage` aux ~40 catches UI non encore migrés (mécanique).
- [ ] Étendre `traceAsync` à : match score submission, friend requests, registration P2.

## Diagnostic complet 2026-05-20 (ce commit)

`flutter analyze` 0 issue · 182/182 tests verts · aucun secret en dur.
Points traités dans cette passe :

- [x] **Edge Function fantôme** — `get-agora-call-token` était déployée
  (v1, `verify_jwt:true`) mais n'avait aucun code source versionné. Code
  récupéré depuis Supabase et committé dans
  `supabase/functions/get-agora-call-token/index.ts`. README corrigé :
  13 → 14 Edge Functions.
- [x] **Worktree obsolète** — `.claude/worktrees/lucid-mcnulty-5bf4c2/`
  (2.7 Go) retiré (corbeille). Sa branche `claude/lucid-mcnulty-5bf4c2`
  portait 2 commits non mergés (`080a0ff` perf realtime publication
  Phase 3/4, `2d9aee0` Sentry user context Phase 4/4) — **mergée dans
  `main`** (commit de merge `9a77aa1`). La branche locale est conservée
  (redondante, supprimable).
- [x] **`sentry_flutter`** bumpé `^9.19.0` → `^9.20.0`.

### Réconciliation des migrations (dérive registre ↔ dossier)

Le registre distant `supabase_migrations.schema_migrations` (73 entrées)
et `supabase/migrations/` avaient divergé : des migrations appliquées via
MCP `apply_migration` n'avaient jamais été sauvegardées comme fichier.

- [x] **13 migrations rapatriées** depuis `schema_migrations.statements`
  (le SQL réellement appliqué) vers `supabase/migrations/`, nommées
  `<version>_<name>.sql` :
  `20260505184750_security_and_perf_hardening`,
  `20260505185438_rls_policies_optimization`,
  `20260510151601_fix_auto_publish_final_match_status_typo`,
  `20260510152648_chat_messages_allow_room_code_type`,
  `20260515212934_three_strikes_hardening_revoke_triggers`,
  `20260518160707_competitions_auto_management_lot_a`,
  `20260518162244_competitions_commission_xaf_lot_b`,
  `20260518162642_super_admin_kpis_lot_b`,
  `20260518163612_admin_filter_users_by_competition_lot_c`,
  `20260518164644_referral_system_lot_d`,
  `20260518170120_auto_bracket_on_update_a3`,
  `20260518170158_profile_last_seen_at_b1`,
  `20260518170817_admin_filter_users_multi_competition_c2`.
  Dossier : 66 → **79 fichiers**.
- [x] **Cas vérifiés OK** (fichier local présent, effet live sur la base,
  juste non enregistré au registre — rien à faire) :
  `realtime_drop_unused_tables`, `chat_media_storage_bucket`,
  `fix_chat_media_storage_rls_name_shadow`.
- [ ] **Dette résiduelle (process)** : les versions de fichiers locaux
  ne correspondent toujours pas 1:1 aux versions du registre (numéros
  d'application ≠ noms de fichiers). `harden_search_path_3_remaining_functions`
  est enregistrée 2× (idempotente, sans effet). Avant tout `supabase db
  push`/`reset` en CI : générer une baseline propre (`supabase db dump`)
  ou faire un `migration repair`. Non bloquant — la base de prod est saine.

### Risque accepté — `is_blocked_pair` exposée à `authenticated`

L'advisor `authenticated_security_definer_function_executable` flagge
`public.is_blocked_pair(p_user_a uuid, p_user_b uuid)` : tout utilisateur
authentifié peut, via `/rest/v1/rpc/is_blocked_pair`, tester l'état de
blocage entre **deux UUID arbitraires** (pas seulement les siens).

- **Pourquoi conservée** : la fonction est `SECURITY DEFINER` et est
  appelée par ~plusieurs policies RLS (`chat_messages_no_blocked_pair`
  RESTRICTIVE, etc.). Lui retirer `EXECUTE` côté `authenticated` ou la
  passer `SECURITY INVOKER` casserait l'évaluation RLS au runtime.
- **Surface réelle** : fuite booléenne mineure (existe-t-il un blocage
  entre A et B). Pas de PII, pas d'énumération de comptes (les UUID ne
  sont pas devinables). Idem `is_admin()` / `is_super_admin()` —
  intentionnellement exposées (cf. note `20260517110007`).
- **Décision** : **risque accepté V1.0**, advisor restera WARN. Si une
  passe future veut le fermer : wrapper RPC qui exige
  `p_user_a = auth.uid() OR p_user_b = auth.uid()`, en gardant la
  fonction interne non exposée pour les policies.

## Audit complet 2026-06-01 — fix C-1 / M-3 / E-1

- [x] **C-1 — colonnes secrètes de `profiles` verrouillées** — migration
  `20260601120000_c1_revoke_profiles_secret_columns.sql` (appliquée prod).
  `profiles_select` rendait `totp_secret`/`backup_codes` lisibles par tout
  utilisateur via `select=*`. Piège PG : un `REVOKE (colonne)` est inopérant
  tant qu'un GRANT SELECT *table-level* existe → on a `REVOKE SELECT` table
  puis `GRANT SELECT (<34 colonnes non-secrètes>)` à anon/authenticated.
  Côté client, `ProfileRepository` (getById/getByIds/create/update) est passé
  d'un `.select()` implicite (`*`) à une liste de colonnes explicite (sans
  secrets) — sinon `permission denied for column profiles.totp_secret`.
  Vérifié : `column_privileges` ne liste plus SELECT sur les 2 secrets pour
  anon/authenticated ; `flutter analyze` 0 issue · 213/213 tests verts.
  EF TOTP non impactées (service role bypasse les grants colonne).
  - [ ] **Résiduel (MEDIUM, ex-C-1)** — la PII inter-utilisateurs (email,
    whatsapp_number, fcm_token) reste lisible par `authenticated` via
    `getByIds` (hydratation adversaires/pairs/brackets). Fix complet =
    vue `public_profiles` (colonnes publiques only) + modèle `PublicProfile`
    pour les lectures cross-user. Reporté (refacto multi-fichiers, à tester
    sur device).
- [x] **M-3 — `backup_codes` plus renvoyés au client** — `delete
  safeProfile.backup_codes;` ajouté dans `admin-verify-totp` et
  `register-admin` (en plus de `totp_secret`). `verify-totp-setup` renvoie
  les backup codes en clair UNE fois au setup = légitime, conservé.
  ⚠️ **À déployer** : `bin/supabase.exe functions deploy admin-verify-totp register-admin`
  (le fix source ne prend effet qu'après redéploiement des EF).
- [x] **E-1 — secret webhook : rotation confirmée + scrub** — vérifié via
  Vault (`decrypted_secrets`) : le secret `webhook_secret` n'est PLUS la
  valeur brûlée `8877a4a6…` (rotée, len 64 ; webhooks prod fonctionnels →
  le secret EF correspond). Risque neutralisé. Hygiène : la valeur morte
  (8 occurrences dans 5 migrations pré-Vault, supersédées par
  `20260522100000`) remplacée par le placeholder
  `ROTATED-SEE-MIGRATION-20260522100000` ; entrée d'allowlist gitleaks
  correspondante retirée (CI scanne le working tree, pas l'historique).

## C-1 résiduel (PII inter-utilisateurs) — PR #14, mergée 2026-06-02

✅ **Migration appliquée en prod le 2026-06-01 (version remote `20260601184427`).**
La RLS restrictive étant déjà active côté base, le merge du code Dart rerouté
était l'action sûre (une app construite depuis `main` sans ce code aurait des
lectures cross-user vides). La checklist device reste valable comme smoke test
post-merge.

- [x] **Fix PII cross-user via vue `public_profiles` + RLS self+admin** —
  migration `20260601130000_c1_residual_public_profiles_view.sql`. La policy
  `profiles_select` est restreinte à self+admin ; une vue `public_profiles`
  (`security_invoker=false`) expose uniquement les colonnes publiques (sans
  email/whatsapp/fcm/voip/kyc/auth_provider/referral). `Profile.email` passé
  `String?`. Lectures reroutées :
  - `ProfileRepository` : `getByIds` + nouveau `getPublicById` + `usernameExists` → vue.
    `getById`/`create`/`update` restent sur la table (self/admin).
  - cross-user `getById` → `getPublicById` : chat (`_opponentProvider`),
    chat ami (`_friendPeerProvider`), salle de match (`matchPlayersProvider`).
  - `friends_repository` : `resolvePeers`/`searchByUsername`/`findByUsername` → vue.
  - `competition_repository.getRanking` : embed `profiles!player_id` remplacé
    par 2 requêtes (registrations + `public_profiles`).
  - `call_repository.usernameOf` → vue.
  - admin (`super_admin_users`, reintegration, embeds admin) : restent sur la
    table (les admins lisent la table via la RLS `is_admin()`).
  - **Checklist device** (cf. en-tête de la migration) : salle de match, chats,
    inbox, bracket/poules, classement final, recherche+profil public, appel
    entrant, vérif username au signup, écrans admin.
  - Validé localement : `flutter analyze` 0 issue · 213/213 tests · l'advisor
    `security_definer_view` flaggera `public_profiles` (WARN assumé, intentionnel).
