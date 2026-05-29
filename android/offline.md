offline

Je veux que tu mettes en place un système de gestion OFFLINE-FIRST complet dans toute l'application.
Objectif principal :
L'application doit continuer à fonctionner même sans connexion Internet. Toutes les données déjà chargées doivent rester accessibles et visibles hors ligne, puis se synchroniser automatiquement dès que la connexion revient.
Exigences techniques :
1. Persistance locale globale

* Mettre en cache localement toutes les données critiques de l'application.
* Les données doivent rester disponibles après fermeture et réouverture de l'application.
* Utiliser une solution locale adaptée (SQLite, Hive, Isar ou mécanisme recommandé selon l'architecture existante).

2. Architecture Offline-First

* L'application doit lire prioritairement les données locales.
* Les requêtes réseau servent uniquement à synchroniser ou rafraîchir les données.
* Éviter la dépendance directe au serveur pour l'affichage de l'interface.

3. Gestion des états réseau
   Détecter automatiquement :

* connecté
* connexion lente
* hors ligne
* reconnexion

Mettre en place un NetworkManager ou service équivalent centralisé.

4. Cache intelligent des données
   Pour chaque module :

* sauvegarder les données après chargement réussi
* afficher automatiquement les données du cache si Internet est absent
* éviter les écrans vides ou erreurs inutiles

5. Synchronisation automatique
   Lors du retour d'Internet :

* relancer automatiquement la synchronisation
* récupérer les nouvelles données
* mettre à jour le cache local
* rafraîchir l'UI sans redémarrage de l'application

6. File d'attente des actions offline
   Les actions utilisateur effectuées hors ligne doivent être conservées localement :

* création
* modification
* suppression
* envoi de formulaires
* génération ou édition de factures

Créer une Sync Queue locale :

* stocker les actions en attente
* exécuter automatiquement à la reconnexion
* éviter la perte de données

7. Gestion des conflits
   Si une donnée est modifiée localement et également sur le serveur :

* implémenter une stratégie de résolution
* privilégier Last Write Wins ou proposer une méthode plus robuste si nécessaire
* documenter la logique choisie

8. Expérience utilisateur
   Ajouter :

* indicateur visuel Online / Offline
* message de synchronisation
* loader de sync discret
* feedback clair lorsque l'application travaille hors ligne

9. Robustesse

* éviter les crashes liés au réseau
* gérer timeouts et erreurs API
* prévoir retry automatique
* journaliser les erreurs importantes

10. Refactoring propre

* conserver l'architecture actuelle
* produire du code propre, modulaire et maintenable
* commenter les parties critiques
* éviter le code dupliqué

Livrables attendus :

* implémentation complète
* nouveaux services/classes créés
* explication du fonctionnement
* liste des fichiers modifiés
* schéma de flux Offline → Sync → Online
L'objectif final est que toute l'application fonctionne de manière fiable même sans Internet, avec synchronisation automatique et aucune perte de données.