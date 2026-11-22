-- ════════════════════════════════════════════════════════════════════
-- pgTAP — Étape obligatoire « groupe WhatsApp » (migration 20261123120000)
-- ════════════════════════════════════════════════════════════════════
-- Vérifie que :
--   - la normalisation tolère casse / accents / espaces / ponctuation,
--   - le joueur voit l'étape requise mais JAMAIS le nom attendu,
--   - un mauvais nom est refusé, le bon nom (variante) valide l'étape,
--   - le joueur ne peut pas cocher l'étape lui-même (UPDATE direct bloqué,
--     colonne neutralisée à l'INSERT d'inscription),
--   - seul le super-admin règle le groupe.
-- Pattern : rôle `authenticated` + JWT simulé, résultats capturés dans une
-- table temp, assertions après `reset role`.
-- ════════════════════════════════════════════════════════════════════

begin;
select plan(10);

-- ─── Fixtures (superuser) ────────────────────────────────────────────
insert into auth.users(id) values
  ('9a9a9a9a-0000-0000-0000-000000000001'),  -- super-admin
  ('9a9a9a9a-0000-0000-0000-0000000000a1'),  -- joueur existant
  ('9a9a9a9a-0000-0000-0000-0000000000a2');  -- nouvel inscrit (INSERT)
insert into profiles(id,username,email,country_code,referral_code,role,is_active,permanent_ban) values
  ('9a9a9a9a-0000-0000-0000-000000000001','wa_sa','wasa@ci.invalid','CI','WASA','super_admin',true,false),
  ('9a9a9a9a-0000-0000-0000-0000000000a1','wa_p1','wap1@ci.invalid','CI','WAP1','player',true,false);

update whatsapp_group_config
   set invite_url = 'https://chat.whatsapp.com/ABCdef123',
       group_name = 'Arena Communauté 🏆'
 where id = 1;

-- (1) Normalisation.
select is(
  public._normalize_group_name('  ARÉNA communaute! '),
  'arenacommunaute',
  'normalisation : casse, accents, espaces et ponctuation ignorés'
);

create temp table _r(test text primary key, result text) on commit drop;
grant all on _r to authenticated;

-- ─── Acte 1 — JOUEUR (…a1) ──────────────────────────────────────────
set local role authenticated;
set local request.jwt.claims = '{"sub":"9a9a9a9a-0000-0000-0000-0000000000a1"}';

insert into _r select 'status_before', required::text || '/' || joined::text
  from public.my_whatsapp_group_status();
insert into _r select 'config_rows_player', count(*)::text from public.whatsapp_group_config;
insert into _r values ('wrong_name', public.confirm_whatsapp_group('Arena Fans')::text);

do $$ begin
  update public.profiles set whatsapp_group_joined_at = now()
   where id = '9a9a9a9a-0000-0000-0000-0000000000a1';
  insert into _r values ('self_tick', 'allowed');
exception when others then
  insert into _r values ('self_tick', 'blocked');
end $$;

do $$ begin
  perform public.set_whatsapp_group_config('https://chat.whatsapp.com/hack', 'hack');
  insert into _r values ('player_set_config', 'allowed');
exception when others then
  insert into _r values ('player_set_config', 'blocked');
end $$;

insert into _r values ('right_name', public.confirm_whatsapp_group('arena communaute')::text);
insert into _r select 'status_after', required::text || '/' || joined::text
  from public.my_whatsapp_group_status();

-- ─── Acte 2 — NOUVEL INSCRIT (…a2) tente de pré-cocher à l'INSERT ────
set local request.jwt.claims = '{"sub":"9a9a9a9a-0000-0000-0000-0000000000a2"}';
insert into public.profiles(id,username,email,country_code,role,is_active,whatsapp_group_joined_at)
  values ('9a9a9a9a-0000-0000-0000-0000000000a2','wa_p2','wap2@ci.invalid','CI','player',true, now());

-- ─── Acte 3 — SUPER-ADMIN ───────────────────────────────────────────
set local request.jwt.claims = '{"sub":"9a9a9a9a-0000-0000-0000-000000000001"}';
do $$ begin
  perform public.set_whatsapp_group_config('https://chat.whatsapp.com/NEW123', 'Arena Officiel');
  insert into _r values ('sa_set_config', 'allowed');
exception when others then
  insert into _r values ('sa_set_config', 'blocked: ' || sqlerrm);
end $$;

reset role;

-- ─── Assertions ─────────────────────────────────────────────────────
select is((select result from _r where test = 'status_before'), 'true/false',
  'joueur : étape requise et pas encore validée');
select is((select result from _r where test = 'config_rows_player'), '0',
  'joueur : la config (nom attendu) est illisible');
select is((select result from _r where test = 'wrong_name'), 'false',
  'joueur : un mauvais nom est refusé');
select is((select result from _r where test = 'self_tick'), 'blocked',
  'joueur : impossible de cocher l''étape par UPDATE direct');
select is((select result from _r where test = 'player_set_config'), 'blocked',
  'joueur : impossible de régler le groupe');
select is((select result from _r where test = 'right_name'), 'true',
  'joueur : le bon nom (variante casse/accents) valide l''étape');
select is((select result from _r where test = 'status_after'), 'true/true',
  'joueur : étape validée après le bon nom');
select ok(
  (select whatsapp_group_joined_at is null from profiles
    where id = '9a9a9a9a-0000-0000-0000-0000000000a2'),
  'nouvel inscrit : la colonne est neutralisée à l''INSERT client'
);
select is((select result from _r where test = 'sa_set_config'), 'allowed',
  'super-admin : peut régler le groupe');

select * from finish();
rollback;
