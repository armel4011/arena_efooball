-- ============================================================================
-- Assainit l'avancement des brackets (pré-requis du match de classement 3e place)
-- ============================================================================
-- Deux bugs latents corrigés dans le trigger `cascade_match_winner` :
--
-- 1) Le générateur Dart (admin_bracket_repository._persistPlan, utilisé par
--    l'UI admin mobile ET desktop) câble `bracket_nodes.next_node_id` mais
--    JAMAIS `matches.next_match_id`. Or le trigger ne lisait QUE
--    `new.next_match_id` -> les gagnants des brackets générés côté Dart
--    n'avançaient pas. (Seul le générateur SQL `generate_single_elim_bracket`
--    renseigne next_match_id.) On dérive désormais le match suivant via
--    `bracket_nodes.next_node_id` en repli quand `next_match_id` est NULL,
--    ce qui fait fonctionner LES DEUX chemins de génération.
--
-- 2) Le trigger ne se déclenchait que sur `status = 'completed'`. Les matchs
--    `forfeited` (byes auto-résolus + forfaits joueur) n'avançaient donc pas
--    leur vainqueur. On gère maintenant `completed` OU `forfeited`.
--
-- Vérifié en amont par tests transactionnels rollback (avancement gagnant via
-- bracket_nodes + avancement d'un bye forfaité). Comportement du chemin SQL
-- (next_match_id présent) inchangé : il reste prioritaire.
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.cascade_match_winner()
  RETURNS trigger
  LANGUAGE plpgsql
  SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  v_next_position text;
  v_next_match_id uuid;
begin
  if ((new.status = 'completed' or new.status = 'forfeited')
      and new.winner_id is not null
      and (old.status is distinct from new.status
           or old.winner_id is distinct from new.winner_id)) then

    select bn.next_position into v_next_position
      from public.bracket_nodes bn
      where bn.match_id = new.id
      limit 1;

    -- Priorité au champ direct (générateur SQL), repli sur bracket_nodes
    -- (générateur Dart, qui ne pose pas matches.next_match_id).
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
  end if;
  return new;
end;
$function$;
