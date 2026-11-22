-- ════════════════════════════════════════════════════════════════════
-- pgTAP — Activation des jeux (migration 20261124120000)
-- ════════════════════════════════════════════════════════════════════
-- Vérifie que :
--   - seul le super-admin (dés)active un jeu ;
--   - un jeu désactivé refuse toute NOUVELLE compétition (INSERT) et tout
--     passage d'une compétition vers ce jeu (UPDATE OF game) ;
--   - une compétition EXISTANTE d'un jeu désactivé reste modifiable ;
--   - un jeu actif accepte la création ;
--   - le dernier jeu actif ne peut pas être désactivé ;
--   - la table est lisible publiquement.
-- ════════════════════════════════════════════════════════════════════

begin;
select plan(9);

insert into auth.users(id) values
  ('8b8b8b8b-0000-0000-0000-000000000001'),  -- super-admin
  ('8b8b8b8b-0000-0000-0000-000000000002');  -- admin simple
insert into profiles(id,username,email,country_code,referral_code,role,is_active,permanent_ban) values
  ('8b8b8b8b-0000-0000-0000-000000000001','gs_sa','gssa@ci.invalid','CI','GSSA','super_admin',true,false),
  ('8b8b8b8b-0000-0000-0000-000000000002','gs_adm','gsadm@ci.invalid','CI','GSADM','admin',true,false);

-- Compétition existante sur dream_league (avant désactivation).
insert into competitions(id,name,game,format,status,start_date,max_players,registration_currency) values
  ('8c8c8c8c-0000-0000-0000-000000000001','GS_EXIST','dream_league','single_elimination',
   'registration_open', now() + interval '1 day', 4, 'XAF'),
  ('8c8c8c8c-0000-0000-0000-000000000002','GS_OTHER','efootball','single_elimination',
   'registration_open', now() + interval '1 day', 4, 'XAF');

create temp table _r(test text primary key, result text) on commit drop;
grant all on _r to authenticated;

-- ─── Admin simple : ne peut pas régler les jeux ──────────────────────
set local role authenticated;
set local request.jwt.claims = '{"sub":"8b8b8b8b-0000-0000-0000-000000000002"}';
do $$ begin
  perform public.set_game_enabled('dream_league', false);
  insert into _r values ('admin_toggle', 'allowed');
exception when others then
  insert into _r values ('admin_toggle', 'blocked');
end $$;
insert into _r select 'public_read', count(*)::text from public.game_settings;

-- ─── Super-admin : désactive dream_league ────────────────────────────
set local request.jwt.claims = '{"sub":"8b8b8b8b-0000-0000-0000-000000000001"}';
select public.set_game_enabled('dream_league', false);
do $$ begin
  perform public.set_game_enabled('efootball', false);
  perform public.set_game_enabled('draughts', false);
  perform public.set_game_enabled('ea_sports_fc', false);
  insert into _r values ('disable_all', 'allowed');
exception when others then
  insert into _r values ('disable_all', 'blocked');
end $$;
reset role;

-- ─── Garde de création (superuser : le trigger s'applique à tous) ────
do $$ begin
  insert into competitions(name,game,format,status,start_date,max_players,registration_currency)
  values ('GS_NEW','dream_league','single_elimination','draft', now() + interval '1 day', 4, 'XAF');
  insert into _r values ('create_disabled', 'allowed');
exception when others then
  insert into _r values ('create_disabled', 'blocked');
end $$;
do $$ begin
  insert into competitions(name,game,format,status,start_date,max_players,registration_currency)
  values ('GS_NEW2','efootball','single_elimination','draft', now() + interval '1 day', 4, 'XAF');
  insert into _r values ('create_enabled', 'allowed');
exception when others then
  insert into _r values ('create_enabled', 'blocked');
end $$;
do $$ begin
  update competitions set game = 'dream_league'
   where id = '8c8c8c8c-0000-0000-0000-000000000002';
  insert into _r values ('switch_to_disabled', 'allowed');
exception when others then
  insert into _r values ('switch_to_disabled', 'blocked');
end $$;
do $$ begin
  update competitions set name = 'GS_EXIST_RENAMED'
   where id = '8c8c8c8c-0000-0000-0000-000000000001';
  insert into _r values ('existing_update', 'allowed');
exception when others then
  insert into _r values ('existing_update', 'blocked');
end $$;

-- ─── Assertions ─────────────────────────────────────────────────────
select is((select result from _r where test = 'admin_toggle'), 'blocked',
  'admin simple : ne peut pas (dés)activer un jeu');
select ok((select result from _r where test = 'public_read')::int >= 4,
  'la table game_settings est lisible');
select is((select is_enabled from game_settings where game = 'dream_league'), false,
  'super-admin : dream_league désactivé');
select is((select result from _r where test = 'disable_all'), 'blocked',
  'le dernier jeu actif ne peut pas être désactivé');
select is((select count(*) from game_settings where is_enabled), 3::bigint,
  'les 3 autres jeux restent actifs (rollback de la tentative)');
select is((select result from _r where test = 'create_disabled'), 'blocked',
  'création refusée sur un jeu désactivé');
select is((select result from _r where test = 'create_enabled'), 'allowed',
  'création autorisée sur un jeu actif');
select is((select result from _r where test = 'switch_to_disabled'), 'blocked',
  'basculer une compétition vers un jeu désactivé est refusé');
select is((select result from _r where test = 'existing_update'), 'allowed',
  'une compétition existante d''un jeu désactivé reste modifiable');

select * from finish();
rollback;
