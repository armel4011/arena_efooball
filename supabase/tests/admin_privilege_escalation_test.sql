-- ════════════════════════════════════════════════════════════════════
-- pgTAP — Audit 2026-07-07 : fermeture des escalades « admin simple »
-- ════════════════════════════════════════════════════════════════════
-- Couvre la migration 20260707120000 :
--   P1 #1a  guard_matches_protected_columns (verrou re-décision, comp à prix) :
--            - admin simple ne peut PAS inverser un winner_id déjà posé,
--            - ni ré-arbitrer un match terminal,
--            - MAIS la 1re saisie reste ouverte,
--            - comp SANS prix : inchangé (ouvert),
--            - super-admin : autorisé.
--   P1 #1b  guard_registrations_final_rank (comp à prix CLÔTURÉE) :
--            - admin simple bloqué, comp sans prix OK, super-admin OK.
--   P1 #2   reintegration_admin_update → is_super_admin() (RLS filtre l'admin
--            simple à 0 ligne ; le super-admin débannit).
--
-- Pattern (cf. payments_payouts_rls_test) : on bascule en rôle `authenticated`
-- avec JWT simulé pour exercer la RLS + les guards (current_user='authenticated'),
-- on capture le résultat dans une table temp, puis on `reset role` AVANT les
-- assertions pgTAP (qui tournent en superuser).
-- ════════════════════════════════════════════════════════════════════

begin;
select plan(11);

-- Triggers de cascade/stats/planif neutralisés : on teste le guard, pas
-- l'avancement du tournoi.
alter table public.matches disable trigger trg_matches_cascade_winner;
alter table public.matches disable trigger trg_matches_finalize_competition;
alter table public.matches disable trigger trg_matches_increment_stats;
alter table public.matches disable trigger trg_matches_recalc_group_standings;
alter table public.matches disable trigger z_auto_schedule_next_round_on_match_complete;
alter table public.matches disable trigger trg_matches_auto_publish_final;
alter table public.matches disable trigger trg_notify_match_room_activated_upd;

-- ─── Fixtures (superuser : bypass RLS) ──────────────────────────────
insert into auth.users(id) values
  ('7a7a7a7a-0000-0000-0000-000000000001'),  -- admin simple
  ('7a7a7a7a-0000-0000-0000-000000000002'),  -- super-admin
  ('7a7a7a7a-0000-0000-0000-0000000000a1'),  -- player1
  ('7a7a7a7a-0000-0000-0000-0000000000a2'),  -- player2
  ('7a7a7a7a-0000-0000-0000-0000000000b9');  -- banni à vie (réintégration)
insert into profiles(id,username,email,country_code,referral_code,role,is_active,permanent_ban) values
  ('7a7a7a7a-0000-0000-0000-000000000001','pe_adm','pea@ci.invalid','CI','PEA','admin',true,false),
  ('7a7a7a7a-0000-0000-0000-000000000002','pe_sa','pesa@ci.invalid','CI','PESA','super_admin',true,false),
  ('7a7a7a7a-0000-0000-0000-0000000000a1','pe_p1','pe1@ci.invalid','CI','PEP1','player',true,false),
  ('7a7a7a7a-0000-0000-0000-0000000000a2','pe_p2','pe2@ci.invalid','CI','PEP2','player',true,false),
  ('7a7a7a7a-0000-0000-0000-0000000000b9','pe_ban','peb@ci.invalid','CI','PEBAN','player',false,true);

-- comp à prix (ongoing) / comp sans prix (ongoing) / comp à prix CLÔTURÉE.
insert into competitions(id,name,game,format,status,start_date,max_players,registration_fee,registration_currency,prize_pool_local) values
  ('7b7b7b7b-0000-0000-0000-000000000001','PEPRIZE','efootball','single_elimination','ongoing',now()-interval '1 hour',4,1000,'XAF',50000),
  ('7b7b7b7b-0000-0000-0000-000000000002','PEFREE','efootball','single_elimination','ongoing',now()-interval '1 hour',4,1000,'XAF',0),
  ('7b7b7b7b-0000-0000-0000-000000000003','PEPRIZEDONE','efootball','single_elimination','completed',now()-interval '2 hour',4,1000,'XAF',50000),
  ('7b7b7b7b-0000-0000-0000-000000000004','PEFREEDONE','efootball','single_elimination','completed',now()-interval '2 hour',4,1000,'XAF',0);

