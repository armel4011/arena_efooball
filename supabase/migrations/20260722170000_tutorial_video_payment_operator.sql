-- Tuto paiement PAR OPÉRATEUR (en plus du pays).
--
-- Le tuto de paiement (`payment_tutorial`) était discriminé par PAYS seulement.
-- On ajoute une dimension OPÉRATEUR (`operator_code`, slug MAJUSCULE dérivé du
-- label, ex. ORANGE_MONEY / MTN_MOMO / WAVE). `operator_code` est OPTIONNEL :
--   - renseigné  → vidéo spécifique à cet opérateur dans ce pays ;
--   - NULL       → vidéo « par défaut du pays » (repli si aucune vidéo
--                  spécifique à l'opérateur du joueur).
-- Les autres cibles n'ont pas d'opérateur (NULL imposé).

alter table public.tutorial_video
  add column if not exists operator_code text;

-- `operator_code` uniquement pour payment_tutorial, slug MAJUSCULE (A-Z0-9_).
alter table public.tutorial_video
  drop constraint if exists tutorial_video_operator_code_chk;
alter table public.tutorial_video
  add constraint tutorial_video_operator_code_chk
  check (
    operator_code is null
    or (target_page = 'payment_tutorial' and operator_code ~ '^[A-Z0-9_]+$')
  );

-- Unicité tuto paiement : 1 vidéo active par (pays, opérateur). L'opérateur
-- NULL (→ '' via coalesce) représente la vidéo par défaut du pays, distincte
-- des vidéos par opérateur. Remplace l'ancien index (pays seul).
drop index if exists public.tutorial_video_active_country_ctx;
create unique index if not exists tutorial_video_active_payment_ctx
  on public.tutorial_video (country_code, coalesce(operator_code, ''))
  where (is_active and target_page = 'payment_tutorial');
