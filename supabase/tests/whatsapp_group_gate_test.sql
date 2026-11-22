-- ════════════════════════════════════════════════════════════════════
-- pgTAP — Groupes WhatsApp obligatoires (migrations 20261123120000 →
-- 20261123140000 : nombre illimité, identifiant stable, bascule auto)
-- ════════════════════════════════════════════════════════════════════
-- Vérifie que :
--   - la normalisation tolère casse / accents / espaces / ponctuation,
--   - le joueur reçoit le lien du 1er groupe non plein, jamais les noms,
--   - BASCULE : groupe 1 plein → le joueur suivant reçoit le lien du 2,
--   - le nom de N'IMPORTE quel groupe valide ; on enregistre lequel,
--   - le joueur ne peut ni cocher l'étape ni choisir son groupe lui-même
--     (UPDATE bloqué, colonnes neutralisées à l'INSERT d'inscription),
--   - seul le super-admin règle les groupes ; noms en double refusés ;
--     plus de 5 groupes acceptés ; ré-enregistrer conserve les compteurs.
-- Pattern : rôle `authenticated` + JWT simulé, résultats capturés dans une
-- table temp, assertions après `reset role`.
-- ════════════════════════════════════════════════════════════════════

begin;
select plan(17);

-- ─── Fixtures (superuser) ────────────────────────────────────────────
insert into auth.users(id) values
  ('9a9a9a9a-0000-0000-0000-000000000001'),  -- super-admin
  ('9a9a9a9a-0000-0000-0000-0000000000a1'),  -- joueur 1
  ('9a9a9a9a-0000-0000-0000-0000000000a2'),  -- joueur 2
  ('9a9a9a9a-0000-0000-0000-0000000000a3');  -- nouvel inscrit (INSERT)
insert into profiles(id,username,email,country_code,referral_code,role,is_active,permanent_ban) values
  ('9a9a9a9a-0000-0000-0000-000000000001','wa_sa','wasa@ci.invalid','CI','WASA','super_admin',true,false),
  ('9a9a9a9a-0000-0000-0000-0000000000a1','wa_p1','wap1@ci.invalid','CI','WAP1','player',true,false),
  ('9a9a9a9a-0000-0000-0000-0000000000a2','wa_p2','wap2@ci.invalid','CI','WAP2','player',true,false);

-- Groupe 1 de capacité 1 (pour tester la bascule), groupe 2 normal.
insert into whatsapp_groups(sort_order, invite_url, group_name, capacity) values
  (1, 'https://chat.whatsapp.com/GRP001', 'Arena_Game 001', 1),
  (2, 'https://chat.whatsapp.com/GRP002', 'Arena_Game 002', 1020);

-- Ids des groupes, lisibles par les rôles simulés (le joueur ne peut pas
-- lire whatsapp_groups).
create temp table _ids on commit drop as
  select sort_order as n, id from whatsapp_groups;
grant select on _ids to authenticated;

-- (1) Normalisation.
select is(
  public._normalize_group_name('  ARENA_game 001! '),
  'arenagame001',
  'normalisation : casse, espaces, underscore et ponctuation ignorés'
);

create temp table _r(test text primary key, result text) on commit drop;
grant all on _r to authenticated;

-- ─── Acte 1 — JOUEUR 1 ──────────────────────────────────────────────
set local role authenticated;
set local request.jwt.claims = '{"sub":"9a9a9a9a-0000-0000-0000-0000000000a1"}';

insert into _r select 'status_p1',
  required::text || '/' || joined::text || '/' || coalesce(invite_url, '')
  from public.my_whatsapp_group_status();
insert into _r select 'rows_player', count(*)::text from public.whatsapp_groups;
insert into _r values ('wrong_name', public.confirm_whatsapp_group('Arena_Game 009')::text);

do $$ begin
  update public.profiles set whatsapp_group_joined_at = now()
   where id = '9a9a9a9a-0000-0000-0000-0000000000a1';
  insert into _r values ('self_tick', 'allowed');
exception when others then
  insert into _r values ('self_tick', 'blocked');
end $$;

do $$ begin
  update public.profiles set whatsapp_group_id = (select id from _ids where n = 2)
   where id = '9a9a9a9a-0000-0000-0000-0000000000a1';
  insert into _r values ('self_group', 'allowed');
exception when others then
  insert into _r values ('self_group', 'blocked');
end $$;

do $$ begin
  perform public.set_whatsapp_groups(
    '[{"invite_url":"https://chat.whatsapp.com/hack","group_name":"hack"}]'::jsonb);
  insert into _r values ('player_set_groups', 'allowed');
exception when others then
  insert into _r values ('player_set_groups', 'blocked');
end $$;

insert into _r values ('right_name_p1', public.confirm_whatsapp_group('arena game 001')::text);

-- ─── Acte 2 — JOUEUR 2 : groupe 1 désormais plein → bascule ──────────
set local request.jwt.claims = '{"sub":"9a9a9a9a-0000-0000-0000-0000000000a2"}';
insert into _r select 'status_p2',
  required::text || '/' || joined::text || '/' || coalesce(invite_url, '')
  from public.my_whatsapp_group_status();
