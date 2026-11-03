---
name: orkyn-debugging
description: Procédure de débogage méthodique : reproduire, isoler, identifier la cause racine, corriger minimalement, prouver la correction par un test. Utiliser pour tout bug, erreur, test en échec ou comportement inattendu.
---

# Débogage méthodique

1. **Reproduire** : obtiens l'échec avec une commande ou un test précis et note la sortie exacte. Si c'est impossible, dis-le et liste ce qui manque.
2. **Consulter la mémoire** : ce piège a peut-être déjà été rencontré dans ce projet.
3. **Isoler** : lis la stack trace en partant du bas, dans le code du projet. Réduis le cas : dernier changement (`git log -p`, `git diff`), entrées minimales, bisection si nécessaire.
4. **Hypothèses** : formule-en au plus 3, classées par probabilité. Pour chacune, prévois l'observation qui la confirme ou la réfute, et teste-la. Ne corrige pas à l'aveugle.
5. **Cause racine** : explique *pourquoi* le bug se produit, pas seulement où. Un symptôme masqué (try/catch silencieux, valeur par défaut) n'est pas une correction.
6. **Corriger minimalement**, dans le style du fichier. Pas de refactor opportuniste.
7. **Prouver** : ajoute ou adapte un test qui échouait avant et passe après, quand le projet a des tests. Relance aussi les tests voisins.
8. **Mémoriser**, si c'est durable : `[fait] symptôme → cause → correction`.

Après 3 hypothèses réfutées, arrête-toi et rapporte : les observations, les pistes restantes et ce qu'il faudrait pour avancer.
