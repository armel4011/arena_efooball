-- ════════════════════════════════════════════════════════════════════
-- pgTAP — RLS chat : la paire bloquée ne peut plus s'écrire
-- ════════════════════════════════════════════════════════════════════
-- Garde anti-régression sur `chat_messages_no_blocked_pair`, une policy
-- RESTRICTIVE dont un bug latent (PERMISSIVE au lieu de RESTRICTIVE) avait
-- déjà été découvert (cf. mémoire projet rls_permissive_vs_restrictive).
--
-- Invariant : dans un canal de match, si les deux joueurs sont une paire
-- `blocked` (friendships), aucun des deux ne peut insérer de message ;
-- dès que le blocage est levé, l'envoi repasse.
--
-- Logique validée en prod via transaction ROLLBACK le 2026-06-13.
-- ════════════════════════════════════════════════════════════════════

begin;
select plan(2);

-- ─── Fixtures (superuser) ───────────────────────────────────────────
insert into auth.users(id) values
  ('aaaaaaaa-0000-0000-0000-000000000001'),
  ('aaaaaaaa-0000-0000-0000-000000000002');

insert into profiles(id, username, email, country_code, referral_code, role) values
  ('aaaaaaaa-0000-0000-0000-000000000001','t_ci_a','a@ci.invalid','CI','CIREFA01','player'),
  ('aaaaaaaa-0000-0000-0000-000000000002','t_ci_b','b@ci.invalid','CI','CIREFB02','player');

insert into competitions(id,name,game,format,start_date,max_players,registration_currency)
values ('cccccccc-0000-0000-0000-000000000001','CI','efootball','single_elimination',now()+interval '1 day',8,'XOF');

insert into matches(id,competition_id,player1_id,player2_id,status)
values ('11111111-0000-0000-0000-000000000001','cccccccc-0000-0000-0000-000000000001',
        'aaaaaaaa-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000002','pending');

insert into chat_channels(id,type,match_id)
values ('22222222-0000-0000-0000-000000000001','match','11111111-0000-0000-0000-000000000001');

-- A bloque B.
insert into friendships(requester_id,addressee_id,status,blocked_by)
values ('aaaaaaaa-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000002','blocked',
        'aaaaaaaa-0000-0000-0000-000000000001');

create temp table _r(test text primary key, result text) on commit drop;
grant all on _r to authenticated;

-- ─── Cas 1 : paire bloquée → INSERT refusé ──────────────────────────
set local role authenticated;
set local request.jwt.claims = '{"sub":"aaaaaaaa-0000-0000-0000-000000000001"}';
do $$ begin
  insert into chat_messages(channel_id, content, sender_id)
  values ('22222222-0000-0000-0000-000000000001','hello','aaaaaaaa-0000-0000-0000-000000000001');
  insert into _r values ('blocked_pair','allowed');
exception when others then insert into _r values ('blocked_pair','denied'); end $$;

-- ─── Cas 2 : blocage levé → INSERT autorisé (contrôle positif) ──────
reset role;
delete from friendships
 where requester_id='aaaaaaaa-0000-0000-0000-000000000001'
   and addressee_id='aaaaaaaa-0000-0000-0000-000000000002';
set local role authenticated;
set local request.jwt.claims = '{"sub":"aaaaaaaa-0000-0000-0000-000000000001"}';
do $$ begin
  insert into chat_messages(channel_id, content, sender_id)
  values ('22222222-0000-0000-0000-000000000001','hello again','aaaaaaaa-0000-0000-0000-000000000001');
  insert into _r values ('unblocked','allowed');
exception when others then insert into _r values ('unblocked','denied'); end $$;

reset role;

-- ─── Assertions pgTAP ───────────────────────────────────────────────
select is((select result from _r where test='blocked_pair'), 'denied',
  'chat_messages_no_blocked_pair (RESTRICTIVE) bloque l''envoi entre une paire bloquée');
select is((select result from _r where test='unblocked'), 'allowed',
  'le déblocage rétablit l''envoi de messages dans le canal de match');

select finish();
rollback;