insert into _r values ('right_name_p2', public.confirm_whatsapp_group('ARENA GAME 002')::text);

-- ─── Acte 3 — NOUVEL INSCRIT tente de pré-cocher à l'INSERT ─────────
set local request.jwt.claims = '{"sub":"9a9a9a9a-0000-0000-0000-0000000000a3"}';
insert into public.profiles(id,username,email,country_code,role,is_active,
                            whatsapp_group_joined_at,whatsapp_group_id)
  values ('9a9a9a9a-0000-0000-0000-0000000000a3','wa_p3','wap3@ci.invalid','CI',
          'player',true, now(), (select id from _ids where n = 1));

-- ─── Acte 4 — SUPER-ADMIN ───────────────────────────────────────────
set local request.jwt.claims = '{"sub":"9a9a9a9a-0000-0000-0000-000000000001"}';
do $$ begin
  perform public.set_whatsapp_groups(
    '[{"invite_url":"https://chat.whatsapp.com/A1","group_name":"Arena_Game 001"},
      {"invite_url":"https://chat.whatsapp.com/A2","group_name":"arena game 001"}]'::jsonb);
  insert into _r values ('sa_duplicate', 'allowed');
exception when others then
  insert into _r values ('sa_duplicate', 'blocked');
end $$;

-- 6 groupes (> 5) : les 2 existants conservés par id + 4 nouveaux.
do $$ begin
  perform public.set_whatsapp_groups(
    jsonb_build_array(
      jsonb_build_object('id', (select id from _ids where n = 1),
        'invite_url', 'https://chat.whatsapp.com/GRP001', 'group_name', 'Arena_Game 001'),
      jsonb_build_object('id', (select id from _ids where n = 2),
        'invite_url', 'https://chat.whatsapp.com/GRP002', 'group_name', 'Arena_Game 002'))
    || (select jsonb_agg(jsonb_build_object(
          'invite_url', 'https://chat.whatsapp.com/GRP' || lpad(n::text, 3, '0'),
          'group_name', 'Arena_Game ' || lpad(n::text, 3, '0')))
          from generate_series(3, 6) n));
  insert into _r values ('sa_set_six', 'allowed');
exception when others then
  insert into _r values ('sa_set_six', 'blocked: ' || sqlerrm);
end $$;

reset role;

-- ─── Assertions ─────────────────────────────────────────────────────
select is((select result from _r where test = 'status_p1'),
  'true/false/https://chat.whatsapp.com/GRP001',
  'joueur 1 : étape requise, lien du groupe 1');
select is((select result from _r where test = 'rows_player'), '0',
  'joueur : les groupes (et leurs noms) sont illisibles');
select is((select result from _r where test = 'wrong_name'), 'false',
  'joueur : un nom ne correspondant à aucun groupe est refusé');
select is((select result from _r where test = 'self_tick'), 'blocked',
  'joueur : impossible de cocher l''étape par UPDATE direct');
select is((select result from _r where test = 'self_group'), 'blocked',
  'joueur : impossible de choisir son groupe par UPDATE direct');
select is((select result from _r where test = 'player_set_groups'), 'blocked',
  'joueur : impossible de régler les groupes');
select is((select result from _r where test = 'right_name_p1'), 'true',
  'joueur 1 : le nom (variante) du groupe 1 valide l''étape');
select is((select result from _r where test = 'status_p2'),
  'true/false/https://chat.whatsapp.com/GRP002',
  'BASCULE : groupe 1 plein → joueur 2 reçoit le lien du groupe 2');
select is((select result from _r where test = 'right_name_p2'), 'true',
  'joueur 2 : le nom du groupe 2 valide l''étape');
select is(
  (select whatsapp_group_id from profiles where id = '9a9a9a9a-0000-0000-0000-0000000000a2'),
  (select id from _ids where n = 2),
  'joueur 2 rattaché au groupe 2 (compteur du bon groupe)');
select ok(
  (select whatsapp_group_joined_at is null and whatsapp_group_id is null
     from profiles where id = '9a9a9a9a-0000-0000-0000-0000000000a3'),
  'nouvel inscrit : colonnes neutralisées à l''INSERT client'
);
select is((select result from _r where test = 'sa_duplicate'), 'blocked',
  'super-admin : deux groupes au même nom (normalisé) sont refusés');
select is((select result from _r where test = 'sa_set_six'), 'allowed',
  'super-admin : peut enregistrer plus de 5 groupes');
select is((select count(*) from whatsapp_groups), 6::bigint,
  '6 groupes enregistrés');
select is(
  (select whatsapp_group_id from profiles where id = '9a9a9a9a-0000-0000-0000-0000000000a1'),
  (select id from _ids where n = 1),
  'ré-enregistrement : joueur 1 toujours rattaché au même groupe (id stable)');
select is(
  (select string_agg(group_name, ',' order by sort_order) from whatsapp_groups),
  'Arena_Game 001,Arena_Game 002,Arena_Game 003,Arena_Game 004,Arena_Game 005,Arena_Game 006',
  'ordre des groupes conforme à la liste enregistrée');

select * from finish();
rollback;
