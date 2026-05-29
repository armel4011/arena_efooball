# Offline-first ARENA — implémentation

> Réponse technique à la spec `android/offline.md`. Objectif : l'app reste
> utilisable sans Internet, les données déjà chargées restent visibles, et
> les actions sont rejouées automatiquement au retour du réseau, sans perte.

## 1. Vue d'ensemble

La stack offline repose sur **3 services centralisés** + **1 widget UI**, tous
branchés une fois au boot via Riverpod et gardés vivants pour la session :

| Service | Rôle | Fichier |
|---------|------|---------|
| `NetworkStatusService` | Détecte l'état réseau (online / slow / offline / reconnexion) | `lib/core/services/network_status_service.dart` |
| `PersistentCache` | Persiste la dernière donnée connue sur disque (SharedPreferences) | `lib/core/services/persistent_cache.dart` |
| `SyncQueueService` | File d'attente des mutations offline + auto-flush + façade `OfflineAwareActions` | `lib/core/services/sync_queue_service.dart` |
| `OfflineBanner` | Indicateur visuel hors-ligne / lent / synchronisation / reconnecté | `lib/features_shared/widgets/offline_banner.dart` |

Les 3 services sont ancrés dans `MainLayout` (`ref.watch(...)`) et le banner
est monté tout en haut du `body`.

## 2. Schéma de flux Offline → Sync → Online

```
                         ┌─────────────────────────────────────────────┐
                         │            NetworkStatusService              │
   connectivity_plus ───▶│  interface OS + sonde latence (/auth/health) │
                         │   none→offline · lent→slow · ok→online       │
                         └───────┬───────────────────────┬─────────────┘
                                 │ stream                 │ current/isConnected
                  ┌──────────────▼──────────┐    ┌────────▼──────────────┐
                  │       OfflineBanner      │    │    SyncQueueService    │
                  │  hors-ligne / lent /     │    │  auto-flush au retour  │
                  │  sync… / reconnecté      │◀───┤  réseau (online|slow)  │
                  └──────────────────────────┘    └────────┬───────────────┘
                                                           │
   ┌─────────────────── LECTURE (offline-first) ──────────┼──────────────┐
   │                                                       │              │
   │   StreamProvider Supabase ──▶ PersistentCache.hydrate*│              │
   │        (realtime)              ▲          │           │              │
   │                                │ persist  │ yield     │              │
   │                          SharedPreferences│ cache d'abord            │
   │                                           ▼           │              │
   │                                    UI (jamais d'écran vide/erreur)   │
   └───────────────────────────────────────────────────────────────────┘

   ┌─────────────────── ÉCRITURE (action utilisateur) ─────────────────┐
   │  UI ──▶ OfflineAwareActions.xxx()                                  │
   │           │                                                        │
   │           ├─ online ──▶ repository.insert() (direct)               │
   │           └─ offline ─▶ SyncQueueService.enqueue(SyncAction)        │
   │                              │ persiste JSON (SharedPreferences)    │
   │                              ▼                                      │
   │             [retour réseau] auto-flush ──▶ action.execute(client)   │
   │                              │  succès / 23505 / 42501 → drop       │
   │                              │  erreur transitoire     → garde      │
   │                              ▼                                      │
   │                        Supabase (idempotent via id local = PK)      │
   └────────────────────────────────────────────────────────────────────┘
```

## 3. Détails par exigence

### 1–2. Persistance locale + Offline-first
`PersistentCache` sérialise en JSON dans SharedPreferences. Les
`StreamProvider` passent par `hydrate` / `hydrateSingle` / `hydratePairs` :
le cache est **émis en premier** (affichage immédiat au cold start), puis
chaque event realtime remplace l'UI **et** réécrit le cache. Si le stream
lève (réseau coupé), l'exception est avalée → l'UI reste figée sur la
dernière donnée connue, **jamais d'écran d'erreur réseau**.

Modules câblés sur le cache : notifications, matchs actifs, compétitions,
amis, chat admin, profil courant.

### 3. États réseau (`NetworkStatus`)
- `online` — interface active + sonde rapide (< 1500 ms)
- `slow` — interface active mais sonde lente **ou** en échec (dégradé, pas
  offline : on évite les faux négatifs)
- `offline` — aucune interface réseau (signal fiable de `connectivity_plus`)
- `unknown` — ~100 ms au boot, traité comme online

