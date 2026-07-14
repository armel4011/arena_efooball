# Protocole de test device — Overlay & notif de contrôle (#325 / #326)

> **Pourquoi ce doc ?** Le code natif d'enregistrement (MediaProjection, service
> premier-plan `ArenaRecorderService`, overlay `flutter_overlay_window`,
> notification enrichie) **n'est pas exécuté en CI** — la CI ne fait que compiler.
> Ces scénarios doivent donc être validés **manuellement sur de vrais téléphones**.
>
> Réfs : PR **#325** (overlay non bloquant + guide « paramètres restreints »
> Android 15) et PR **#326** (notif de contrôle unifiée : compteur, Arrêter,
> Ouvrir, échange de code room, coordination avec le bouton flottant).

## 1. Matériel & pré-requis

| Rôle | Téléphone | Contrainte |
|---|---|---|
| **HOME** (domicile — crée la salle, **envoie** le code room) | idéalement **Google Pixel 9 / Android 15 stock** | reproduit le blocage « paramètre restreint » |
| **AWAY** (extérieur — rejoint, **reçoit** le code room) | 2ᵉ téléphone (Android 12+ ; un Xiaomi/MIUI est un bon complément) | — |

Pré-requis :
- **APK release** installé sur les 2 (versionCode strictement supérieur à celui déjà installé — sinon downgrade refusé ; build release signé, cf. `android_signing_state`).
- 2 comptes joueurs distincts, une **compétition avec un match** entre eux (état permettant le démarrage : salle activable).
- Réseau data actif sur les 2 (FCM + Realtime).
- Autoriser les notifications d'Arena sur les 2 (Android 13+ demande `POST_NOTIFICATIONS`).

> Convention : ✅ = conforme, ❌ = bug (noter device + capture + logs `adb logcat`).

---

## 2. Bloc A — Overlay « paramètre restreint » (#325) — sur le Pixel 9

Objectif : sur un APK sideloadé, le toggle « Afficher au-dessus des autres apps »
(`SYSTEM_ALERT_WINDOW`) est grisé « paramètre restreint ». L'enregistrement
anti-triche **ne doit plus en dépendre**.

| # | Étape | Résultat attendu | ✅/❌ |
|---|---|---|---|
| A1 | Installation fraîche, **NE PAS** accorder la superposition. Démarrer un match qui déclenche l'enregistrement. | L'**enregistrement natif démarre quand même** (service premier-plan actif, notif présente). Plus aucun blocage, aucun report `overlay_denied`. | |
| A2 | Observer l'écran après le refus/impossibilité d'overlay. | **Bannière non bloquante** + possibilité d'ouvrir le **guide « paramètres restreints »** (dialog FR, calqué sur le guide MIUI). Rien ne bloque l'usage. | |
| A3 | Suivre le guide : Infos appli → ⋮ → « Autoriser les paramètres restreints » → auth (code/empreinte) → activer « Afficher au-dessus des autres apps ». Relancer un enregistrement. | Le **bouton flottant** apparaît désormais **en plus** de la notif. | |
| A4 | **Régression preuve** (critique — #325 a modifié le chemin de démarrage) : laisser l'enregistrement aller au bout. | La chaîne record → commit → claim → upload → `hash_verified` fonctionne (preuve présente côté serveur), overlay accordé **ou non**. cf. `anticheat_p3_e2e_validation` | |

---

## 3. Bloc B — Notif de contrôle unifiée (#326) — sur les 2 téléphones

Objectif : la notification du service premier-plan est le **repli universel** du
bouton flottant (marche même overlay bloqué). Tester en priorité sur le **Pixel 9
overlay bloqué** (notif seule), puis sur AWAY.

| # | Étape | Résultat attendu | ✅/❌ |
|---|---|---|---|
| B1 | Enregistrement en cours → dérouler la notif. | **Chronomètre** qui défile (`setUsesChronometer`), titre/état lisibles. | |
| B2 | Appuyer sur **« Arrêter »**. | L'enregistrement s'arrête **proprement** (`ACTION_STOP_REQUESTED` → `recorderStopRequested` → `coordinator.stopCleanly()`), fichier finalisé (pas de moov manquant, cf. `recording_stack`). | |
| B3 | Enregistrement en cours → **taper le corps** de la notif. | **Arena s'ouvre** (au bon écran). | |
| B4 | **HOME (domicile)** : dans la notif, utiliser la **réponse directe** (RemoteInput) pour **envoyer** le code room. | Le code part (transport `matches.room_code` + trigger + `sendRoomCode`). PendingIntent **MUTABLE** requis → vérifier que la saisie fonctionne. | |
| B5 | **AWAY (extérieur)** : réception. | La notif AWAY **affiche le code** reçu + action **« Copier »**. **Copier fonctionne** (contrairement à l'overlay/MIUI où le presse-papier est bloqué). | |
| B6 | Coller le code dans le champ salle côté AWAY. | Le code est correct → AWAY rejoint la salle. | |

### Coordination des 2 surfaces (overlay accordé — sur le Pixel 9 après A3, ou AWAY si overlay OK)

| # | Étape | Résultat attendu | ✅/❌ |
|---|---|---|---|
| B7 | Overlay accordé → vérifier que **notif ET bouton flottant** sont présents. | Les **2 surfaces** coexistent. | |
| B8 | Arrêter via **le bouton flottant**. | La **notif se ferme** aussi (stop coordonné). | |
| B9 | Relancer, puis arrêter via **« Arrêter » de la notif**. | Le **bouton flottant disparaît** aussi. | |
| B10 | Cas overlay **bloqué** (Pixel 9 sans A3). | **Notif seule** (pas de bouton flottant), et l'enregistrement fonctionne quand même. | |

---

## 4. Bloc C — Bout-en-bout à deux téléphones

| # | Scénario complet | Attendu | ✅/❌ |
|---|---|---|---|
| C1 | HOME crée la salle → **envoie le code via la notif** (B4) → AWAY **reçoit + Copier** (B5) → match joué → enregistrements des 2 côtés → preuve vérifiée serveur. | Toute la chaîne passe, sur Pixel 9 **overlay bloqué** comme accordé. | |

---

## 5. Journalisation en cas d'échec

- `adb logcat -s ArenaRecorderService arena/native flutter` pendant le scénario.
- ⚠️ En **release**, `debugPrint` est muet (cf. `overlay_room_code_sender`) → s'appuyer sur les logs natifs (Kotlin `Log.x`) et l'état serveur (`streams`, `matches.room_code`).
- Noter : modèle exact, version Android, versionCode APK, overlay accordé (O/N).

## 6. Critère de clôture

Tous les ✅ sur **Pixel 9 (overlay bloqué)** + **1 second device** ⇒ #325/#326
validés runtime → lever la mention « RESTE validation device » de la passation.
