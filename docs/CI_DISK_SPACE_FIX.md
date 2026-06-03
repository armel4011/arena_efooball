# Correctif CI — « No space left on device » sur le build APK admin

## Symptôme
Le job **Build APK (admin)** échoue par intermittence avec :
```
java.io.IOException: No space left on device
Execution failed for task ':app:mergeAdminDebugNativeLibs'.
```
Le re-run passe en général (`gh run rerun <id> --failed`), mais c'est de
la flakiness à supprimer.

## Cause
Le runner `ubuntu-latest` a ~14 Go libres. Le build admin est lourd
(SDK Agora Windows + Firebase C++ + nombreuses libs natives) et sature
le disque pendant `mergeNativeLibs`. C'est purement infrastructurel — le
code est sain.

## Correctif (à appliquer côté GitHub — nécessite le scope `workflow`)

Dans `.github/workflows/ci.yml`, job `build-apk`, ajouter une étape de
libération d'espace **juste après `- name: Checkout`** (ligne ~159),
avant le setup Java :

```yaml
      - name: Free up disk space (runner)
        run: |
          sudo rm -rf /usr/share/dotnet /usr/local/lib/android/sdk/ndk \
            /opt/ghc /usr/local/share/boost "$AGENT_TOOLSDIRECTORY" || true
          sudo docker image prune --all --force || true
          df -h
```

Cela libère ~20–30 Go (dotnet, NDK Android inutilisé, GHC, images
Docker), largement suffisant pour le build admin.

> ⚠️ Ne PAS supprimer tout `/usr/local/lib/android/sdk` — seul le
> sous-dossier `ndk` est inutile ici ; le reste du SDK sert au build.

## Comment l'appliquer
Le token CLI local n'a pas le scope `workflow` (modifs de
`.github/workflows/` refusées au push). Deux options :

1. **Via l'éditeur web GitHub** (le plus simple) : ouvrir
   `.github/workflows/ci.yml` sur github.com → ✏️ Edit → coller l'étape →
   Commit.
2. **Re-générer un token CLI avec le scope `workflow`** :
   `gh auth refresh -h github.com -s workflow` puis pousser normalement.

## En attendant
Le build admin reste fonctionnel — un simple
`gh run rerun <run-id> --failed` relance le job qui passe alors (le cache
Gradle réduit l'empreinte au 2e essai).
