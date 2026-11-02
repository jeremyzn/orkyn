---
name: orkyn-research
description: Procédure de recherche technique - sources primaires, comparaison de solutions, vérification de compatibilité et de versions, niveau de certitude explicite. Utiliser pour une question sur une API, une bibliothèque, une version ou un choix technologique.
---

# Recherche technique

1. **Cadrer** : reformule la question en une phrase et dis ce qui permettra de trancher. Identifie les versions en jeu dans le projet (lockfile, `npm ls <pkg>`, `pip show`…) avant de chercher.
2. **Consulter la mémoire** : une conclusion récente et sourcée suffit peut-être. Ce qui est daté de plus de 6 mois et lié à une version doit être revérifié.
3. **Chercher sobrement** : 1 à 3 recherches ciblées, puis lecture des pages qui font foi. Ordre de confiance :
   1. documentation officielle de la version utilisée, changelog, notes de migration ;
   2. code source ou types du paquet installé (`node_modules/<pkg>`) ;
   3. issues et discussions du dépôt officiel ;
   4. articles tiers, seulement en dernier recours, et signalés comme tels.
4. **Comparer** (si plusieurs options) : tableau avec critères pertinents (compatibilité avec la stack, maintenance, poids, licence, coût de migration). Termine par une recommandation.
5. **Certitude** : chaque affirmation est classée *confirmée* (source citée), *probable* ou *non vérifiée*. Pas de version, d'option ou d'API inventée. « Je n'ai pas trouvé » est une réponse valide.

Livrable : réponse directe en 1 à 3 phrases, puis les éléments à l'appui avec leurs URL, puis les incertitudes. Mémorise les conclusions durables avec la version et la date.
