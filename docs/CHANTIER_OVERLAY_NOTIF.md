# Chantier — Cycle de vie overlay + notif RemoteViews (2026-07-14)

Issu de la validation device #325/#326 (cf. `PROTOCOLE_TEST_DEVICE_325_326.md` §7).
Trois volets, conçus ici pour être implémentés **sans** boucle build/test à l'aveugle.

---

## Volet 1 — Cycle de vie overlay (bouton flottant figé au 2ᵉ démarrage)

### Cause racine (confirmée par lecture du code + du plugin)
`flutter_overlay_window: ^0.5.0` **réutilise le même `FlutterEngine`** pour l'overlay.
- `_ArenaOverlayRoot.initState` (`recording_overlay.dart`) s'abonne à
  `FlutterOverlayWindow.overlayListener` **une seule fois**.
- `closeOverlay()` **ferme ce stream** et détache la vue.
- `showOverlay()` (2ᵉ appel) **ré-attache le moteur en cache SANS relancer
  `overlayMain`/`initState`** → l'abonnement `overlayListener` reste **mort** → plus
  aucun tick/action ne remonte → **chrono figé, boutons inertes, non fermable**.
- Le plugin 0.5.0 n'expose **aucune** API pour détruire/recréer le moteur.

### Décision : « show-once, morph-forever, close-only-on-dispose »
On n'appelle **JAMAIS** `closeOverlay()` au milieu d'un match. L'overlay est montré
**une seule fois** (au 1ᵉʳ `start`/code-sender) puis **morphé** entre états. Fermeture
réelle uniquement à : `coordinator.dispose()` (sortie de salle), statut terminal, ou
bascule Live.

- Recording **stop** → `idle()` : garde moteur + listener + port vivants, coupe les
  ticks, et **morphe vers un visuel « ARRÊTÉ » DISTINCT** (≠ pause).
- Recording **restart** → `morphToRecording()` (déjà existant) sur le moteur vivant →
  pas de 2ᵉ `showOverlay` → **plus de gel**.

⚠️ **Leçon de la tentative 3037** : l'`idle()` avait réutilisé le visuel `paused`
(face jaune, chrono figé) → l'utilisateur l'a lu comme « figé/cassé ». Il FAUT un
visuel dédié.

### À implémenter
1. `RecordingOverlayMessages` : ajouter `modeIdle` + `OverlayMode.idle` (mappé dans
   `overlayModeFromMessage`).
2. `recording_overlay.dart` : rendre le mode idle = **bouton gris « ⏺ Reprendre »**
   (clairement arrêté, tap → `focus_main`/réouvre les actions), chrono masqué.
3. `RecordingOverlayController.idle()` : push `modeIdle` (pas `paused`), garde
   overlay/listener/port, coupe le tick. `stop()` (close réel) inchangé.
4. Coordinator : `_doStopCleanly` → `_overlay.idle()` ; `dispose()`/terminal/goLive →
   `_overlay.stop()` (close réel). (cf. tentative revertée, à re-appliquer proprement.)

### Validation device (obligatoire)
Démarrer → **Arrêter** (bouton devient « Reprendre » gris, **tappable**) → **Reprendre**
(chrono repart, actions OK) → répéter ×3 → quitter la salle (overlay disparaît).

---

## Volet 2 — Notif de contrôle : boutons colorés + icônes (RemoteViews)

### Contrainte Android (confirmée)
Les actions de notif **standard** n'affichent **pas** d'icône sur Android 7+ (libellé
texte seul) et **ne se colorent pas** individuellement. → nécessite une **notification
à layout personnalisé (RemoteViews)**.

### Décision : `setCustomContentView` + `setCustomBigContentView`
Deux layouts XML (`res/layout/notif_recorder_*.xml`) :
- **collapsed** : icône + titre + `Chronometer` (compteur natif qui défile seul).
- **expanded** : le chrono + une rangée de **boutons colorés** (fond teinté + icône +
  libellé) : ⏹ Arrêter (rouge), ⧉ Ouvrir (bleu), ➤ Envoyer / ⧉ Copier (cyan).
- Chaque bouton → `PendingIntent` (mêmes actions qu'aujourd'hui : `ACTION_STOP_REQUESTED`,
  ouvrir MainActivity, `ACTION_SUBMIT_CODE` via RemoteInput / `ACTION_COPY_CODE`).
- `setColorized(true)` + canal importance HIGH pour la proéminence (pas d'API pour
  « épingler en tête » — au mieux ça).

### Pièges RemoteViews
- Vues limitées (`TextView`, `ImageView`, `Button`, `Chronometer`, `LinearLayout`…).
- `RemoteInput` (réponse directe) fonctionne AVEC un bouton custom → attacher via
  `NotificationCompat.Action` **hors** RemoteViews OU via un `PendingIntent` + champ ;
  ⚠️ à tester : le champ inline de réponse directe n'est pas rendu dans un RemoteViews
  custom → possible repli sur l'action standard pour l'ENVOI et RemoteViews pour le reste.
- Teinte des fonds via drawable + `setInt(viewId, "setColorFilter"/"setBackgroundColor")`.

### Validation device
Rendu correct collapsed + expanded sur Samsung ET Xiaomi/MIUI (thème sombre inclus).

---

## Volet 3 — Code rééditable + renvoi (2ᵉ envoi)

### État
En prod (code actuel), le HOME envoie le code **une fois** (`awaitingCode: !hasCode`) ;
après envoi le champ disparaît. La demande : pouvoir **modifier/renvoyer** le code.

### Bug du 2ᵉ envoi (observé sur la tentative revertée)
Avec `awaitingCode` gardé à `true`, le 2ᵉ `ACTION_SUBMIT_CODE` ne repartait pas.
Hypothèse : le `PendingIntent` (requestCode fixe = 2, `FLAG_MUTABLE|FLAG_UPDATE_CURRENT`)
+ le `RemoteInput` re-postés ne ré-attachent pas le résultat au 2ᵉ coup.
→ À corriger : requestCode **incrémental** par rebuild de notif, et vider
`remoteInputHistory` après lecture. À valider sur device.

### À implémenter
- `awaitingCode` reste `true` côté HOME (label « Modifier le code », affiche le code
  courant). `ACTION_SUBMIT_CODE` : garder `awaitingCode=true`, `roomCode=typed`.
- Dépend du Volet 2 (intégration RemoteInput dans/à côté du RemoteViews).

---

## Ordre proposé & principe de validation
1. **Volet 1** (vrai bug prod) — 1 build → validation device (le protocole ci-dessus).
2. **Volet 2** (RemoteViews) — 1 build → validation rendu device.
3. **Volet 3** (rééditable/renvoi) — greffé sur le Volet 2.

Un build par volet, validé sur device avant le suivant — pas d'empilement à l'aveugle.
