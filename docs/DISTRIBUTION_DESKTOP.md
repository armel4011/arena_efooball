# Distribution de ARENA Admin Desktop (Windows)

Deux méthodes pour installer l'app sur d'autres ordinateurs Windows 10/11.
**La méthode recommandée est l'installeur .exe : un seul fichier, aucun
certificat à gérer.**

---

## ⭐ Méthode 1 — Installeur unique .exe (recommandée)

### Générer l'installeur (sur le poste de développement)

```sh
# 1. Build release de l'app desktop (fermer l'app si elle tourne)
taskkill /F /IM arena.exe
flutter build windows -t lib/main_admin_desktop.dart

# 2. Compilation de l'installeur (Inno Setup 6)
"%LOCALAPPDATA%\Programs\Inno Setup 6\ISCC.exe" windows\installer\arena_admin_installer.iss
```

→ Résultat : **`dist/arena-admin-installeur-1.0.0.exe`** (~52 MB)

### Installer sur n'importe quel poste

1. Copier **ce seul fichier** sur le poste (USB, réseau, cloud...)
2. Double-clic → assistant d'installation en français
3. L'app s'installe **sans droits administrateur** (par utilisateur),
   crée les raccourcis Menu Démarrer + Bureau (optionnel) et un
   désinstallateur.

> 💡 Si le fichier a été téléchargé depuis internet, Windows SmartScreen
> peut afficher « Windows a protégé votre ordinateur » → cliquer
> **Informations complémentaires** → **Exécuter quand même**.
> (Pas d'avertissement si copié par USB/réseau local.)

### Mise à jour de l'app

1. Incrémenter `#define AppVersion` dans
   `windows/installer/arena_admin_installer.iss` (ex. "1.0.1")
2. Re-générer (mêmes commandes ci-dessus)
3. Installer le nouvel .exe par-dessus l'ancien → mise à jour propre.

### Modifier l'installeur

Le script est dans `windows/installer/arena_admin_installer.iss`
(langue, raccourcis, dossier d'installation, version...). Inno Setup 6
est installé dans `%LOCALAPPDATA%\Programs\Inno Setup 6\`.

---

## Méthode 2 — Paquet MSIX (pour le Microsoft Store plus tard)

<details>
<summary>Déplier — utile uniquement pour la piste Store ou un déploiement
géré en entreprise (Intune)</summary>

### Générer

```sh
taskkill /F /IM arena.exe
flutter build windows -t lib/main_admin_desktop.dart
dart run msix:create --build-windows false
```

→ `dist/arena-admin-setup.msix` (~72 MB)

### Installer sur un autre poste (2 fichiers + 2 étapes)

1. Copier `arena-admin-setup.msix` **+** `windows/certificates/arena_admin.cer`
2. Installer le certificat (une fois par poste, droits admin requis) :
   - Clic droit sur le `.cer` → Installer le certificat → **Ordinateur
     local** → **Autorités de certification racines de confiance**
   - Ou en PowerShell admin :
     `Import-Certificate -FilePath .\arena_admin.cer -CertStoreLocation Cert:\LocalMachine\Root`
3. Double-clic sur le `.msix` → Installer

### Certificat de signature MSIX

| Fichier | Contenu | Criticité |
|---|---|---|
| `windows/certificates/arena_admin.pfx` | Certificat + clé privée | 🔴 À sauvegarder (coffre) |
| `windows/certificates/arena_admin.cer` | Certificat public | 🟢 À distribuer |
| `windows/certificates/INFOS.txt` | Mot de passe du .pfx | 🔴 Avec le .pfx |

- Validité : expire le **2031-06-03**. Dossier **gitignoré** — sauvegardé
  dans le coffre chiffré (cf. checklist pré-lancement).
- Régénération : voir le script PowerShell dans `INFOS.txt` ou l'historique
  de ce fichier.

### Vers le Microsoft Store

1. Compte développeur Microsoft (19 $ une fois)
2. `msix_config` (pubspec) : retirer `certificate_path`, mettre l'identité
   du Partner Center
3. `dart run msix:publish` — le Store signe l'app lui-même.

</details>

---

## Alternative sans installation : version portable

Zipper `build/windows/x64/runner/Release/` et lancer `arena.exe`
directement sur le poste cible. Nécessite les
[redistribuables Visual C++](https://aka.ms/vs/17/release/vc_redist.x64.exe)
(présents sur la plupart des Windows).
