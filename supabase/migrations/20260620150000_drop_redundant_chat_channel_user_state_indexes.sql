-- ════════════════════════════════════════════════════════════════════
-- Durcissement P3 (audit 2026-06-15) — index redondants de
-- chat_channel_user_state
-- ════════════════════════════════════════════════════════════════════
-- La table a pour PK UNIQUE (user_id, channel_id). Deux index secondaires
-- (0 scan en prod) sont redondants avec elle :
--   * _user_idx (user_id)            → couvert par le préfixe gauche de la PK
--     (qui sert aussi la cascade du FK user_id → profiles).
--   * _last_read_at_idx (user_id, channel_id, last_read_at) → la PK étant
--     UNIQUE sur (user_id, channel_id), il y a au plus UN row par couple ;
--     ajouter last_read_at en 3e colonne n'apporte aucun gain.
--
-- On CONSERVE volontairement _channel_idx (channel_id) : il couvre le FK
-- channel_id → chat_channels ON DELETE CASCADE (politique projet : garder
-- les index de clés étrangères). L'audit suggérait « 3 » mais cet index-là
-- n'est pas redondant.
-- ════════════════════════════════════════════════════════════════════

drop index if exists public.chat_channel_user_state_user_idx;
drop index if exists public.chat_channel_user_state_last_read_at_idx;
