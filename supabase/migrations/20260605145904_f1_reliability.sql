-- =============================================================================
-- ARENA — Fiabilisation du pipeline payout F-1 (audit v4)
-- =============================================================================
-- 1. RGPD : scrub payouts.payee_phone à l'anonymisation (la colonne n'existait
--    pas quand anonymize_deleted_account a été écrit → PII résiduelle).
-- 2. Notifs payout : ajout d'une clé `route` → tap deep-linke vers l'historique
--    (onglet GAINS), et le client les catégorise (cf. notifications_page).
-- 3. generate_payouts : distingue « pas de classé » (erreur explicite) de
--    « déjà généré » (retour 0) → fini l'échec silencieux si l'admin oublie de
--    publier le classement avant de générer.
-- 4. Unicité (competition_id, final_rank) : empêche 2 ex-aequo au même rang
--    (sinon generate_payouts en paie un seul via LIMIT 1, en silence).
-- =============================================================================

-- ─── 1. RGPD : complète le scrub avec payouts.payee_phone ────────────────────
create or replace function public.anonymize_deleted_account(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_tag text := left(replace(p_user_id::text, '-', ''), 16);
begin
  update public.profiles set
    username                = 'del_' || v_tag,
    email                   = p_user_id::text || '@deleted.invalid',
    whatsapp_number         = null,
    fcm_token               = null,
    voip_token              = null,
    auth_provider_id        = null,
    referral_code           = 'DEL' || upper(v_tag),
    referred_by             = null,
    account_deletion_reason = null,
    totp_secret             = null,
    totp_enabled            = false,
    backup_codes            = '[]'::jsonb,
    last_seen_at            = null,
    anonymized_at           = now()
  where id = p_user_id
    and anonymized_at is null;

  update public.payments
     set payer_phone = null
   where user_id = p_user_id and payer_phone is not null;

  -- Numéro Mobile Money de retrait du gagnant : PII à scrubber aussi.
  update public.payouts
     set payee_phone = null
   where user_id = p_user_id and payee_phone is not null;
end;
$$;

comment on function public.anonymize_deleted_account(uuid) is
  'RGPD C-1 (complété F-3 + F-1 reliability) : scrub PII de profiles + '
  'payments.payer_phone + payouts.payee_phone. Conserve les lignes compta '
  'anonymisées. Service_role only.';

-- ─── 3+2. generate_payouts : garde anti-classement-manquant + route notif ────
create or replace function public.generate_payouts(p_competition_id uuid)
returns integer
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_status   public.competition_status;
  v_pool     numeric;
  v_dist     jsonb;
  v_currency text;
  v_name     text;
  v_n        integer;
  i          integer;
  v_amount   numeric;
  v_user     uuid;
  v_count    integer := 0;
  v_had_prize boolean := false;
begin
  if not public.is_super_admin() then
    raise exception 'Reserve au super-admin' using errcode = '42501';
  end if;

  select status, prize_pool_local, prize_distribution, registration_currency, name
    into v_status, v_pool, v_dist, v_currency, v_name
    from public.competitions
    where id = p_competition_id;
  if not found then
    raise exception 'Competition introuvable' using errcode = 'P0002';
  end if;
  if v_status <> 'completed' then
    raise exception 'Les versements ne se generent qu''une fois la competition terminee'
      using errcode = '42501';
  end if;

  -- Idempotence : ne pas regenerer si des payouts existent deja.
  if exists (select 1 from public.payouts where competition_id = p_competition_id) then
    return 0;
  end if;
  if v_dist is null or jsonb_typeof(v_dist) <> 'array' then
    return 0;
  end if;

  v_n := jsonb_array_length(v_dist);
  i := 1;
  while i <= v_n loop
    v_amount := coalesce((v_dist->>(i - 1))::numeric, 0);
    if v_amount > 0 then
      v_had_prize := true;
      select player_id into v_user
        from public.competition_registrations
        where competition_id = p_competition_id and final_rank = i
        limit 1;
      if v_user is not null then
        insert into public.payouts
          (user_id, competition_id, amount_local, currency, status, rank, payout_provider)
        values
          (v_user, p_competition_id, v_amount, v_currency,
           'pending_admin_validation', i, 'mobile_money_manual');

        insert into public.notifications (user_id, type, title, body, data)
        values (v_user, 'payout_available', 'Tu as gagne !',
          'Felicitations ! Tu as remporte ' || v_amount::text || ' ' || v_currency
            || ' a « ' || v_name || ' ». Reclame tes gains dans l''app pour '
            || 'recevoir ton versement Mobile Money.',
          jsonb_build_object('competition_id', p_competition_id, 'rank', i,
                             'amount_local', v_amount, 'route', '/payments/history'));
        v_count := v_count + 1;
      end if;
    end if;
    i := i + 1;
  end loop;

  -- Garde anti-echec-silencieux : des prix sont prevus mais aucun joueur classe.
  if v_count = 0 and v_had_prize then
    raise exception 'Aucun joueur classe pour les rangs recompenses. Publie d''abord le classement final, puis genere les versements.'
      using errcode = 'P0002';
  end if;

  return v_count;
end;
$$;

comment on function public.generate_payouts(uuid) is
  'F-1 : genere les payouts (gains) d''une competition completed depuis '
  'prize_distribution + final_rank. Notifie (route GAINS). Idempotent. '
  'Erreur explicite si prix prevus mais classement non publie. Gate super-admin.';

-- ─── 2. mark_payout_paid : route notif vers l'historique ─────────────────────
create or replace function public.mark_payout_paid(p_payout_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user     uuid;
  v_status   text;
  v_phone    text;
  v_amount   numeric;
  v_currency text;
  v_name     text;
begin
  if not public.is_super_admin() then
    raise exception 'Reserve au super-admin' using errcode = '42501';
  end if;

  select p.user_id, p.status, p.payee_phone, p.amount_local, p.currency, c.name
    into v_user, v_status, v_phone, v_amount, v_currency, v_name
    from public.payouts p
    join public.competitions c on c.id = p.competition_id
    where p.id = p_payout_id for update;
  if not found then
    raise exception 'Versement introuvable' using errcode = 'P0002';
  end if;
  if v_status = 'completed' then
    raise exception 'Versement deja paye' using errcode = '42501';
  end if;
  if coalesce(trim(v_phone), '') = '' then
    raise exception 'Le gagnant n''a pas encore reclame (numero de retrait manquant)'
      using errcode = '42501';
  end if;

  update public.payouts
     set status               = 'completed',
         validated_by_admin_id = auth.uid(),
         validated_at         = now(),
         completed_at         = now()
   where id = p_payout_id;

  insert into public.notifications (user_id, type, title, body, data)
  values (v_user, 'payout_paid', 'Versement effectue',
    'Ton gain de ' || v_amount::text || ' ' || v_currency || ' pour « ' || v_name
      || ' » a ete verse sur ton numero Mobile Money.',
    jsonb_build_object('payout_id', p_payout_id, 'route', '/payments/history'));
end;
$$;

comment on function public.mark_payout_paid(uuid) is
  'F-1 : le super-admin marque un payout paye (apres virement reel). Exige un '
  'numero reclame. Notifie le gagnant (route GAINS). Gate super-admin.';

-- ─── 4. Unicité du rang final par compétition ────────────────────────────────
create unique index if not exists uniq_registrations_competition_final_rank
  on public.competition_registrations (competition_id, final_rank)
  where final_rank is not null;