La **sonde de latence** fait un `HEAD` vers `<SUPABASE_URL>/auth/v1/health`
toutes les 30 s (et à chaque changement d'interface), avec un timeout de 4 s.
Elle comble le trou de `connectivity_plus` qui ne voit que l'interface, pas
la joignabilité réelle.

### 4. Cache intelligent par module
Voir §1–2. Invalidation par `_schemaVersion` (bump = purge des caches
`arena.cache.*`) pour éviter de désérialiser un vieux format.

### 5. Synchronisation automatique
`SyncQueueService.attach()` écoute le stream réseau et draine la queue dès
qu'une interface redevient active (`online` **ou** `slow`). Flush aussi
immédiat à l'enqueue si déjà connecté, et au boot si la queue n'est pas vide.

### 6. File d'attente des actions offline
`SyncAction` (sealed) sérialisée en JSON. Actions branchées :
- `MarkNotificationReadAction` (`notif.read`)
- `SendChatMessageAction` (`chat.send`)
- `RegisterFreeCompetitionAction` (`competition.register_free`)

Façade `OfflineAwareActions` : `if (offline) enqueue else repository.call()`.
Câblée dans `notifications_page`, `chat_page`, `friend_chat_page`,
`registration_confirm_page`. Chaque action en file renvoie un feedback UI
(SnackBar « envoyé à la reconnexion »).

### 7. Gestion des conflits — Last Write Wins
Chaque action porte un `createdAt` (horodatage local) et un `id` UUID v4 qui
sert d'**idempotency key** (PK côté serveur). Au flush :
- `notif.read` : `.filter('read_at', 'is', null)` → un read déjà stampé n'est
  pas écrasé.
- `chat.send` : `id` = PK ; un doublon (23505) est considéré idempotent → drop.
- `register_free` : unique `(competition_id, player_id)` ; 23505 → déjà inscrit.
- RLS denied (42501) → action définitivement invalide → drop. Erreur
  transitoire (réseau) → conservée pour retry.

### 8. Expérience utilisateur
`OfflineBanner` affiche 5 états par priorité : **HORS LIGNE** (+ compteur
d'actions en file), **SYNCHRONISATION…** (spinner + nb restant), **CONNEXION
LENTE**, **RECONNECTÉ** (flash 2 s), masqué. Alimenté par
`networkStatusProvider` + le `ValueNotifier<SyncState>` exposé par la queue.

### 9. Robustesse
`try/catch` systématique, fail-open au boot (réseau inconnu = online),
swallow des erreurs de stream, timeout sur la sonde, retry automatique des
actions non-définitives, purge du cache corrompu.

### 10. Refactoring propre
Code modulaire (1 service = 1 responsabilité), commenté sur les parties
critiques (LWW, idempotency, swallow), pas de duplication (façade unique).

## 4. Fichiers créés / modifiés

**Créés**
- `lib/core/services/network_status_service.dart`
- `lib/core/services/persistent_cache.dart`
- `lib/core/services/sync_queue_service.dart`
- `lib/features_shared/widgets/offline_banner.dart`

**Modifiés (cache hydrate)**
- `lib/data/repositories/notification_repository.dart`
- `lib/data/repositories/match_repository.dart`
- `lib/data/repositories/competition_repository.dart`
- `lib/data/repositories/friends_repository.dart`
- `lib/data/repositories/admin_chat_repository.dart`
- `lib/features_shared/auth_common/shared_auth_providers.dart` (profil)

**Modifiés (montage + actions offline)**
- `lib/features_user/home/main_layout.dart`
- `lib/features_user/notifications/notifications_page.dart`
- `lib/features_user/chat/chat_page.dart`
- `lib/features_user/chat/friend_chat_page.dart`
- `lib/features_user/competitions/registration_confirm_page.dart`

**Dépendances** : `connectivity_plus`, `shared_preferences` (déjà présentes).

## 5. Limites connues (V1)
- La sonde de latence est mobile/desktop only (`dart:io HttpClient`).
- Messages chat envoyés offline : pas d'affichage optimiste (ils
  apparaissent après le flush) — feedback via SnackBar en attendant.
- `slow` regroupe « latence haute » et « captive portal » (sonde en échec
  alors que l'interface est up) — choix volontaire pour ne jamais couper
  l'UI à tort.
