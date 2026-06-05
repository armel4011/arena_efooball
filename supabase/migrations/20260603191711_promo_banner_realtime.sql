-- La home utilisateur doit refleter en temps reel la publication / le retrait
-- d'une banniere par le super-admin. On ajoute promo_banner a la publication
-- realtime pour que le StreamProvider `activePromoBannerProvider`
-- (MatchRepository-style watch) recoive les INSERT/UPDATE sans cold start.
--
-- Idempotent : duplicate_object est avale si la table est deja publiee.

DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.promo_banner;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
