-- ════════════════════════════════════════════════════════════════════
-- app_config : aligne supported_languages sur FR + EN
-- ════════════════════════════════════════════════════════════════════
-- Le lecteur de feature flags Flutter (FeatureFlagsService.fetch /
-- FeatureFlags.fromConfig) est réparé : il lit DÉSORMAIS réellement la table
-- clé/valeur `app_config` (avant, il cherchait une clé racine `enabled_*` dans
-- une seule ligne → ne lisait jamais rien, retombait toujours sur les defaults
-- code).
--
-- Conséquence : la valeur DB de `supported_languages` redevient autoritaire.
-- Elle valait `["fr"]` (V1.0) → sans cet UPDATE, elle ÉCRASERAIT le défaut code
-- `[fr, en]` et re-masquerait le sélecteur de langue (isMultiLanguage=false).
-- On l'aligne donc sur FR + EN (l'arabe reste différé).
-- ════════════════════════════════════════════════════════════════════

update public.app_config
   set value = '["fr", "en"]'::jsonb,
       updated_at = now()
 where key = 'supported_languages';
