-- ════════════════════════════════════════════════════════════════════
-- Audit 2026-07-01 — Intégrité des preuves + course de planification round
-- ════════════════════════════════════════════════════════════════════
-- Deux correctifs issus de l'audit complet du 2026-07-01 :
--
--   (P1) INTÉGRITÉ DE PREUVE — bucket `match-recordings`.
--        Les policies d'origine (`20260507100001`) laissaient le joueur
--        SUPPRIMER (`owner_delete`) et ÉCRASER (`owner_update`) sans condition
--        les objets de son dossier `{match_id}/{player_id}/…`. Un tricheur
--        pouvait donc, APRÈS `admin_claim_proof` + upload + `proof_verify`
--        (flag `proof_hash_verified=true`), effacer/remplacer la vidéo : l'URL
--        signée admin renvoyait 404 (ou du contenu falsifié) alors que le
--        système la croyait « livrée & vérifiée » → preuve incriminante
--        irrécupérable. Idem sur la capture serveur LiveKit écrite dans son
--        propre dossier.
--        Fix :
--          • DROP `owner_delete` — le client n'a AUCUN besoin légitime de
--            supprimer ; la rétention/purge est faite en service-role par
--            l'EF `cleanup-streams`.
--          • RESTREINDRE `owner_update` — l'upload-on-claim utilise
--            `upsert:true` (rejeu idempotent = UPDATE sur objet existant), on
--            ne peut donc pas la supprimer. On l'autorise UNIQUEMENT tant que
--            la preuve n'est pas encore vérouillée (`proof_hash_verified` non
--            vrai). Le rejeu légitime a lieu avant vérification ; l'écrasement
--            malveillant post-vérification est bloqué.
--
--   (P2) COURSE DE PLANIFICATION DU ROUND SUIVANT.
--        `try_schedule_next_round` compte les matchs non terminés du round
--        SANS verrou. En READ COMMITTED, deux matchs du même round terminés
--        dans deux transactions concurrentes voient chacun « 1 restant » (la
--        complétion de l'autre n'est pas encore committée) → aucune ne
--        planifie le round suivant → bracket figé, compétition jamais
--        clôturée, `generate_payouts` bloqué (gains gelés, pas perdus).
--        Fix : `pg_advisory_xact_lock(hashtext(competition_id), round)` en
--        tête de fonction sérialise les triggers concurrents du MÊME round.
--        Le deuxième trigger attend le commit du premier puis re-compte sur
--        un snapshot frais (nouvelle commande en READ COMMITTED) → voit le
--        match committé. Une clé d'advisory lock unique (pas de FOR UPDATE
--        multi-lignes) évite tout risque de deadlock entre les deux triggers.
-- ════════════════════════════════════════════════════════════════════

-- ─── (P1) match-recordings : retirer le DELETE, borner l'UPDATE ──────
drop policy if exists "match_recordings_owner_delete" on storage.objects;

drop policy if exists "match_recordings_owner_update" on storage.objects;
create policy "match_recordings_owner_update"
  on storage.objects for update
  using (
    bucket_id = 'match-recordings'
    and auth.uid()::text = (storage.foldername(name))[2]
    -- Interdit d'écraser une preuve déjà vérifiée (anti-falsification
    -- post-verify). L'upsert idempotent de l'upload-on-claim a lieu AVANT
    -- que `proof-verify` ne pose `proof_hash_verified` → non affecté.
    and not exists (
      select 1
      from public.streams s
      where s.match_id::text  = (storage.foldername(name))[1]
        and s.player_id::text = (storage.foldername(name))[2]
        and s.proof_hash_verified is true
    )
  );

do $$
begin
  comment on policy "match_recordings_owner_update" on storage.objects is
    'Audit 2026-07-01 — upsert autorisé tant que la preuve n''est pas vérifiée ; '
    'écrasement post-verify bloqué (anti-falsification).';
