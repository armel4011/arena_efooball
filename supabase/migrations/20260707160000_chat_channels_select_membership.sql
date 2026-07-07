-- =============================================================================
-- ARENA — Audit 2026-07-07 (P2) : chat_channels_select restreint à l'appartenance
-- =============================================================================
-- `chat_channels_select` était `using(true)` : tout authentifié pouvait lire les
-- MÉTADONNÉES de N'IMPORTE quel canal (support_user_id, friendship_id, match_id,
-- name) — fuite d'existence des fils support/amis d'autrui. Le CONTENU restait
-- protégé par `chat_messages_select`, mais l'énumération des canaux ne l'était
-- pas (et alimentait la faille d'INSERT corrigée en PR #270).
--
-- CORRECTIF : on aligne la visibilité des CANAUX sur le même modèle
-- d'appartenance que `chat_messages_select` :
--   • is_admin()                          → tous les canaux ;
--   • competition_broadcast / global      → publics (lecture par tous) ;
--   • match      → l'un des deux joueurs ;
--   • friend     → membre de la friendship (requester/addressee) ;
--   • admin_user → le support_user_id (côté user).
--
-- Sans régression : les flux user (listMyFriendChannels, matchChannelIdsFor,
-- openedMatchChannelIds, ensureMatchChannel) filtrent DÉJÀ par les matchs /
-- amitiés du user → cette RLS renvoie le même sous-ensemble. Les flux admin
-- passent par is_admin().
-- =============================================================================

drop policy if exists chat_channels_select on public.chat_channels;
create policy chat_channels_select on public.chat_channels
  for select to public
  using (
    (select public.is_admin())
    or type = any (array['competition_broadcast', 'global'])
    or (
      type = 'match'
      and exists (
        select 1 from public.matches m
        where m.id = chat_channels.match_id
          and ((select auth.uid()) = m.player1_id
            or (select auth.uid()) = m.player2_id)
      )
    )
    or (
      type = 'friend'
      and exists (
        select 1 from public.friendships f
        where f.id = chat_channels.friendship_id
          and ((select auth.uid()) = f.requester_id
            or (select auth.uid()) = f.addressee_id)
      )
    )
    or (type = 'admin_user' and support_user_id = (select auth.uid()))
  );

comment on policy chat_channels_select on public.chat_channels is
  'P2 audit 2026-07-07 : visibilité des canaux alignée sur chat_messages_select '
  '(admin / broadcast-global publics / match=joueur / friend=membre / '
  'admin_user=support_user) — remplace using(true) qui fuitait les métadonnées.';
