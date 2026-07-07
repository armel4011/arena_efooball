-- =============================================================================
-- ARENA — Audit 2026-07-07 (P1 #3) : INSERT chat_messages exige l'appartenance
-- =============================================================================
-- La policy PERMISSIVE `chat_messages_insert` ne vérifiait QUE
-- `sender_id = auth.uid()` — jamais que l'émetteur appartient au canal. Comme
-- `chat_channels_select` est `using(true)`, tout authentifié pouvait énumérer
-- n'importe quel `channel_id` puis y INSÉRER un message :
--   • canal `competition_broadcast` / `global` → visible par TOUS les users
--     (le SELECT autorise ces types à tout le monde) = spam/phishing de masse
--     dans le fil « officiel » de la plateforme ;
--   • canal `match` / `friend` / `admin_user` dont il n'est pas membre → message
--     injecté dans une conversation privée (harcèlement ciblé).
--
-- Les gardes RESTRICTIVE existantes ne couvraient qu'une partie du problème :
--   - `chat_messages_no_blocked_pair`      : uniquement les paires bloquées (match) ;
--   - `chat_messages_support_insert_guard` : uniquement les canaux `admin_user`.
--   → rien pour match (non-bloqué mais non-membre), friend, broadcast, global.
--
-- CORRECTIF : on remplace le WITH CHECK par le MÊME modèle d'appartenance que
-- `chat_messages_select`, appliqué à l'écriture :
--   • is_admin()                          → tout (broadcast/global/support inclus) ;
--   • sinon sender_id = auth.uid() ET :
--       - `match`      → l'émetteur est l'un des deux joueurs ;
--       - `friend`     → amitié ACCEPTÉE dont l'émetteur est membre ;
--       - `admin_user` → l'émetteur est le support_user_id (côté user).
--   • `competition_broadcast` / `global` → ABSENTS du modèle d'écriture non-admin
--     → écriture réservée aux admins (lecture publique inchangée). Aucun flux user
--     ne poste dans ces canaux (le broadcast admin passe par la RPC notifications,
--     pas par chat_messages) : fermeture sans régression.
--
-- Les 2 policies RESTRICTIVE (blocked pair, support guard) restent en place et
-- s'appliquent EN PLUS (AND) — défense en profondeur.
-- =============================================================================

drop policy if exists chat_messages_insert on public.chat_messages;
create policy chat_messages_insert on public.chat_messages
  for insert to public
  with check (
    (select public.is_admin())
    or (
      sender_id = (select auth.uid())
      and exists (
        select 1
        from public.chat_channels c
        left join public.matches m     on m.id = c.match_id
        left join public.friendships f on f.id = c.friendship_id
        where c.id = chat_messages.channel_id
          and (
            (c.type = 'match'
              and ((select auth.uid()) = m.player1_id
                or (select auth.uid()) = m.player2_id))
            or (c.type = 'friend'
              and f.status = 'accepted'::friendship_status
              and ((select auth.uid()) = f.requester_id
                or (select auth.uid()) = f.addressee_id))
            or (c.type = 'admin_user'
              and c.support_user_id = (select auth.uid()))
          )
      )
    )
  );

comment on policy chat_messages_insert on public.chat_messages is
  'P1 audit 2026-07-07 : l''émetteur doit appartenir au canal (miroir de '
  'chat_messages_select) — match=joueur, friend=amitié acceptée, admin_user='
  'support_user ; broadcast/global = écriture admin-only. Complète les RESTRICTIVE '
  'chat_messages_no_blocked_pair / chat_messages_support_insert_guard.';
