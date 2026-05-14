-- prize_distribution passe des pourcentages aux montants absolus
-- (monnaie locale de la compétition). Le wizard admin ne propose plus
-- que la saisie de montants ; prize_pool_local en est la somme.
alter table public.competitions
  alter column prize_distribution set default '[0, 0, 0, 0]'::jsonb;

comment on column public.competitions.prize_distribution is
  'Montants de gain par rang d''arrivée (monnaie locale de la compétition), ex. [100000,50000,25000,10000]. prize_pool_local en est la somme.';

-- Conversion ponctuelle des compétitions existantes : prize_distribution
-- était en %, on le passe en montants (montant = pool × % / 100) et on
-- recale prize_pool_local sur la somme des montants. Sur une base neuve
-- (aucune compétition) cette requête est un no-op.
with converted as (
  select
    c.id,
    jsonb_agg(
      round(c.prize_pool_local * (elem.value)::numeric / 100)
      order by elem.ord
    ) as new_dist
  from public.competitions c,
       lateral jsonb_array_elements(c.prize_distribution)
         with ordinality as elem(value, ord)
  group by c.id
)
update public.competitions c
set prize_distribution = conv.new_dist,
    prize_pool_local = (
      select coalesce(sum((x.value)::numeric), 0)
      from jsonb_array_elements(conv.new_dist) as x(value)
    )
from converted conv
where c.id = conv.id;
