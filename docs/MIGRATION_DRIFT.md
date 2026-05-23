# Migration drift — Tracking (audit 2026-05-23)

## Constat

`supabase migration list` (avec Supabase CLI 2.101.0) signale un
décalage important entre les fichiers locaux et le tracking remote :

| | Local | Remote |
|---|---|---|
| Fichiers / entrées | **88** | **76** |
| Timestamps matchés | 17 | 17 |
| Local-only timestamps | **71** | — |
| Remote-only timestamps | — | **59** |

Le contenu est en place (la DB est dans l'état attendu, advisors OK,
RLS testée), mais les timestamps des fichiers ne correspondent pas
à ceux enregistrés dans `supabase_migrations.schema_migrations`.

## Cause probable

Migrations rejouées via dashboard / `apply_migration` MCP / CLI à
différents moments du cycle de dev. Chaque rejeu crée une entrée
schema_migrations avec **l'heure d'exécution** (et non l'heure du
fichier), d'où le décalage par paquets de 8h ou plus.

## Risque actuel

- ⚠️ **`supabase db push` est inutile** — il croit que rien n'est
  à appliquer (les fichiers locaux sont marqués `non appliqué` côté
  CLI mais leur contenu est bien dans la DB).
- ⚠️ **CI / déploiement** — un environnement de staging vide ne
  pourrait pas être reconstruit à partir des seuls fichiers (les
  17 timestamps matchés ne suffisent pas).
- ✅ **Production OK** — aucun impact runtime, l'app fonctionne.

## Stratégie de cleanup (à exécuter en bloc)

**Pré-requis** : faire un dump complet de la prod
(`supabase db dump --linked > backup_pre_repair.sql`) pour pouvoir
rollback en cas de pépin.

### Option A — Repair tracking (recommandée)

Aligne le tracking remote avec les fichiers locaux. Réversible.

```bash
# 1. Reverter les 59 ghost entries (entrées remote sans fichier local)
#    Liste à extraire via : supabase migration list | awk-filter
bin/supabase.exe migration repair --linked --status reverted \
  20260505183451 20260505183523 ... # (59 timestamps)

# 2. Marquer les 71 fichiers locaux comme déjà appliqués
bin/supabase.exe migration repair --linked --status applied \
  20260505100001 20260505100002 ... # (71 timestamps)

# 3. Vérifier
bin/supabase.exe migration list  # doit montrer 88 = 88 matched
```

### Option B — Reset & replay

Recrée la DB depuis zéro (staging uniquement, JAMAIS en prod) :

```bash
bin/supabase.exe db reset --linked  # ⚠️ DESTRUCTIF
bin/supabase.exe db push
```

### Option C — Rename local files (manuel)

Renomme les 71 fichiers pour matcher les timestamps remote. Évite
les ghost entries mais nécessite un mapping nom-à-nom prudent
(les noms peuvent collisionner).

## Décision actuelle

**Différé** — la prod fonctionne, aucune urgence. À traiter avant
le premier push staging / fresh-DB / fork pour test.

**Prochaine échéance** : si besoin de monter un environnement
staging, exécuter Option A.

## Workaround pour nouvelles migrations

D'ici-là, les nouvelles migrations doivent passer par
`mcp__supabase__apply_migration` (qui inscrit avec le timestamp
courant) **ET** être sauvegardées localement avec le **même**
timestamp pour rester traçables :

```typescript
// 1. Récupérer le timestamp via list_migrations après apply
// 2. Créer le fichier supabase/migrations/<timestamp>_<name>.sql
```

Une autre option (plus simple en pratique) est d'utiliser un
timestamp futur du type `20260523200000_xxx.sql` côté local et de
documenter le drift cible dans le commit.
