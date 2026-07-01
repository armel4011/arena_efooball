-- ════════════════════════════════════════════════════════════════════
-- Data fix — indicatif pays dupliqué dans whatsapp_number
-- ════════════════════════════════════════════════════════════════════
-- Certains comptes ont l'indicatif pays écrit DEUX fois (ex.
-- `+237237655869124` au lieu de `+237655869124`) : l'utilisateur avait saisi
-- l'indicatif dans le champ « numéro local » à l'inscription, et l'ancien
-- buildE164Phone le re-préfixait sans dédoublonner (corrigé côté app dans la
-- même PR). On normalise les lignes existantes : si les chiffres du numéro
-- commencent par l'indicatif du pays RÉPÉTÉ, on retire une occurrence.
--
-- Idempotent : après correction, le numéro ne commence plus par l'indicatif
-- doublé → un rejeu ne change rien.
-- ════════════════════════════════════════════════════════════════════

with dial(cc, d) as (
  values
    ('CM', '237'), ('SN', '221'), ('CI', '225'), ('GA', '241'),
    ('BJ', '229'), ('TG', '228'), ('BF', '226'), ('ML', '223'),
    ('NE', '227'), ('TD', '235'), ('GN', '224'), ('CD', '243'),
    ('MG', '261')
)
update public.profiles p
   set whatsapp_number =
         '+' || di.d
         || substr(regexp_replace(p.whatsapp_number, '\D', '', 'g'),
                   length(di.d) * 2 + 1)
  from dial di
 where di.cc = p.country_code
   and p.whatsapp_number is not null
   and regexp_replace(p.whatsapp_number, '\D', '', 'g') like (di.d || di.d || '%');
