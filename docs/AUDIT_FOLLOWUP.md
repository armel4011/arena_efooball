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
- [ ] `lib/features_user/home/home_page.dart` — 961 lignes
- [ ] `lib/features_admin/competitions_admin/admin_competition_detail_page.dart` — 907 lignes
- [ ] `lib/features_user/competitions/competitions_list_page.dart` — 842 lignes

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
- [ ] `lib/features_shared/widgets/arena_phone_frame.dart:22` — `Color(0xFF1A1A22)` → `ArenaColors.carbon2` (#1C1C26, écart imperceptible).
- [ ] `lib/features_user/profile/avatar_palette.dart:33,35` — `Color(0xFF4C7AFF)` → `ArenaColors.signalBlue`.

**EXTEND `ArenaColors` (puis remplacer les usages) :**
- [ ] **Gold premium** (`tierGold` + `tierGoldDeep`) — `competitions_list_page.dart:602-603` (`0xFFFFC93C` / `0xFFCB9A1F`), `super_admin_dashboard.dart`, `super_admin_invitations.dart` (`0xFFFFD700`).
- [ ] **Brand mobile money** (`brandOrangeMoney` + `brandMtnMomo` ou un map dans `payment_method.dart` — décider du nommage côté design) — `payment_history_page.dart:245`, `payment_method.dart:16,24` (oranges custom).
- [ ] **Status variants** (`statusOkDeep`, `statusDangerDeep` ou les exposer comme gradients) — `payment_success_page.dart:138` (`0xFF00A878`), `payment_failed_page.dart:190` (`0xFF8B0020`).
- [ ] **Stream moderation gradients** (`streamModerationGradients` ou 4 gradients dédiés) — `admin_stream_moderation_page.dart:28-43` (4 gradients custom blue/red/green/purple).

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

### Indexes inutilisés (26 — advisor performance INFO)
À auditer avant suppression : un index peut être utilisé en pic seulement, ou nécessaire à une migration future. Faire `SELECT … FROM pg_stat_user_indexes` sur un cycle d'utilisation représentatif avant DROP.

- [ ] `idx_profiles_country`, `idx_profiles_deleted`, `idx_profiles_permanent_ban`
- [ ] `idx_competitions_dates`, `idx_competitions_game`
- [ ] `idx_memberships_group`
- [ ] `idx_matches_status`, `idx_matches_streamed_live`, `idx_matches_group`, `idx_matches_home_player`, `idx_matches_winner`, `idx_matches_streaming_admin`
- [ ] `idx_bracket_nodes_parent`, `idx_bracket_nodes_next_node`
- [ ] `idx_payments_provider_tx`, `idx_payments_validated_at`
- [ ] `idx_payouts_admin_validation`
- [ ] `idx_webhook_log_provider`
- [ ] `idx_auto_actions_function`
- [ ] `idx_invitation_codes_unused`, `invitation_codes_code_active_idx`
- [ ] `idx_banned_words_language`
- [ ] `idx_exchange_rates_pair`
- [ ] `idx_match_events_created_by`
- [ ] `idx_streams_active_public`
- [ ] `idx_reintegration_status_created`

### FK non indexées (2 — advisor performance INFO)
- [ ] `friendships.blocked_by_fkey` → `CREATE INDEX ON public.friendships(blocked_by);`
- [ ] `reintegration_requests.resolved_by_fkey` → `CREATE INDEX ON public.reintegration_requests(resolved_by);`

## CI & qualité

- [ ] **0 test d'intégration** — créer `integration_test/` avec au moins le golden path (login → home → join competition → match flow). Cible de couverture : 50 %.
- [ ] **Pas de codecov dans CI** — ajouter step `flutter test --coverage` + upload codecov dans `.github/workflows/ci.yml`.
- [ ] **`custom_lint` / `riverpod_lint` désactivés** — surveiller la sortie d'analyzer 7.7+ pour réactiver (cf. `analysis_options.yaml`).
- [ ] **17 `authenticated_security_definer_function_executable` (WARN)** — par design (RPC user-actionnable, checks internes en place). À documenter dans un commentaire SQL pour faire taire l'advisor sans masquer un vrai trou.

## Notes pour la prochaine session

- `chat_messages_no_blocked_pair` est passé en `RESTRICTIVE` dans `20260517110004` — **fix de bug** (auparavant en PERMISSIVE, la policy n'avait aucun effet à cause du OR Postgres). À garder en tête pour toute future policy `no_xxx` / `deny_xxx` : doit être `RESTRICTIVE`.
- Les migrations RLS A-D ont éliminé 50 `multiple_permissive_policies`, 2 `auth_rls_initplan`, 1 `anon_security_definer`. Le schéma `public` n'a plus aucun warning perf actif.
- Aucun secret côté client (`SERVICE_ROLE_KEY`, `RESEND_API_KEY` introuvables dans `lib/`).
- iOS deployment target = 13.0 (EOL Apple 2023) — bump à 14+ à considérer.
- `firebase_options.dart` absent côté Flutter (init Firebase par `google-services.json` seul, Android-only OK ; pour iOS lancer `flutterfire configure`).
