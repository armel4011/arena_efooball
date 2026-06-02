# Checklist pré-lancement V1.0 — Arena

Issue de l'audit du 2026-06-02. Deux volets : **actions manuelles obligatoires**
(personne d'autre que vous ne peut les faire) et **validation device** (l'app
doit être testée sur un téléphone réel avec un jeu installé).

---

## 1. Sauvegarde du keystore release (CRITIQUE — perte = perte de l'identité Play Store)

Le keystore `android/arena-release.jks` + ses mots de passe dans
`android/key.properties` sont la **seule** preuve d'identité de l'app sur le
Play Store. S'ils sont perdus (disque mort, vol, réinstallation Windows),
**aucune mise à jour de l'app ne pourra plus jamais être publiée** sous le même
nom de package.

### À faire (30 min, une seule fois)

- [ ] **Copier le keystore + key.properties dans un gestionnaire de mots de passe**
  (Bitwarden / 1Password / Proton Pass — champ "fichier joint") :
  - `android/arena-release.jks` (ou l'emplacement réel indiqué par `storeFile=` dans key.properties)
  - Le contenu de `android/key.properties` (storePassword, keyPassword, keyAlias)
- [ ] **Seconde copie hors machine** : clé USB chiffrée OU archive 7-Zip avec mot de passe
  fort, stockée dans un cloud personnel (Drive/Proton). Ne JAMAIS la committer dans git.
- [ ] **Vérifier la restauration** : ouvrir l'archive depuis un autre appareil et
  confirmer que le .jks s'ouvre (`keytool -list -keystore arena-release.jks`).
- [ ] **(Recommandé)** Activer la **Play App Signing** de Google lors de la première
  publication : Google garde la clé de signature finale, votre .jks ne devient
  qu'une clé d'upload (remplaçable en cas de perte). C'est l'assurance-vie du projet.

### Secrets `.env` (même logique)

- [ ] Copier le contenu de `.env` (racine du projet) dans le même gestionnaire de
  mots de passe. En cas de réinstallation, c'est ce qui permet de relancer le projet.

---

## 2. Validation device — fix C-1 résiduel (PR #14, mergée)

La RLS de `profiles` est désormais **self + admin** ; toutes les lectures
cross-user passent par la vue `public_profiles`. Les scénarios RLS ont été
validés côté base (9/9 OK le 2026-06-02), mais un **smoke test visuel** sur
device reste nécessaire pour confirmer qu'aucun écran n'a été oublié.

> Build : `flutter run --flavor user` puis `--flavor admin` sur device réel.

### App User (avec 2 comptes joueurs, A et B)

- [ ] **Salle de match** : pseudo + avatar de l'adversaire visibles
- [ ] **Chat direct + chat ami** : pseudo du pair affiché, bouton appel présent
- [ ] **Inbox messages** : pseudos des expéditeurs visibles
- [ ] **Bracket + classement par poules** : tous les pseudos visibles
- [ ] **Classement final d'une compétition** : ranking complet avec pseudos
- [ ] **Recherche d'utilisateurs** : résultats avec username/pays/avatar/stats
- [ ] **Page profil public d'un autre joueur** : s'affiche correctement
- [ ] **Appel entrant** : "X vous appelle" affiche bien le pseudo de l'appelant
- [ ] **Inscription** : un username déjà pris est détecté ("déjà utilisé")
- [ ] **Réglages** : votre propre email s'affiche (pas "—")

### App Admin

- [ ] **Liste des users** (`/super/users`) : emails et données complètes visibles
- [ ] **Paiements en attente** : les infos joueur s'affichent
- [ ] **Chat admin→user** : fonctionne dans les deux sens

### Rate-limit TOTP (nouveau, PR #19)

- [ ] Login admin : saisir 3 codes TOTP **faux** → le 3e doit afficher
  « Compte verrouillé après 3 tentatives. Réessayez dans 30 minutes. »
- [ ] Confirmer qu'un code correct est refusé pendant le verrou (429)
- [ ] Après 30 min (ou suppression de la ligne `totp_attempts` via SQL) : login OK

---

## 3. Validation device — Agora RTC (jamais testé en conditions réelles)

Le code de streaming live et d'appels audio est livré mais **n'a jamais été
validé end-to-end** (cf. README « État du projet »). Nécessite 2 devices.

### Streaming finale (MediaProjection + Agora)

- [ ] Admin lance le stream d'une finale → le flux apparaît côté joueurs/spectateurs
- [ ] L'enregistrement local 540p démarre en parallèle (vérifier le fichier ~112 MB/25 min)
- [ ] Mini overlay "Live" : bascule recording → joinAsBroadcaster fonctionne (Android 14+)
- [ ] Fin de stream : teardown propre (pas de moov atom manquant sur le .mp4)

### Appels audio 1v1

- [ ] Appel depuis le chat ami : sonnerie + notification CallKit côté destinataire
- [ ] Décrocher → audio bidirectionnel OK
- [ ] Raccrocher des deux côtés → pas de session fantôme
- [ ] Appel pendant que l'app est en arrière-plan / écran verrouillé

---

## 4. Reste à faire côté GitHub

- [ ] **Merger la PR #2** (codecov-action 4 → 6) manuellement via l'interface web —
  le token CLI local n'a pas le scope `workflow` requis.
- [ ] PRs dependabot **#16 (Gradle 9.5.1)** et **#17 (Kotlin 2.3.21)** : laissées
  ouvertes avec commentaire — leur CI échoue (builds APK cassés). À revisiter
  après une montée de version Flutter.
