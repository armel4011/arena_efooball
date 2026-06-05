-- =============================================================================
-- ARENA — Sécurité S-1 : fige les colonnes d'intégrité de bracket sur `matches`
-- =============================================================================
-- `guard_matches_protected_columns` (20260605100000) ne gelait que
-- score1/score2/winner_id et la transition status→completed/forfeited. La
-- policy `matches_update` autorise un joueur (auth.uid()=player1_id OR
-- player2_id) à UPDATE TOUTES les autres colonnes de SA ligne → vecteurs
-- d'atteinte à l'intégrité des tournois (audit S-1) :
--   • modifier `player2_id` = substituer son adversaire (la with_check passe
--     toujours car auth.uid() reste = player1_id) ;
--   • repointer `next_match_id` = détourner l'avancement du bracket propagé
--     par le trigger cascade_match_winner ;
--   • changer competition_id/phase_id/group_id/round/match_number = déplacer
--     le match dans l'arbre.
--
-- Correctif : on ÉTEND le même trigger (BEFORE UPDATE, SECURITY INVOKER) pour
-- figer ces 8 colonnes structurelles côté client non-admin. Les colonnes que
-- les flux joueur écrivent légitimement restent mutables :
--   room_code, home_player_id, player1_team_name, player2_team_name,
--   status (non terminal), started_at — cf. match_repository.dart
--   (setRoomCode / setTeamName / markInProgress / flagDisputed).
-- Les admins (is_admin) et le service_role/DEFINER (finalize_match_score,
-- générateurs de bracket) restent libres — eux seuls construisent l'arbre.
-- =============================================================================

create or replace function public.guard_matches_protected_columns()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
begin
  if current_user in ('authenticated', 'anon') and not public.is_admin() then
    -- a) Score et vainqueur figés (posés uniquement via finalize_match_score).
    if new.score1    is distinct from old.score1
       or new.score2    is distinct from old.score2
       or new.winner_id is distinct from old.winner_id
    then
      raise exception 'Modification interdite : le score et le vainqueur d''un match ne peuvent etre poses que via la finalisation serveur (accord des deux joueurs)'
        using errcode = '42501';
    end if;

    -- b) Transition vers un état terminal réservée aux fonctions serveur.
    if new.status is distinct from old.status
       and new.status in ('completed', 'forfeited')
    then
      raise exception 'Modification interdite : passer un match en "%" exige la finalisation serveur', new.status
        using errcode = '42501';
    end if;

    -- c) Colonnes d'intégrité du bracket figées (S-1) : appariement,
    --    chaînage et position dans l'arbre. Aucun flux joueur ne les écrit ;
    --    seuls les admins / générateurs de bracket les posent.
    if new.player1_id    is distinct from old.player1_id
       or new.player2_id    is distinct from old.player2_id
       or new.next_match_id is distinct from old.next_match_id
       or new.competition_id is distinct from old.competition_id
       or new.phase_id      is distinct from old.phase_id
       or new.group_id      is distinct from old.group_id
       or new.round         is distinct from old.round
       or new.match_number  is distinct from old.match_number
    then
      raise exception 'Modification interdite : l''appariement et la position d''un match dans le bracket sont geres par l''organisateur, pas par les joueurs'
        using errcode = '42501';
    end if;
  end if;
  return new;
end;
$$;

comment on function public.guard_matches_protected_columns() is
  '#1 + S-1 : fige score1/score2/winner_id, les transitions completed/forfeited, ET les colonnes de bracket (player1/2_id, next_match_id, competition/phase/group_id, round, match_number) cote joueur RLS. Admins (is_admin) et service_role/DEFINER restent libres.';