exception
  when insufficient_privilege then
    raise notice 'Skipping COMMENT on storage.objects policy (not owner) — local/CI stack.';
end$$;

-- ─── (P2) try_schedule_next_round : verrou sur (competition, round) ──
create or replace function public.try_schedule_next_round(p_match_id uuid)
 returns void
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
DECLARE
  v_match            record;
  v_comp             record;
  v_remaining        integer;
  v_next_round       integer;
  v_last_finished    timestamptz;
  v_next_scheduled   timestamptz;
  v_interval_minutes integer;
  v_round_override   integer;
BEGIN
  SELECT * INTO v_match FROM matches WHERE id = p_match_id;
  IF NOT FOUND OR v_match.competition_id IS NULL OR v_match.round IS NULL THEN
    RETURN;
  END IF;

  SELECT * INTO v_comp FROM competitions WHERE id = v_match.competition_id;
  IF NOT FOUND THEN RETURN; END IF;

  -- Sérialise les complétions concurrentes du MÊME round : le 2e trigger
  -- attend le commit du 1er, puis re-compte sur un snapshot frais → voit
  -- bien tous les matchs terminés (sinon le round suivant reste figé).
  PERFORM pg_advisory_xact_lock(hashtext(v_match.competition_id::text), v_match.round);

  SELECT count(*) INTO v_remaining
    FROM matches
   WHERE competition_id = v_match.competition_id
     AND round = v_match.round
     AND status::text NOT IN ('completed', 'forfeited', 'cancelled');
  IF v_remaining > 0 THEN RETURN; END IF;

  v_next_round := v_match.round + 1;

  IF NOT EXISTS (
    SELECT 1 FROM matches
     WHERE competition_id = v_match.competition_id AND round = v_next_round
  ) THEN
    RETURN;
  END IF;

  SELECT max(COALESCE(finished_at, updated_at)) INTO v_last_finished
    FROM matches
   WHERE competition_id = v_match.competition_id AND round = v_match.round;

  -- Lot A.2 : override par round si jsonb fourni.
  -- round_intervals[v_match.round - 1] = délai en min après le round courant.
  v_interval_minutes := v_comp.match_interval_minutes;
  IF v_comp.round_intervals IS NOT NULL AND jsonb_typeof(v_comp.round_intervals) = 'array' THEN
    v_round_override := (v_comp.round_intervals -> (v_match.round - 1))::text::integer;
    IF v_round_override IS NOT NULL AND v_round_override > 0 THEN
      v_interval_minutes := v_round_override;
    END IF;
  END IF;

  v_next_scheduled := COALESCE(v_last_finished, now())
                       + (v_interval_minutes || ' minutes')::interval;

  UPDATE matches
     SET status       = 'scheduled'::match_status,
         scheduled_at = v_next_scheduled,
         updated_at   = now()
   WHERE competition_id = v_match.competition_id
     AND round          = v_next_round
     AND status::text   = 'pending'
     AND player1_id IS NOT NULL
     AND player2_id IS NOT NULL;

  -- WALKOVER : un match du round suivant resté avec un SEUL joueur (l'autre
  -- feeder était un bye / forfait sans adversaire) est auto-gagné par le
  -- joueur présent, sinon il ne devient jamais jouable et le bracket se fige.
  -- Le passage à 'completed' relance cascade_match_winner (propagation du
  -- gagnant) et ce trigger (résolution des rounds suivants en chaîne).
  UPDATE matches
     SET status      = 'completed'::match_status,
         winner_id   = COALESCE(player1_id, player2_id),
         finished_at = now(),
         updated_at  = now()
   WHERE competition_id = v_match.competition_id
     AND round          = v_next_round
     AND status::text   = 'pending'
     AND winner_id IS NULL
     AND (
           (player1_id IS NOT NULL AND player2_id IS NULL)
        OR (player1_id IS NULL AND player2_id IS NOT NULL)
         );
END;
$function$;
