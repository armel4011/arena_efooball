-- =============================================================================
-- ARENA — Anti-triche Phase 3 : RPC admin « réclamer la vidéo » sur litige
-- =============================================================================
-- Le joueur a engagé un commitment (hash du proxy 360p) à la fin du match, mais
-- la vidéo elle-même n'est PAS uploadée par défaut (économie réseau/coût). Quand
-- un litige l'exige, l'admin la RÉCLAME : on estampille `proof_claimed_at` et on
-- notifie le joueur (FCM via le trigger AFTER INSERT sur notifications). À sa
-- prochaine connexion, l'app uploade le proxy puis appelle l'EF proof-verify qui
-- compare le hash livré au commitment.
--
-- SECURITY DEFINER + garde is_admin() : écrit `streams` (RLS service-role) et
-- crée une notification pour autrui — réservé aux admins. EXECUTE révoqué à
-- anon/public.
-- =============================================================================

create or replace function public.admin_claim_proof(p_stream_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_stream      public.streams%rowtype;
  v_was_claimed boolean;
  v_claimed_at  timestamptz;
begin
  if not public.is_admin() then
    raise exception 'Reserve aux administrateurs' using errcode = '42501';
  end if;

  select * into v_stream from public.streams where id = p_stream_id;
  if not found then
    raise exception 'Enregistrement introuvable' using errcode = 'P0002';
  end if;

  -- On ne peut réclamer que ce qui a été engagé.
  if v_stream.proof_sha256 is null then
    raise exception 'Aucun commitment a reclamer pour cet enregistrement'
      using errcode = 'P0001';
  end if;

  -- Déjà livré : rien à faire, on évite une notification inutile.
  if v_stream.proof_uploaded_at is not null then
    return jsonb_build_object(
      'ok', true,
      'already_uploaded', true,
      'verified', v_stream.proof_hash_verified,
      'player_id', v_stream.player_id
    );
  end if;

  v_was_claimed := v_stream.proof_claimed_at is not null;

  -- Idempotent : la PREMIÈRE réclamation fait foi (engagement d'upload du joueur).
  update public.streams
     set proof_claimed_at = coalesce(proof_claimed_at, now())
   where id = p_stream_id
   returning proof_claimed_at into v_claimed_at;

  -- Notifier le joueur. Re-réclamer alors qu'aucun upload n'est arrivé = relance
  -- légitime → on (re)notifie. Le trigger trg_notifications_dispatch pousse le FCM.
  insert into public.notifications (user_id, type, title, body, data)
  values (
    v_stream.player_id,
    'proof_claim_request',
    'Video demandee',
    'Un administrateur demande la video de ton match. Ouvre l''app connecte pour l''envoyer.',
    jsonb_build_object(
      'match_id', v_stream.match_id,
      'stream_id', v_stream.id,
      'route', '/match/' || v_stream.match_id::text
    )
  );

  return jsonb_build_object(
    'ok', true,
    'claimed_at', v_claimed_at,
    're_claimed', v_was_claimed,
    'player_id', v_stream.player_id
  );
end;
$$;

revoke execute on function public.admin_claim_proof(uuid) from anon, public;
grant execute on function public.admin_claim_proof(uuid) to authenticated;

comment on function public.admin_claim_proof(uuid) is
  'Admin : réclame la vidéo de preuve (Phase 3 anti-triche). Estampille streams.proof_claimed_at et notifie le joueur (FCM). Idempotent ; ne re-notifie pas si déjà uploadé.';
