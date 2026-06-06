-- ============================================================================
-- Match de classement (petite finale / 3e place) — optionnel par compétition
-- ============================================================================
-- Ajoute un match opposant les deux PERDANTS des demi-finales, généré quand
-- l'organisateur coche l'option à la création. Repose sur l'avancement assaini
-- (cf. 20260606150000_cascade_via_bracket_nodes).
--
-- Contrat (vérifié par test transactionnel rollback) :
--   * competitions.third_place_match : opt-in admin.
--   * matches.is_third_place : marque le match de classement (rendu bronze côté UI).
--   * bracket_nodes.loser_next_node_id / loser_next_position : sur chaque nœud
--     de demi-finale, pointe le nœud du match 3e place + le slot du perdant.
--   * cascade_match_winner route désormais AUSSI le perdant vers ce match.
-- ----------------------------------------------------------------------------

ALTER TABLE public.competitions
  ADD COLUMN IF NOT EXISTS third_place_match boolean NOT NULL DEFAULT false;

ALTER TABLE public.matches
  ADD COLUMN IF NOT EXISTS is_third_place boolean NOT NULL DEFAULT false;

ALTER TABLE public.bracket_nodes
  ADD COLUMN IF NOT EXISTS loser_next_node_id uuid REFERENCES public.bracket_nodes (id),
  ADD COLUMN IF NOT EXISTS loser_next_position text;

-- Index sur la nouvelle FK (advisor perf 0001_unindexed_foreign_keys).
CREATE INDEX IF NOT EXISTS idx_bracket_nodes_loser_next_node
  ON public.bracket_nodes (loser_next_node_id);

-- Trigger étendu : route le gagnant (via next_node_id, cf. migration précédente)
-- ET le perdant (via loser_next_node_id) vers le match de classement.
CREATE OR REPLACE FUNCTION public.cascade_match_winner()
  RETURNS trigger
  LANGUAGE plpgsql
  SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  v_next_position  text;
  v_next_match_id  uuid;
  v_loser_position text;
  v_loser_match_id uuid;
  v_loser          uuid;
begin
  if ((new.status = 'completed' or new.status = 'forfeited')
      and new.winner_id is not null
      and (old.status is distinct from new.status
           or old.winner_id is distinct from new.winner_id)) then

    -- ─── Avancement du GAGNANT ───────────────────────────────────────
    select bn.next_position into v_next_position
      from public.bracket_nodes bn
      where bn.match_id = new.id
      limit 1;

    v_next_match_id := new.next_match_id;
    if v_next_match_id is null then
      select nn.match_id into v_next_match_id
        from public.bracket_nodes bn
        join public.bracket_nodes nn on nn.id = bn.next_node_id
        where bn.match_id = new.id
        limit 1;
    end if;

    if v_next_match_id is not null then
      if v_next_position = 'player1' then
        update public.matches set player1_id = new.winner_id
          where id = v_next_match_id and player1_id is null;
      elsif v_next_position = 'player2' then
        update public.matches set player2_id = new.winner_id
          where id = v_next_match_id and player2_id is null;
      end if;
    end if;

    -- ─── Routage du PERDANT vers le match de classement (3e place) ────
    select bn.loser_next_position, lnn.match_id
      into v_loser_position, v_loser_match_id
      from public.bracket_nodes bn
      join public.bracket_nodes lnn on lnn.id = bn.loser_next_node_id
      where bn.match_id = new.id
      limit 1;

    if v_loser_match_id is not null then
      v_loser := case
        when new.winner_id = new.player1_id then new.player2_id
        when new.winner_id = new.player2_id then new.player1_id
        else null end;
      if v_loser is not null then
        if v_loser_position = 'player1' then
          update public.matches set player1_id = v_loser
            where id = v_loser_match_id and player1_id is null;
        elsif v_loser_position = 'player2' then
          update public.matches set player2_id = v_loser
            where id = v_loser_match_id and player2_id is null;
        end if;
      end if;
    end if;
  end if;
  return new;
end;
$function$;
