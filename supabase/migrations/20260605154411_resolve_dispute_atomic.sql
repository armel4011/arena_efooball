-- =============================================================================
-- ARENA — Résolution de litige atomique (audit robustesse)
-- =============================================================================
-- La résolution faisait 3 écritures client séquentielles non transactionnelles
-- (setVerdict sur `matches` → resolve sur `disputes` → audit_log). Si la 2e
-- échouait (réseau/RLS), le match était finalisé et le bracket avançait (via
-- `cascade_match_winner`), mais le litige restait `open` → réapparaissait dans
-- la file, risque de double-arbitrage.
--
-- Une RPC unique fait tout dans UNE transaction : verdict OU annulation du
-- match + résolution du litige + trace d'audit. Tout réussit ou rien (rollback).
-- SECURITY DEFINER (contourne le guard de colonnes `matches`) + gate is_admin().
-- =============================================================================

create or replace function public.resolve_dispute(
  p_match_id      uuid,
  p_dispute_id    uuid,
  p_justification text,
  p_cancel        boolean default false,
  p_winner_id     uuid    default null,
  p_score1        integer default null,
  p_score2        integer default null
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_admin uuid := auth.uid();
begin
  if not public.is_admin() then
    raise exception 'Reserve aux administrateurs' using errcode = '42501';
  end if;
  if coalesce(trim(p_justification), '') = '' then
    raise exception 'Justification obligatoire' using errcode = '22023';
  end if;

  -- 1. Verdict (score/winner/completed) OU annulation du match.
  if p_cancel then
    update public.matches
       set status = 'cancelled', finished_at = now()
     where id = p_match_id;
  else
    update public.matches
       set score1 = p_score1, score2 = p_score2, winner_id = p_winner_id,
           status = 'completed', finished_at = now()
     where id = p_match_id;
  end if;

  if not found then
    raise exception 'Match introuvable' using errcode = 'P0002';
  end if;

  -- 2. Résout le litige (s'il existe) — même transaction.
  if p_dispute_id is not null then
    update public.disputes
       set status      = case when p_cancel then 'cancelled' else 'resolved' end,
           resolved_at = now(),
           resolved_by = v_admin,
           resolution  = p_justification
     where id = p_dispute_id;
  end if;

  -- 3. Trace d'audit — même transaction.
  insert into public.admin_audit_log
    (admin_id, action, target_type, target_id, after_state)
  values (
    v_admin,
    case when p_cancel then 'dispute_cancelled' else 'dispute_resolved' end,
    'match', p_match_id,
    case when p_cancel
      then jsonb_build_object('justification', p_justification)
      else jsonb_build_object('winner_id', p_winner_id, 'score1', p_score1,
                              'score2', p_score2, 'justification', p_justification)
    end
  );
end;
$$;

comment on function public.resolve_dispute(uuid, uuid, text, boolean, uuid, integer, integer) is
  'Robustesse : résout un litige de façon ATOMIQUE (verdict/annulation match + '
  'resolve dispute + audit) dans une seule transaction. Gate is_admin().';

revoke execute on function public.resolve_dispute(uuid, uuid, text, boolean, uuid, integer, integer)
  from anon, public;
grant execute on function public.resolve_dispute(uuid, uuid, text, boolean, uuid, integer, integer)
  to authenticated;
