-- Audit 2026-11-22 (P3 perf) — Index couvrants sur les 2 FK collecteurs
-- signalées par l'advisor (unindexed_foreign_keys). Tables audit low-traffic,
-- mais évite les scans / contention de lock sur DELETE du profil référencé.
create index if not exists idx_collector_remittances_validated_by
  on public.collector_remittances(validated_by)
  where validated_by is not null;

create index if not exists idx_payment_collectors_created_by
  on public.payment_collectors(created_by);
