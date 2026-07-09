# Unused Indexes — Tracking (audit 2026-05-23)

## MAJ 2026-07-09 — re-check advisor + pg_stat

Re-run `get_advisors(performance)` + `pg_stat_user_indexes` : **~60 index à
`idx_scan = 0`, mais les stats restent BIAISÉES** — même des index certainement
utilisés (`profiles_username_key`, `payments_idempotency_key_key`) sont à 0
(compteurs remis à zéro / trafic quasi nul). → `idx_scan = 0` **n'est pas** un
signal de suppression fiable. On **maintient la règle** : purge usage-based
seulement après ≥ 2026-07-22, et re-vérifier que le trafic prod est réel
(des index cœur ont un scan > 0) avant de dropper.

**Action prise 2026-07-09 (indépendante des stats)** : migration
`20260709140000_drop_redundant_indexes.sql` retire 3 **doublons exacts** (index
non-unique portant le même jeu de colonnes qu'un index de contrainte UNIQUE) :
`idx_bracket_nodes_phase`, `idx_draughts_moves_game_ply`, `idx_phases_competition`.
Sûr : l'index unique dessert les mêmes lookups. NE PAS confondre avec la purge
usage-based ci-dessous, toujours en attente.



L'advisor performance Supabase signale **26 indexes jamais utilisés**.
Ils sont conservés pour l'instant : le projet est en pré-production /
phase d'ouverture publique, donc la stats `pg_stat_user_indexes` est
biaisée (peu de trafic réel, peu de queries déclenchant les indexes).

**Règle** : ré-évaluer après **60 jours de prod** (≥ 2026-07-22).
Un index utilisé ne serait-ce qu'une fois sort de la liste.

## Tracking

| Table | Index | Raison du keep |
|---|---|---|
| `profiles` | `idx_profiles_country` | Filtres pays (admin filter) |
| `profiles` | `idx_profiles_deleted` | Soft delete RGPD |
| `profiles` | `idx_profiles_permanent_ban` | 3-strikes gate |
| `profiles` | `idx_profiles_last_seen` | Présence + analytics |
| `competitions` | `idx_competitions_dates` | Liste tournois par date |
| `competitions` | `idx_competitions_game` | Filtre par jeu |
| `matches` | `idx_matches_status` | Bracket pipeline |
| `matches` | `idx_matches_streamed_live` | Streaming live finals |
| `matches` | `idx_matches_group` | Round-robin / groupes |
| `matches` | `idx_matches_home_player` | Lookup par joueur |
| `matches` | `idx_matches_streaming_admin` | Admin streaming console |
| `matches` | `idx_matches_winner` | Stats winner lookup |
| `payments` | `idx_payments_provider_tx` | Idempotence webhooks (futurs CinetPay/NowPayments) |
| `payments` | `idx_payments_validated_at` | Reporting validation manuelle |
| `payouts` | `idx_payouts_admin_validation` | Queue admin payouts |
| `payment_webhook_log` | `idx_webhook_log_provider` | Debug webhooks |
| `auto_actions_log` | `idx_auto_actions_function` | Audit auto-actions |
| `banned_words` | `idx_banned_words_language` | Modération chat multi-langue |
| `exchange_rates` | `idx_exchange_rates_pair` | Conversion XAF |
| `match_events` | `idx_match_events_created_by` | Audit anti-cheat |
| `calls` | `idx_calls_caller` | Historique appels |
| `calls` | `idx_calls_callee_ringing` | Push call entrant FCM |
| `reintegration_requests` | `idx_reintegration_status_created` | Queue super-admin |
| `invitation_codes` | `invitation_codes_code_active_idx` | Lookup code admin |
| `friendships` | `idx_friendships_blocked_by` | Block/unblock RLS |
| `chat_channel_user_state` | `chat_channel_user_state_user_idx` | Badge non-lus user |
| `chat_channel_user_state` | `chat_channel_user_state_channel_idx` | Lookup channel state |
| `chat_channel_user_state` | `chat_channel_user_state_last_read_at_idx` | Tri par dernière lecture |

## Décision drop

Après 60j de prod (≥ 2026-07-22) :
1. Re-run `mcp__supabase__get_advisors` type=performance
2. Pour chaque index toujours INFO unused → vérifier `pg_stat_user_indexes.idx_scan = 0`
3. Drop migration → `DROP INDEX IF EXISTS <name>;`
4. Garder un keep-list explicite pour les indexes "stratégiques" (webhooks futurs, queues admin)
