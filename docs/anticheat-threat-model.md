# Modèle de menace — anti-triche ARENA

_Statut : 2026-07-09. Formalise le finding P1 #4 de l'audit 2026-07-07
(« commitment non lié à la capture réelle ») en modèle de menace explicite et
en trace la limite fondamentale + l'escalade prévue._

## But

Prouver, en cas de litige sur un match à enjeu financier, que le score déclaré
correspond à ce qui s'est réellement passé à l'écran d'un joueur — sans exiger
d'uploader systématiquement des vidéos lourdes (coût réseau/stockage
prohibitif sur des devices bas de gamme en 2G).

## Les deux tiers de capture

| Tier | Mécanisme | Où est calculée la preuve | Falsifiable ? |
|------|-----------|---------------------------|----------------|
| **Natif** (`native_recorder`) | MediaProjection Kotlin → MP4 local → proxy 360p → SHA-256 → commitment (`anticheat-commit`) ; vidéo uploadée seulement sur réclamation admin (`proof-verify`) | **Sur le device du joueur** (non fiable) | **Oui** (voir menace ci-dessous) |
| **Egress** (`livekit_track_egress`) | LiveKit publie la piste écran → **Track Egress côté serveur** écrit le WebM dans le bucket `match-recordings` | **Sur le serveur** (le client ne voit jamais le fichier) | **Non** |

Le provider actif est piloté par `app_config.anticheat_provider`. Le natif reste
le **filet de sécurité permanent** ; l'egress est le tier infalsifiable.

## La menace (P1 #4) — commitment natif non lié à la capture réelle

Le commitment natif hashe un fichier **choisi par le client**
(`proof_commitment_service.dart`) et l'EF `anticheat-commit` accepte **n'importe
quel SHA-256 bien formé**. Un attaquant qui **repackage l'APK** (ou tourne sur un
device rooté) peut donc :

1. jouer/tricher sans réellement capturer son écran ;
2. produire hors-ligne une vidéo « propre » retouchée ;
3. en engager le hash comme commitment.

Sur litige, il livrera cette vidéo retouchée : son hash correspondra au
commitment (`proof_hash_verified = true`) alors qu'elle ne reflète pas la partie.

### Pourquoi on ne peut PAS le corriger sur le tier natif

Lier cryptographiquement un hash calculé **sur un device non fiable** au vrai
contenu de l'écran est **impossible** sans une racine de confiance côté
plateforme. Le commitment natif apporte une garantie réelle mais **partielle** :

- il est **write-once** et **horodaté serveur** → un tricheur ne peut pas
  ré-engager le hash d'une vidéo trafiquée **après** qu'un litige a éclaté ;
- il **engage** le joueur : ne pas livrer, ou livrer un fichier au hash
  différent, est une charge contre lui.

Contre un joueur ordinaire (APK officiel non modifié), c'est une **déterrence
forte** (~90 % du risque réel). Contre un attaquant déterminé qui repackage
l'APK, **c'est contournable**. C'est un **risque résiduel assumé et documenté**.

## Parade retenue (décision 2026-07-09) : documenter + s'appuyer sur l'egress

Plutôt qu'une attestation d'intégrité (Play Integrity — écartée : exige
d'enregistrer l'app dans la Google Play Console alors qu'ARENA est en
distribution APK directe, cf. décision Play Store / RMG), la parade est :

1. **Ce document** : le risque résiduel du tier natif est explicite, pas un
   angle mort.
2. **L'egress comme escalade haut-enjeu** : pour les compétitions à forte
   cagnotte, basculer `anticheat_provider = livekit_track_egress` donne une
   preuve **infalsifiable** (capture serveur, le client ne touche jamais le
   fichier). L'egress est **déjà implémenté et validé E2E** ; il reste
   **désactivé en prod** à cause d'une régression de crash à froid sur
   Android 14+/targetSdk 36 (FGS mediaProjection démarré avant le consentement).
   **Débloquer l'egress = corriger ce crash**, pas réécrire l'anti-triche.

### Complément côté finalisation (P1 #5, migration 20260709120000)

Indépendamment de la falsifiabilité du hash, la capture était **facultative** et
la soumission de score n'était gatée sur **rien** : absence de preuve
indiscernable d'un échec réseau. Le soft-gate corrige ce trou :

- **trace toujours** : `streams.capture_status` (`committed` | `unavailable`) +
  `capture_note` ; à la finalisation d'un match à prix dont le vainqueur n'a pas
  de commitment, un event `match_events.proof_missing` est **toujours**
  journalisé (les admins voient enfin le phénomène) ;
- **enforcement optionnel** : si `app_config.proof_gate_enforced = true`, un tel
  match est routé vers `disputed` (revue super-admin) au lieu de `completed`.
  Défaut **OFF** tant que la fiabilité de la capture native n'est pas prouvée
  (échecs fréquents MIUI / FGS targetSdk36), pour ne pas inonder la file de
  litiges.

## En résumé

- Le commitment natif = **déterrence forte, pas une preuve infalsifiable**.
- La preuve infalsifiable existe (**egress**) et est **prête** ; son activation
  prod dépend du fix crash targetSdk36.
- Le soft-gate P1 #5 garantit qu'une absence de preuve est **toujours tracée**,
  et **bloquante à la demande** (flag), sans jamais confondre triche et échec
  device.
