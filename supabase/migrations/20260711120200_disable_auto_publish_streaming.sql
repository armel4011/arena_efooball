-- =============================================================================
-- ARENA — Diffusion live 100 % admin-gated (désactive l'auto-publish des finales)
-- =============================================================================
-- Les triggers `auto_publish_final_match` (AFTER UPDATE OF status ON matches) et
-- `auto_publish_late_stream` (BEFORE INSERT ON streams) passaient
-- automatiquement le stream du HOME en `is_public = true` + is_streamed/auto_final
-- dès qu'une « grande finale » démarrait — SANS action admin. Dans les petits
-- brackets (1 match = la finale), tout match se retrouvait auto-diffusé.
--
-- Exigence produit : par défaut le live est DÉSACTIVÉ ; seul l'admin l'active
-- (setManualStreaming → streaming_activation_type='manual_admin'). On supprime
-- donc les deux triggers et on nettoie l'état déjà auto-publié.
-- Les fonctions sont conservées (inertes sans trigger) au cas où l'auto-finale
-- serait ré-outillée plus tard derrière un flag de config.
-- =============================================================================

drop trigger if exists trg_matches_auto_publish_final on public.matches;
drop trigger if exists trg_streams_auto_publish_late on public.streams;

-- Nettoyage : repasse en privé les streams auto-publiés et efface le flag auto.
update public.streams s
   set is_public = false
  from public.matches m
 where s.match_id = m.id
   and m.streaming_activation_type = 'auto_final'
   and s.is_public = true;

update public.matches
   set is_streamed               = false,
       streaming_activation_type = null,
       streaming_activated_at    = null,
       stream_status             = case when stream_status = 'pending' then 'none'
                                        else stream_status end
 where streaming_activation_type = 'auto_final';
