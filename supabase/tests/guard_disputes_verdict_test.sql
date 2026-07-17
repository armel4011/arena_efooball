-- ════════════════════════════════════════════════════════════════════
-- pgTAP — P0 : le verdict d'un litige est réservé au serveur
-- ════════════════════════════════════════════════════════════════════
-- Régression 20260717190000. AVANT le guard, `disputes_insert` ne contraignait
-- que `opened_by`/`match_id` : un joueur postait 3 litiges sur SON match en
-- désignant une victime ARBITRAIRE via `guilty_party_id`, et
-- `trg_three_strikes_ban` (qui comptait sans filtre de statut) la bannissait à
-- vie. Cible possible : n'importe qui, super-admin compris. 3 requêtes REST.
--
-- On vérifie les deux moitiés du fix :
--   1. le guard ferme l'écriture directe du verdict (joueur ET admin) ;
--   2. le compte des strikes n'accepte que de VRAIS verdicts (resolved +
--      resolved_by), pas des accusations brutes.
-- ════════════════════════════════════════════════════════════════════

begin;
select plan(8);

alter table public.matches disable trigger trg_matches_cascade_winner;
alter table public.matches disable trigger trg_matches_finalize_competition;
alter table public.matches disable trigger trg_matches_increment_stats;
alter table public.matches disable trigger trg_matches_recalc_group_standings;

insert into auth.users(id) values
  ('d1000000-0000-0000-0000-0000000000a1'),
  ('d1000000-0000-0000-0000-0000000000a2'),
  ('d1000000-0000-0000-0000-0000000000a3');
insert into profiles(id,username,email,country_code,referral_code,role,is_active) values
  ('d1000000-0000-0000-0000-0000000000a1','gd_attaquant','gd1@ci.invalid','CM','GDA1','player',true),
  ('d1000000-0000-0000-0000-0000000000a2','gd_victime','gd2@ci.invalid','CM','GDA2','player',true),
  ('d1000000-0000-0000-0000-0000000000a3','gd_admin','gd3@ci.invalid','CM','GDA3','super_admin',true);

insert into competitions(id,name,game,format,status,start_date,max_players,registration_fee,registration_currency,country_code)
values ('d1000000-0000-0000-0000-00000000c001','GUARD','efootball','single_elimination','ongoing',
        now() - interval '1 day',4,0,'XOF','CM');

insert into matches(id,competition_id,status,player1_id,player2_id) values
  ('d1000000-0000-0000-0000-000000000011','d1000000-0000-0000-0000-00000000c001','in_progress',
   'd1000000-0000-0000-0000-0000000000a1','d1000000-0000-0000-0000-0000000000a2');

-- ─── 1. L'ATTAQUE, jouée telle quelle ──────────────────────────────────────
set local role authenticated;
set local request.jwt.claims = '{"sub":"d1000000-0000-0000-0000-0000000000a1","role":"authenticated"}';

select throws_ok(
  $$insert into public.disputes (match_id, opened_by, guilty_party_id, reason)
    values ('d1000000-0000-0000-0000-000000000011',
            'd1000000-0000-0000-0000-0000000000a1',
            'd1000000-0000-0000-0000-0000000000a2', 'attaque')$$,
  '42501',
  null,
  'un joueur ne peut pas designer un coupable en ouvrant un litige');

select throws_ok(
  $$insert into public.disputes (match_id, opened_by, status, reason)
    values ('d1000000-0000-0000-0000-000000000011',
            'd1000000-0000-0000-0000-0000000000a1', 'resolved', 'pre-tranche')$$,
  '42501',
  null,
  'un joueur ne peut pas pre-trancher le statut a l''ouverture');

-- Le chemin légitime doit rester ouvert : ouvrir un litige SANS verdict.
select lives_ok(
  $$insert into public.disputes (id, match_id, opened_by, reason)
    values ('d1000000-0000-0000-0000-0000000000d1',
            'd1000000-0000-0000-0000-000000000011',
            'd1000000-0000-0000-0000-0000000000a1', 'litige legitime')$$,
  'ouvrir un litige normal reste possible');

