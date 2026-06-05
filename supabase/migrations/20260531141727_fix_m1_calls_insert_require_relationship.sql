-- =============================================================================
-- ARENA — Sécurité — M1 : un appel ne peut viser qu'un ami ou un adversaire
-- =============================================================================
-- La policy `calls_insert_caller` (20260520130000_calls_signaling.sql:47-48) ne
-- vérifiait que `auth.uid() = caller_id`. N'importe quel utilisateur pouvait
-- donc INSÉRER un appel vers N'IMPORTE QUI : le trigger `notify_incoming_call`
-- (AFTER INSERT) émet alors une notif `call_invite` → FCM haute priorité →
-- sonnerie plein écran (CallKit) chez la cible. Soit un vecteur de
-- harcèlement / DoS (faire sonner un inconnu en boucle, app fermée).
--
-- Correctif : aligner le WITH CHECK sur la gate serveur de
-- `get-agora-call-token/index.ts:95-116` — l'appelant ET l'appelé doivent être
-- les deux joueurs du match (scope='match') ou les deux parties d'une amitié
-- `accepted` (scope='friend'). Le `scope_id` doit donc désigner une relation
-- réelle liant exactement les deux pairs.
--
-- `matches` est en lecture publique (matches_select USING(true)) et l'appelant
-- voit toujours sa propre amitié → les sous-requêtes EXISTS sont évaluables
-- sous RLS pour le rôle authenticated qui insère.
-- =============================================================================
-- Depends on: 20260520130000_calls_signaling.sql,
--             20260516160001_friendships.sql,
--             20260505100003_matches_and_brackets.sql
-- =============================================================================

drop policy if exists calls_insert_caller on public.calls;

create policy calls_insert_caller on public.calls for insert
  with check (
    (select auth.uid()) = caller_id
    and caller_id <> callee_id
    and (
      (
        scope = 'match'
        and exists (
          select 1 from public.matches m
          where m.id = scope_id
            and caller_id in (m.player1_id, m.player2_id)
            and callee_id in (m.player1_id, m.player2_id)
        )
      )
      or (
        scope = 'friend'
        and exists (
          select 1 from public.friendships f
          where f.id = scope_id
            and f.status = 'accepted'
            and caller_id in (f.requester_id, f.addressee_id)
            and callee_id in (f.requester_id, f.addressee_id)
        )
      )
    )
  );
