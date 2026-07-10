-- =============================================================================
-- ARENA — Fix régression : le guard streams bloquait l'attache d'URL / la
-- clôture de session (upload preuve + recorder anti-triche cassés)
-- =============================================================================
-- Le ré-audit 2026-07-09 (20260709190000) a introduit
-- `guard_streams_protected_columns()` (BEFORE UPDATE ON streams) qui, pour
-- current_user in ('authenticated','anon'), rejette toute modif d'une longue
-- liste de colonnes. Cette liste a DÉBORDÉ sur `url`, `storage_path`,
-- `started_at`, `ended_at` — précisément les colonnes que le client écrit
-- légitimement quand il attache l'URL d'un enregistrement (`attachUrl`) et clôt
-- sa session (`markEnded`). Résultat : depuis le 09/07, l'upload de preuve vidéo
-- ET le recorder anti-triche natif échouent (42501) sur CHAQUE match ; l'URL
-- n'est jamais persistée → l'admin ne voit aucun enregistrement.
--
-- Correctif : on RESTREINT le guard aux SEULES colonnes d'intégrité anti-triche
-- (commitment/hash de preuve + statut de capture) + l'identité immuable de la
-- ligne. `url`/`storage_path`/`started_at`/`ended_at` sont libérées — elles
-- restent protégées par la policy RLS `streams_*_update_own`
-- (player_id = auth.uid()), donc un joueur ne modifie que SA propre ligne.
-- =============================================================================

create or replace function public.guard_streams_protected_columns()
returns trigger
language plpgsql
set search_path to 'public', 'pg_temp'
as $$
begin
  if current_user in ('authenticated', 'anon') then
    if new.proof_sha256 is distinct from old.proof_sha256
       or new.proof_bytes is distinct from old.proof_bytes
       or new.proof_duration_seconds is distinct from old.proof_duration_seconds
       or new.proof_committed_at is distinct from old.proof_committed_at
       or new.proof_claimed_at is distinct from old.proof_claimed_at
       or new.proof_uploaded_at is distinct from old.proof_uploaded_at
       or new.proof_hash_verified is distinct from old.proof_hash_verified
       or new.capture_status is distinct from old.capture_status
       or new.capture_note is distinct from old.capture_note
       or new.egress_id is distinct from old.egress_id
       or new.provider is distinct from old.provider
       or new.match_id is distinct from old.match_id
       or new.player_id is distinct from old.player_id
    then
      raise exception 'Modification interdite : colonnes de preuve/capture d''un enregistrement reservees au service anti-triche'
        using errcode = '42501';
    end if;
  end if;
  return new;
end;
$$;
