# Distribution de ARENA Admin Desktop (Windows)

Guide pour générer l'installeur MSIX et installer l'app sur d'autres
ordinateurs Windows 10/11.

---

## 1. Générer l'installeur (sur le poste de développement)

```sh
# 1. Build release de l'app desktop
flutter build windows -t lib/main_admin_desktop.dart

# 2. Création du paquet MSIX signé (config dans pubspec.yaml > msix_config)
dart run msix:create --build-windows false
```

→ Résultat : **`dist/arena-admin-setup.msix`** (~72 MB)

> ⚠️ L'app desktop ne doit **pas être en cours d'exécution** pendant la
> génération (elle verrouille des fichiers dans le dossier Release).
> La fermer d'abord : `taskkill /F /IM arena.exe`

---

## 2. Installer sur un autre ordinateur

### Fichiers à copier sur le poste cible (clé USB / réseau)

| Fichier | Rôle |
|---|---|
| `dist/arena-admin-setup.msix` | L'installeur de l'app |
| `windows/certificates/arena_admin.cer` | Le certificat à approuver (1 seule fois par poste) |

### Étape A — Installer le certificat (une seule fois par poste)

L'app est signée avec un certificat auto-signé « Arena Admin ». Windows
doit l'approuver avant d'accepter l'installeur.

**Option 1 — Interface graphique :**
1. Clic droit sur `arena_admin.cer` → **Installer le certificat**
2. Emplacement : **Ordinateur local** (nécessite les droits admin)
3. **Placer tous les certificats dans le magasin suivant** → Parcourir →
   **Autorités de certification racines de confiance** → OK → Terminer

**Option 2 — PowerShell (en administrateur) :**
```powershell
Import-Certificate -FilePath .\arena_admin.cer `
  -CertStoreLocation Cert:\LocalMachine\Root
```

### Étape B — Installer l'app

1. Double-clic sur `arena-admin-setup.msix`
2. Cliquer **Installer**
3. L'app **ARENA Admin** apparaît dans le menu Démarrer 🎉

### Mises à jour

Pour mettre à jour l'app sur un poste : regénérer le MSIX (avec un
`msix_version` supérieur dans `pubspec.yaml`, ex. `1.0.1.0`), copier le
nouveau `.msix` sur le poste et double-cliquer → **Mettre à jour**.
Le certificat n'a pas besoin d'être réinstallé.

---

## 3. Gestion du certificat

| Fichier | Contenu | Criticité |
|---|---|---|
| `windows/certificates/arena_admin.pfx` | Certificat **+ clé privée** (signe les MSIX) | 🔴 À sauvegarder comme le keystore Android |
| `windows/certificates/arena_admin.cer` | Certificat public (à distribuer aux postes) | 🟢 Public |
| `windows/certificates/INFOS.txt` | Mot de passe du .pfx | 🔴 Avec le .pfx |

- **Validité** : 5 ans (expire le 2031-06-03)
- **Le dossier `windows/certificates/` est gitignoré** — sauvegardez-le
  dans le même coffre que `arena-release.jks` / `key.properties`.
- ⚠️ Si le `.pfx` est perdu : régénérer un certificat (procédure ci-dessous)
  et **réinstaller le nouveau `.cer` sur tous les postes** (les mises à
  jour signées avec un nouveau certificat exigent de désinstaller/réinstaller l'app).

### Régénération du certificat (PowerShell)

```powershell
$cert = New-SelfSignedCertificate -Type Custom -Subject "CN=Arena Admin" `
  -KeyUsage DigitalSignature -FriendlyName "Arena Admin Desktop" `
  -CertStoreLocation "Cert:\CurrentUser\My" -NotAfter (Get-Date).AddYears(5) `
  -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.3", "2.5.29.19={text}")
$password = ConvertTo-SecureString -String "<MOT_DE_PASSE>" -Force -AsPlainText
Export-PfxCertificate -Cert $cert -FilePath "windows\certificates\arena_admin.pfx" -Password $password
Export-Certificate -Cert $cert -FilePath "windows\certificates\arena_admin.cer"
```

Puis mettre à jour `certificate_password` dans `pubspec.yaml` (msix_config).

---

## 4. Alternative sans installation : version portable

Pour un usage ponctuel (pas d'installation, pas de certificat) :
zipper le dossier `build/windows/x64/runner/Release/` et le copier sur
le poste cible → lancer `arena.exe` directement. Fonctionne tant que les
[redistribuables Visual C++](https://aka.ms/vs/17/release/vc_redist.x64.exe)
sont présents (préinstallés sur la plupart des Windows).

---

## 5. Vers le Microsoft Store (plus tard)

Pour une distribution publique sans gestion de certificat :
1. Compte développeur Microsoft (19 $ une fois)
2. `msix_config` : retirer `certificate_path` et ajouter l'identité fournie
   par le Partner Center
3. `dart run msix:publish` ou upload manuel du `.msix`

Le Store signe l'app lui-même — plus aucun certificat à gérer.