-- Matchs : réglé à prix / frais à prix / réglé sans prix.
insert into matches(id,competition_id,status,player1_id,player2_id,winner_id,score1,score2) values
  ('7c7c7c7c-0000-0000-0000-000000000001','7b7b7b7b-0000-0000-0000-000000000001','completed',
   '7a7a7a7a-0000-0000-0000-0000000000a1','7a7a7a7a-0000-0000-0000-0000000000a2','7a7a7a7a-0000-0000-0000-0000000000a1',3,1),
  ('7c7c7c7c-0000-0000-0000-000000000002','7b7b7b7b-0000-0000-0000-000000000001','disputed',
   '7a7a7a7a-0000-0000-0000-0000000000a1','7a7a7a7a-0000-0000-0000-0000000000a2',null,null,null),
  ('7c7c7c7c-0000-0000-0000-000000000003','7b7b7b7b-0000-0000-0000-000000000002','completed',
   '7a7a7a7a-0000-0000-0000-0000000000a1','7a7a7a7a-0000-0000-0000-0000000000a2','7a7a7a7a-0000-0000-0000-0000000000a1',3,1);

-- Registrations classées (final_rank posé) dans les 2 comps clôturées.
-- NB : competition_registrations a une PK composite (competition_id, player_id),
-- pas de colonne `id`.
insert into competition_registrations(competition_id,player_id,status,final_rank) values
  ('7b7b7b7b-0000-0000-0000-000000000003','7a7a7a7a-0000-0000-0000-0000000000a1','confirmed',2),
  ('7b7b7b7b-0000-0000-0000-000000000004','7a7a7a7a-0000-0000-0000-0000000000a1','confirmed',2);

-- Requête de réintégration en attente pour le banni à vie.
insert into reintegration_requests(id,user_id,message,status) values
  ('7e7e7e7e-0000-0000-0000-000000000001','7a7a7a7a-0000-0000-0000-0000000000b9',
   'Je demande ma reintegration svp merci','pending');

create temp table _r(test text primary key, result text) on commit drop;
grant all on _r to authenticated;

-- ════════════════════════════════════════════════════════════════════
-- Acte 1 — ADMIN SIMPLE (7a…001)
-- ════════════════════════════════════════════════════════════════════
set local role authenticated;
set local request.jwt.claims = '{"sub":"7a7a7a7a-0000-0000-0000-000000000001"}';

-- (1) Inverser un winner déjà posé sur un match À PRIX → BLOQUÉ.
do $$ begin
  update public.matches set winner_id='7a7a7a7a-0000-0000-0000-0000000000a2'
   where id='7c7c7c7c-0000-0000-0000-000000000001';
  insert into _r values ('prize_invert_admin','allowed');
exception when others then
  insert into _r values ('prize_invert_admin','blocked');
end $$;

-- (2) 1re saisie d'un résultat sur un match À PRIX (winner null) → AUTORISÉ.
do $$ begin
  update public.matches
     set winner_id='7a7a7a7a-0000-0000-0000-0000000000a1', score1=2, score2=0, status='completed'
   where id='7c7c7c7c-0000-0000-0000-000000000002';
  insert into _r values ('prize_first_entry_admin','allowed');
exception when others then
  insert into _r values ('prize_first_entry_admin','blocked');
end $$;

-- (3) Inverser un winner déjà posé sur un match SANS prix → AUTORISÉ (inchangé).
do $$ begin
  update public.matches set winner_id='7a7a7a7a-0000-0000-0000-0000000000a2'
   where id='7c7c7c7c-0000-0000-0000-000000000003';
  insert into _r values ('free_invert_admin','allowed');
exception when others then
  insert into _r values ('free_invert_admin','blocked');
end $$;

-- (4) Écraser final_rank sur une comp À PRIX CLÔTURÉE → BLOQUÉ.
do $$ begin
  update public.competition_registrations set final_rank=1
   where competition_id='7b7b7b7b-0000-0000-0000-000000000003'
     and player_id='7a7a7a7a-0000-0000-0000-0000000000a1';
  insert into _r values ('prize_finalrank_admin','allowed');
exception when others then
  insert into _r values ('prize_finalrank_admin','blocked');
end $$;

