# Note d'action — C-1 (suppression RGPD) & C-2 (remboursement à l'annulation)

> Issus de l'audit global v2 du 2026-06-05. Ces deux points sont classés **ÉLEVÉ**
> mais sortis du lot de correctifs rapides car ils touchent de l'argent réel et
> une obligation légale → ils demandent une **décision produit** avant code.

## ✅ État d'implémentation (2026-06-05)

- **C-1 — décision retenue : Option 1 (anonymiser + conserver la compta).**
  Livré : colonne `profiles.anonymized_at`, RPC `anonymize_deleted_account(uuid)`
  (scrub PII, service_role only), et réécriture de la cron `cleanup-deleted-accounts`
  (anonymise le profile + scrub auth.users email/metadata + ban login, au lieu de
  `deleteUser`). Les lignes payments/payouts survivent anonymisées. Idempotent via
  `anonymized_at IS NULL`.
- **C-2 — livré : Option 1 (stop-the-bleeding).** Label « refund all » trompeur
  corrigé, texte de confirmation honnête, et RPC `cancel_competition(uuid)` qui
  annule + **notifie** chaque joueur ayant payé (push + inbox) qu'un remboursement
  manuel suivra. **Reste à faire (Option 2, cible V1)** : file de remboursement
  traçable (marquer les paiements `refunded` une fois le P2P effectué).

---

## C-1 · La suppression de compte RGPD échoue pour tout utilisateur ayant joué/payé

### Symptôme
La cron `cleanup-deleted-accounts` (quotidienne, 03:15) appelle
`auth.admin.deleteUser(id)` pour purger les comptes soft-deleted depuis > 30 j
(`supabase/functions/cleanup-deleted-accounts/index.ts:164`).

### Cause racine
`profiles.id → auth.users` est `ON DELETE CASCADE`, mais les tables filles
financières/d'inscription sont `ON DELETE RESTRICT` :
- `payments.user_id` → RESTRICT (`20260505100004_chat_payments_disputes_notifs.sql:69`)
- `payouts.user_id` → RESTRICT (`…:117`)
- `competition_registrations.player_id` → RESTRICT (`20260505100006:177`)

Donc dès qu'un utilisateur a **ne serait-ce qu'une inscription** (même gratuite),
`deleteUser` lève une violation FK, tombe dans `errors[]`, et le compte reste en
limbe « soft-deleted » indéfiniment. **La promesse « supprimé sous 30 jours »
(`delete_account_page.dart`) n'est pas tenue** pour les vrais utilisateurs.

### Tension à arbitrer
RGPD (droit à l'effacement) **vs** obligation de conservation comptable
(les lignes `payments`/`payouts` sont des pièces financières, d'où le RESTRICT).
On ne peut pas simplement passer en CASCADE sans détruire la trace compta.

### Options
1. **Anonymisation en place (recommandé)** : avant `deleteUser`, remplacer les PII
   du `profiles` (username → `deleted_user_<hash>`, email/whatsapp/avatar/etc. → null)
   et **conserver** les lignes compta en les rattachant à un profil tombstone, OU
   passer les FK compta en `SET NULL` + scrubbing. Le compte auth peut alors être
   supprimé (plus de PII), la compta survit anonymisée. Conforme RGPD (les données
   comptables anonymisées ne sont plus des données personnelles).
2. **Suppression explicite ordonnée** : DELETE des lignes filles dans l'ordre
   (payouts → platform_revenue → payments → registrations → …) dans une RPC
   `purge_user(uuid)` DEFINER avant `deleteUser`. ⚠️ détruit la trace compta —
   à éviter si obligation de conservation.
3. **Statu quo documenté** : assumer que les comptes ayant transigé ne sont
   jamais hard-deleted (seulement anonymisés/désactivés) — mais alors il faut
   corriger le texte UI qui promet une suppression complète.

### Recommandation
Option 1. Implémenter une RPC `anonymize_user(uuid)` SECURITY DEFINER (scrub PII +
SET NULL des FK acteurs) appelée par la cron AVANT `deleteUser`, et faire échouer
proprement/journaliser si une ligne compta empêche encore la suppression.

### Stop-the-bleeding immédiat (sans décision produit)
Au minimum : faire en sorte que la cron **logue explicitement** les comptes qu'elle
n'a pas pu supprimer (aujourd'hui ils disparaissent silencieusement dans `errors[]`),
pour avoir la visibilité du backlog RGPD réel.

---

## C-2 · Le bouton « ANNULER (refund all) » ne rembourse rien

### Symptôme
`admin_competition_actions_tab.dart:78` affiche un bouton
« 🚫 ANNULER (refund all) ». La confirmation annonce « Les remboursements seront
déclenchés en PHASE 11bis » (`:161`), mais `_cancel` n'appelle que
`.cancel(competition.id)` — un simple flip de `status`. **Aucun remboursement,
aucune notification** aux joueurs ayant payé, aucune écriture `payouts`/`refunded`.

### Impact
En P2P manuel, le joueur a **déjà payé** (encaissement réel sur le code marchand)
avant l'annulation. Le label « refund all » est mensonger : l'argent est perdu côté
joueur sans trace ni information. Risque litige + réputation.

### Options
1. **Stop-the-bleeding (rapide, recommandé en 1er)** : retirer « refund all » du
   label (→ « ANNULER la compétition »), et à l'annulation **notifier** tous les
   inscrits ayant un `payments.status='succeeded'` qu'un remboursement manuel va
   être traité (réutilise le dispatcher de notifs existant).
2. **Remboursement traçable (cible V1)** : à l'annulation, générer une ligne par
   paiement `succeeded` dans une file de remboursement (`payouts` type `refund`
   ou statut `payments.refunded`) que le super-admin traite manuellement via Mobile
   Money — cohérent avec le P2P manuel actuel. Marquer `payments.status='refunded'`
   une fois fait.
3. **Automatique** : hors périmètre V1 (pas de passerelle de paiement automatisée
   avant CinetPay/NowPayments V2).

### Recommandation
Faire (1) tout de suite (corrige le mensonge + informe les joueurs), puis (2) comme
chantier V1 pour la traçabilité des remboursements.

---

## Synthèse priorité

| Point | Gravité | Effort | Action court terme | Cible |
|---|---|---|---|---|
| C-1 RGPD deletion | ÉLEVÉ (légal) | élevé | logguer le backlog non-supprimé | RPC `anonymize_user` |
| C-2 refund fantôme | ÉLEVÉ (argent) | moyen | corriger label + notifier inscrits payants | file de remboursement P2P |
