# Note de conception — F-1 : pipeline de versement des gains (payouts)

> Audit v3, finding **CRITIQUE**. Le cycle de vie d'une compétition va jusqu'à
> `completed`, mais **le versement des gains n'est câblé nulle part** : aucun
> trigger / RPC / écran ne **crée** de ligne `payouts`. `prize_distribution` et
> `prize_amounts` sont stockés mais jamais consommés ; l'app ne fait que **lire**
> `payouts` pour un KPI. Conséquence : le gagnant n'est jamais payé par le
> système, et il n'existe même pas de file manuelle de payouts à traiter.

## État actuel (constaté)

- `competitions` porte `prize_distribution` (jsonb, ex. `{"1": 0.5, "2": 0.3, ...}`)
  et/ou `prize_amounts`, plus `prize_pool_local` / `commission_xaf`.
- `competition_registrations.final_rank` existe (classement final).
- `payouts` (table) : lue par `admin_kpis_repository.dart` uniquement. Colonnes
  montant en place, FK `ON DELETE RESTRICT`, guard `guard_payouts_financial_columns`
  (anti-falsification) + `payouts_admin_update` (désormais `is_super_admin()`).
- **Aucun producteur** de lignes `payouts`. Aucun trigger sur `status=completed`.

## Cohérence avec le modèle V1 (P2P manuel)

Comme les paiements entrants, les **versements sortants sont manuels** (Mobile
Money par le staff). Le système n'a donc pas à *exécuter* le paiement, mais il
doit : (1) **calculer** qui gagne combien, (2) **matérialiser** des lignes
`payouts` en attente, (3) offrir une **file admin** pour les marquer payés, (4)
**notifier** les gagnants.

## Conception proposée

### 1. Génération des payouts à la clôture
RPC `generate_payouts(p_competition_id uuid)` SECURITY DEFINER, gate
`is_super_admin()` (sortie d'argent), idempotente (skip si des payouts existent
déjà pour la compétition) :
- lit `prize_distribution` + `prize_pool_local` (net de `commission_xaf`) ;
- lit les `final_rank` des `competition_registrations` ;
- pour chaque rang récompensé, insère une ligne `payouts` (user_id, amount_local,
  currency, `status='pending'`, competition_id, rank) ;
- insère une notification « Tu as gagné X » par bénéficiaire.

Déclenchement : soit un **bouton admin** « 💰 Générer les versements » visible
quand `status=completed` (cohérent avec le P2P manuel, garde le contrôle humain),
soit un trigger `AFTER UPDATE OF status WHEN completed`. **Recommandé : bouton**
(évite de générer sur un classement encore incomplet/contesté).

### 2. File de versements + validation
- Écran admin `/super/payouts` : liste les `payouts.status='pending'` avec le
  numéro Mobile Money du gagnant (à ajouter au flux : le gagnant doit fournir son
  numéro de retrait — nouvelle colonne `payouts.payee_phone` ou réutiliser un
  champ profil).
- Le super-admin effectue le virement Mobile Money réel, puis marque la ligne
  `paid` via RPC `mark_payout_paid(p_payout_id)` (gate `is_super_admin()`,
  horodate `validated_at`/`validated_by_admin_id`).

### 3. Garde-fous
- Index unique `(competition_id, user_id, rank)` anti-double-génération.
- CHECK somme des payouts ≤ `prize_pool_local` (cohérence financière).
- Le bénéficiaire ne fournit QUE son numéro de retrait ; montants calculés serveur
  (jamais client), comme `guard_payments_amount`.

## Dépendances / questions ouvertes (décision produit)

1. **Numéro de retrait du gagnant** : collecté où ? (profil ? au moment du gain ?)
2. **Litige sur le classement** : faut-il un délai/gel avant génération des payouts ?
3. **Compétition annulée après paiements** : lien avec C-2 (remboursements) — même
   file de sortie d'argent ? unifier `payouts` (gains) et remboursements ?
4. **Commission** : `commission_xaf` est-il retenu avant ou après distribution ?

## Effort estimé
Migration (RPC generate_payouts + mark_payout_paid + colonne payee_phone +
contraintes) + écran admin `/super/payouts` + repo + notifications. **Chantier
moyen** (1 vague), à cadrer avec les 4 décisions produit ci-dessus.

---
*Lié : `docs/audits/2026-06-05-C1-rgpd-deletion-C2-refund.md` (C-2 remboursements,
même problématique de sortie d'argent manuelle traçable).*
