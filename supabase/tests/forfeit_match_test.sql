-- ════════════════════════════════════════════════════════════════════
-- pgTAP — forfeit_match : déclaration de forfait par un joueur
-- ════════════════════════════════════════════════════════════════════
-- Couvre la RPC SECURITY DEFINER public.forfeit_match(match, reason) :
--   - seul un JOUEUR du match peut déclarer forfait (sinon 42501) ;
--   - le forfait donne la victoire à l'ADVERSAIRE + status 'forfeited' ;
--   - un match déjà finalisé (forfeited/completed/cancelled) ne peut plus
--     être déclaré forfait (42501).
--
-- Pattern (cf. payment_validate_idempotency_test) : rôle `authenticated` +
-- JWT simulé, capture des exceptions dans une table temp, assertions après
-- `reset role`.
-- ════════════════════════════════════════════════════════════════════

begin;
select plan(4);

-- Dispatch de notifications (pg_net) neutralisé : indisponible / non désiré
-- dans la CI, et la finalisation auto de compétition peut en émettre.
alter table public.notifications disable trigger trg_notifications_dispatch;

-- ─── Fixtures (superuser : bypass RLS) ──────────────────────────────
insert into auth.users(id) values
  ('ff000000-0000-0000-0000-0000000000a1'),  -- joueur 1
  ('ff000000-0000-0000-0000-0000000000a2'),  -- joueur 2
  ('ff000000-0000-0000-0000-0000000000ff');  -- intrus (non-joueur)
insert into profiles(id,username,email,country_code,referral_code,role,is_active) values
  ('ff000000-0000-0000-0000-0000000000a1','ff_p1','ffp1@ci.invalid','CM','FFP1','player',true),
  ('ff000000-0000-0000-0000-0000000000a2','ff_p2','ffp2@ci.invalid','CM','FFP2','player',true),
  ('ff000000-0000-0000-0000-0000000000ff','ff_x','ffx@ci.invalid','CM','FFXX','player',true);

insert into competitions(id,name,game,format,status,start_date,max_players,registration_fee,registration_currency)
values ('ff000000-0000-0000-0000-0000000000c1','FORFEIT','efootball','single_elimination','ongoing',now(),4,0,'XAF');

insert into matches(id,competition_id,player1_id,player2_id,status)
values ('ff000000-0000-0000-0000-0000000000e1','ff000000-0000-0000-0000-0000000000c1',
        'ff000000-0000-0000-0000-0000000000a1','ff000000-0000-0000-0000-0000000000a2','in_progress');

create temp table _r(test text primary key, result text) on commit drop;
grant all on _r to authenticated;

set local role authenticated;

-- (1) Un NON-joueur ne peut pas déclarer forfait → 42501.
set local request.jwt.claims = '{"sub":"ff000000-0000-0000-0000-0000000000ff"}';
do $$ begin
  perform public.forfeit_match('ff000000-0000-0000-0000-0000000000e1');
  insert into _r values ('nonplayer','allowed');
exception when others then insert into _r values ('nonplayer','blocked:'||sqlstate); end $$;

-- (2) Le joueur 1 déclare forfait → le joueur 2 gagne, status 'forfeited'.
set local request.jwt.claims = '{"sub":"ff000000-0000-0000-0000-0000000000a1"}';
select public.forfeit_match('ff000000-0000-0000-0000-0000000000e1');

-- (3) Re-tenter un forfait sur un match DÉJÀ finalisé → 42501.
do $$ begin
  perform public.forfeit_match('ff000000-0000-0000-0000-0000000000e1');
  insert into _r values ('refor','allowed');
exception when others then insert into _r values ('refor','blocked:'||sqlstate); end $$;

reset role;

-- ─── Assertions (superuser) ─────────────────────────────────────────
select is((select result from _r where test='nonplayer'), 'blocked:42501',
  'un non-joueur ne peut pas declarer forfait (42501)');
select is((select winner_id from matches where id='ff000000-0000-0000-0000-0000000000e1'),
  'ff000000-0000-0000-0000-0000000000a2'::uuid,
  'le forfait du joueur 1 donne la victoire au joueur 2 (adversaire)');
select is((select status::text from matches where id='ff000000-0000-0000-0000-0000000000e1'),
  'forfeited', 'le match passe en status forfeited');
select is((select result from _r where test='refor'), 'blocked:42501',
  'un match deja finalise ne peut plus etre declare forfait (42501)');

select * from finish();
rollback;