-- (5) Écraser final_rank sur une comp SANS prix clôturée → AUTORISÉ.
do $$ begin
  update public.competition_registrations set final_rank=1
   where competition_id='7b7b7b7b-0000-0000-0000-000000000004'
     and player_id='7a7a7a7a-0000-0000-0000-0000000000a1';
  insert into _r values ('free_finalrank_admin','allowed');
exception when others then
  insert into _r values ('free_finalrank_admin','blocked');
end $$;

-- (6) Réintégration : un admin simple approuve → RLS filtre à 0 ligne.
update public.reintegration_requests
   set status='approved', resolved_at=now(), resolved_by='7a7a7a7a-0000-0000-0000-000000000001'
 where id='7e7e7e7e-0000-0000-0000-000000000001';
insert into _r select 'reintegration_admin_rows',
  (select status from public.reintegration_requests where id='7e7e7e7e-0000-0000-0000-000000000001');

-- ════════════════════════════════════════════════════════════════════
-- Acte 2 — SUPER-ADMIN (7a…002)
-- ════════════════════════════════════════════════════════════════════
set local request.jwt.claims = '{"sub":"7a7a7a7a-0000-0000-0000-000000000002"}';

-- (7) Super-admin inverse un winner à prix → AUTORISÉ.
do $$ begin
  update public.matches set winner_id='7a7a7a7a-0000-0000-0000-0000000000a2'
   where id='7c7c7c7c-0000-0000-0000-000000000001';
  insert into _r values ('prize_invert_superadmin','allowed');
exception when others then
  insert into _r values ('prize_invert_superadmin','blocked');
end $$;

-- (8) Super-admin écrase final_rank à prix clôturée → AUTORISÉ.
do $$ begin
  update public.competition_registrations set final_rank=1
   where competition_id='7b7b7b7b-0000-0000-0000-000000000003'
     and player_id='7a7a7a7a-0000-0000-0000-0000000000a1';
  insert into _r values ('prize_finalrank_superadmin','allowed');
exception when others then
  insert into _r values ('prize_finalrank_superadmin','blocked');
end $$;

-- (9) Super-admin approuve la réintégration → débannit le compte.
update public.reintegration_requests
   set status='approved', resolved_at=now(), resolved_by='7a7a7a7a-0000-0000-0000-000000000002'
 where id='7e7e7e7e-0000-0000-0000-000000000001';
insert into _r select 'reintegration_superadmin_rows',
  (select status from public.reintegration_requests where id='7e7e7e7e-0000-0000-0000-000000000001');

reset role;

-- ─── Assertions ─────────────────────────────────────────────────────
select is((select result from _r where test='prize_invert_admin'),        'blocked',
  'admin simple ne peut PAS inverser un vainqueur d''un match à cagnotte');
select is((select result from _r where test='prize_first_entry_admin'),   'allowed',
  'admin simple peut faire la 1re saisie d''un résultat (comp à prix)');
select is((select result from _r where test='free_invert_admin'),         'allowed',
  'admin simple peut arbitrer librement un match SANS prix (inchangé)');
select is((select result from _r where test='prize_finalrank_admin'),     'blocked',
  'admin simple ne peut PAS écraser final_rank d''une comp à prix clôturée');
select is((select result from _r where test='free_finalrank_admin'),      'allowed',
  'admin simple peut poser final_rank sur une comp SANS prix');
select is((select result from _r where test='reintegration_admin_rows'),  'pending',
  'admin simple : la réintégration reste "pending" (RLS super-admin filtre l''UPDATE)');
select is((select result from _r where test='prize_invert_superadmin'),   'allowed',
  'super-admin peut inverser un vainqueur d''un match à cagnotte');
select is((select result from _r where test='prize_finalrank_superadmin'),'allowed',
  'super-admin peut écraser final_rank d''une comp à prix clôturée');
select is((select result from _r where test='reintegration_superadmin_rows'),'approved',
  'super-admin peut approuver la réintégration');

-- Effet de bord vérifié : le compte banni a bien été réactivé par le trigger.
select is((select is_active from profiles where id='7a7a7a7a-0000-0000-0000-0000000000b9'),
  true, 'l''approbation super-admin réactive le compte (is_active)');
select is((select permanent_ban from profiles where id='7a7a7a7a-0000-0000-0000-0000000000b9'),
  false, 'l''approbation super-admin lève le bannissement à vie (permanent_ban)');

select * from finish();
rollback;
