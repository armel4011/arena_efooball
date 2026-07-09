-- =============================================================================
-- ARENA — Cloisonnement pays des médias anti-triche (recordings)
-- =============================================================================
-- Constat audit 2026-07-07 : l'infra de scoping pays (profiles.admin_allowed_
-- countries + helper admin_can_country + competitions.country_code) existe mais
-- n'est câblée QUE sur les payouts (20260706100400_admin_scoping). Les
-- enregistrements anti-triche restent lisibles par TOUT admin, tous pays.
--
-- Décision produit : miroir des payouts. Un admin simple ne voit/réclame que les
-- enregistrements dont le PAYS DE LA COMPÉTITION (competitions.country_code, le
-- pays organisateur — même dimension que le scoping payouts) ∈ ses pays
-- autorisés. Un super-admin (admin_allowed_countries NULL) voit tout — sémantique
-- portée par admin_can_country (NULL = pas de restriction).
--
-- Chemin pays : streams.match_id → matches.competition_id → competitions.country_code.
--
-- Trois surfaces fermées :
--   1. RPC admin_list_recordings : filtre pays + expose country_code.
--   2. Lecture des objets (bucket match-recordings) : policy storage
--      match_recordings_admin_read réécrite avec la jointure pays. L'URL signée
--      reste fabriquée côté client (createSignedUrl) → automatiquement scopée.
--   3. RPC admin_claim_proof : garde pays avant la réclamation.
--
-- Fail-closed : pour un admin RESTREINT, un objet dont le pays est irrésolvable
-- (match/compétition manquant, chemin malformé) → country NULL → admin_can_country
-- renvoie false → refusé. Un super-admin (scope NULL) reste autorisé.
-- =============================================================================
-- Depends on: 20260706100400 (admin_can_country), 20260706100000
--   (competitions.country_code), 20260628140000 (admin_list_recordings),
--   20260629130000 (admin_claim_proof), 20260507100001 (bucket + policies).
-- =============================================================================

-- ─── 1. RPC admin_list_recordings : filtre pays + colonne country_code ──────
-- La signature (RETURNS TABLE) gagne une colonne → drop + recreate obligatoire.
drop function if exists public.admin_list_recordings(integer);
create function public.admin_list_recordings(p_limit integer default 100)
returns table (
  recording_id       uuid,
  match_id           uuid,
  competition_id     uuid,
  competition_name   text,
  country_code       text,
  game               text,
  provider           text,
  storage_path       text,
  url                text,
  player_id          uuid,
  player_username    text,
  opponent_username  text,
  started_at         timestamptz,
  ended_at           timestamptz,
  has_open_dispute   boolean
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if not public.is_admin() then
    raise exception 'Reserve aux administrateurs' using errcode = '42501';
  end if;

  return query
  select
    s.id,
    s.match_id,
    m.competition_id,
    c.name,
    c.country_code,
    c.game::text,
    s.provider,
    s.storage_path,
    s.url,
    s.player_id,
    pp.username,
    po.username,
    s.started_at,
    s.ended_at,
    exists (
      select 1 from public.disputes d
      where d.match_id = s.match_id
        and d.status in ('open', 'bot_review', 'admin_review')
    )
  from public.streams s
  join public.matches m on m.id = s.match_id
  left join public.competitions c on c.id = m.competition_id
  left join public.profiles pp on pp.id = s.player_id
  left join public.profiles po on po.id = (
    case when m.player1_id = s.player_id then m.player2_id else m.player1_id end
  )
  where s.is_public = false
    and (s.storage_path is not null or s.url is not null)
    -- Cloisonnement pays : super-admin (scope NULL) → tout ; admin restreint →
    -- ses pays uniquement. c.country_code NULL (compétition manquante) → refusé
    -- pour un restreint, visible pour un super-admin.
    and public.admin_can_country(auth.uid(), c.country_code)
  order by s.started_at desc nulls last
  limit greatest(1, least(coalesce(p_limit, 100), 500));
end;
$$;

revoke execute on function public.admin_list_recordings(integer) from anon, public;
grant execute on function public.admin_list_recordings(integer) to authenticated;

comment on function public.admin_list_recordings(integer) is
  'Admin : liste des enregistrements anti-triche. Cloisonné par pays '
  '(competitions.country_code via admin_can_country) : un admin restreint ne '
  'voit que ses pays, un super-admin voit tout. SECURITY DEFINER + garde is_admin.';

-- ─── 2. Policy storage : lecture admin scopée pays ──────────────────────────
-- La signature d'URL reste côté client (createSignedUrl) et s'appuie sur cette
-- policy → la restreindre suffit à cloisonner la lecture des objets.
drop policy if exists "match_recordings_admin_read" on storage.objects;
create policy "match_recordings_admin_read"
  on storage.objects for select
  using (
    bucket_id = 'match-recordings'
    and exists (
      select 1
      from public.profiles p
      where p.id = auth.uid()
        and p.role in ('admin', 'super_admin')
    )
    -- Pays de la compétition du match (1er segment du chemin = match_id).
    -- admin_can_country : NULL scope → true (super-admin) ; restreint → pays ∈
    -- liste ; pays irrésolvable → false (fail-closed pour un restreint).
    and public.admin_can_country(
      auth.uid(),
      (
        select c.country_code
        from public.matches m
        join public.competitions c on c.id = m.competition_id
        where m.id::text = (storage.foldername(storage.objects.name))[1]
      )
    )
  );

-- COMMENT ON POLICY exige d'être owner de storage.objects (hosted OK, local/CI
-- non → 42501). Bloc gardé, purement documentaire.
do $$
begin
  comment on policy "match_recordings_admin_read" on storage.objects is
    'Admins lisent les enregistrements de LEURS pays (competitions.country_code '
    'via admin_can_country) ; super-admin (scope NULL) lit tout.';
exception
  when insufficient_privilege then
    raise notice 'Skipping COMMENT on match_recordings_admin_read (not owner of storage.objects) — local/CI stack.';
end$$;

-- ─── 3. RPC admin_claim_proof : garde pays ──────────────────────────────────
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
  v_country     text;
begin
  if not public.is_admin() then
    raise exception 'Reserve aux administrateurs' using errcode = '42501';
  end if;

  select * into v_stream from public.streams where id = p_stream_id;
  if not found then
    raise exception 'Enregistrement introuvable' using errcode = 'P0002';
  end if;

  -- Cloisonnement pays : un admin restreint ne réclame que dans ses pays. Pays
  -- irrésolvable → admin_can_country false pour un restreint (fail-closed),
  -- true pour un super-admin (scope NULL).
  select c.country_code into v_country
    from public.matches m
    join public.competitions c on c.id = m.competition_id
    where m.id = v_stream.match_id;
  if not public.admin_can_country(auth.uid(), v_country) then
    raise exception 'Enregistrement hors de votre perimetre pays'
      using errcode = '42501';
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
  'Admin : réclame la vidéo de preuve (Phase 3 anti-triche). Cloisonné par pays '
  '(competitions.country_code via admin_can_country). Estampille '
  'streams.proof_claimed_at et notifie le joueur (FCM). Idempotent.';
