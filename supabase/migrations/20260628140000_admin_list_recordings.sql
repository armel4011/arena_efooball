-- =============================================================================
-- ARENA — RPC admin : liste des enregistrements anti-triche (consultation)
-- =============================================================================
-- Donne à l'admin un accès direct aux captures anti-triche (recorder natif +
-- LiveKit Track Egress), indépendamment d'un litige ouvert. Joint le match, la
-- compétition et les joueurs pour faciliter la recherche/corrélation côté admin.
--
-- Comme la rétention est de 1 jour (cleanup-streams), le jeu de données reste
-- petit : pas de pagination lourde, un simple `limit` borné suffit. Le filtrage
-- texte (compétition / joueur) est fait côté client sur ce résultat.
--
-- SECURITY DEFINER + garde is_admin() : contourne la RLS pour joindre profiles,
-- mais réservé aux admins. EXECUTE révoqué à anon/public.
-- =============================================================================

create or replace function public.admin_list_recordings(p_limit integer default 100)
returns table (
  recording_id       uuid,
  match_id           uuid,
  competition_id     uuid,
  competition_name   text,
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
  order by s.started_at desc nulls last
  limit greatest(1, least(coalesce(p_limit, 100), 500));
end;
$$;

revoke execute on function public.admin_list_recordings(integer) from anon, public;
grant execute on function public.admin_list_recordings(integer) to authenticated;