-- ─── 2. Le contournement par UPDATE (P1 : admin simple / super-admin) ──────
set local request.jwt.claims = '{"sub":"d1000000-0000-0000-0000-0000000000a3","role":"authenticated"}';

select throws_ok(
  $$update public.disputes
       set guilty_party_id = 'd1000000-0000-0000-0000-0000000000a2'
     where id = 'd1000000-0000-0000-0000-0000000000d1'$$,
  '42501',
  null,
  'meme un super-admin ne trafique pas le verdict en direct (passer par resolve_dispute)');

-- ─── 3. Les RPC SECURITY DEFINER traversent le guard ───────────────────────
select lives_ok(
  $$select public.resolve_dispute(
      'd1000000-0000-0000-0000-000000000011'::uuid,
      'd1000000-0000-0000-0000-0000000000d1'::uuid,
      'justification de test', true, null, null, null)$$,
  'resolve_dispute (SECURITY DEFINER) traverse le guard');

reset role;

-- ─── 4. Un strike = un VERDICT, pas une accusation ─────────────────────────
-- Écrit en tant que postgres (le guard ne bride que les clients directs), ce
-- qui simule exactement ce qu'une RPC serveur ferait.
--
-- 3 litiges accusant la victime, mais AUCUN tranché : le ban ne doit pas
-- tomber. C'est la défense en profondeur — avant, `count(*)` sans filtre de
-- statut faisait de 3 accusations brutes un bannissement.
insert into public.disputes (match_id, opened_by, status, guilty_party_id, reason) values
  ('d1000000-0000-0000-0000-000000000011','d1000000-0000-0000-0000-0000000000a1','open',
   'd1000000-0000-0000-0000-0000000000a2','accusation 1'),
  ('d1000000-0000-0000-0000-000000000011','d1000000-0000-0000-0000-0000000000a1','open',
   'd1000000-0000-0000-0000-0000000000a2','accusation 2'),
  ('d1000000-0000-0000-0000-000000000011','d1000000-0000-0000-0000-0000000000a1','open',
   'd1000000-0000-0000-0000-0000000000a2','accusation 3');

select ok(
  (select permanent_ban from profiles where id='d1000000-0000-0000-0000-0000000000a2') = false,
  '3 accusations NON tranchees ne bannissent pas');

-- Les mêmes faits, cette fois réellement tranchés par un admin : le ban
-- légitime doit tomber au 3e. Chaque INSERT écrit guilty_party_id, donc arme
-- le trigger (un UPDATE reposant la MÊME valeur sortirait en early-return).
insert into public.disputes (match_id, opened_by, status, resolved_by, guilty_party_id, reason) values
  ('d1000000-0000-0000-0000-000000000011','d1000000-0000-0000-0000-0000000000a1','resolved',
   'd1000000-0000-0000-0000-0000000000a3','d1000000-0000-0000-0000-0000000000a2','verdict 1'),
  ('d1000000-0000-0000-0000-000000000011','d1000000-0000-0000-0000-0000000000a1','resolved',
   'd1000000-0000-0000-0000-0000000000a3','d1000000-0000-0000-0000-0000000000a2','verdict 2');

select ok(
  (select permanent_ban from profiles where id='d1000000-0000-0000-0000-0000000000a2') = false,
  '2 verdicts ne bannissent pas encore (le seuil est bien 3)');

insert into public.disputes (match_id, opened_by, status, resolved_by, guilty_party_id, reason) values
  ('d1000000-0000-0000-0000-000000000011','d1000000-0000-0000-0000-0000000000a1','resolved',
   'd1000000-0000-0000-0000-0000000000a3','d1000000-0000-0000-0000-0000000000a2','verdict 3');

select ok(
  (select permanent_ban from profiles where id='d1000000-0000-0000-0000-0000000000a2') = true,
  '3 verdicts (resolved + resolved_by) bannissent bien a vie');

select * from finish();
rollback;
