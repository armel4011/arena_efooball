-- Phase 12.5 — Colonne pour marquer le joueur jugé coupable lors de
-- la résolution d'un litige. Permet aux super-admins de filtrer les
-- utilisateurs récidivistes / de douter sur leur fair-play.
--
-- Nullable car la majorité des disputes futures resteront sans verdict
-- explicite (closed sans coupable désigné). FK vers profiles avec
-- ON DELETE SET NULL : si un compte est supprimé, on garde l'historique
-- des disputes sans pointer un fantôme.

alter table public.disputes
  add column if not exists guilty_party_id uuid
    references public.profiles(id) on delete set null;

comment on column public.disputes.guilty_party_id is
  'Joueur que l''admin a jugé responsable du litige (faux score, '
  'comportement abusif, etc.). Renseigné au moment du resolved. '
  'NULL = pas de coupable désigné (litige résolu sans blâme).';

create index if not exists idx_disputes_guilty_party
  on public.disputes(guilty_party_id)
  where guilty_party_id is not null;
