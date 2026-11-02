---
name: orkyn-architecture
description: Procédure d'analyse d'architecture d'un projet existant et de conception d'une solution maintenable avec plan technique par étapes. Utiliser avant une fonctionnalité multi-fichiers, une refonte ou pour auditer un projet.
---

# Analyse d'architecture et conception

## 1. Cartographier, au plus court
1. Lis les manifestes (`package.json`, `pyproject.toml`, …), `CLAUDE.md` et le README pour connaître la stack, les scripts et les conventions déclarées.
2. Structure : liste les dossiers de premier et deuxième niveau, puis repère les points d'entrée (routes, `main`, handlers).
3. Pour la zone concernée par la mission seulement : suis le flux de données de l'entrée à la persistance. Pas d'exploration exhaustive.
4. Conventions réelles : déduis-les de 2 ou 3 fichiers voisins (nommage, gestion d'erreurs, tests, imports), pas de la théorie.

## 2. Concevoir
- Commence par la solution la plus simple qui respecte les conventions existantes. Propose une alternative seulement si le compromis est réel.
- Identifie les dépendances : modules touchés, contrats d'interface, migrations de données, configuration, ordre de mise en œuvre.
- Identifie les risques : régression, sécurité, performance, compatibilité.
- Refuse la suringénierie : pas d'abstraction sans au moins deux usages concrets, pas de nouvelle dépendance si la stack couvre déjà le besoin.

## 3. Livrable
```
### Constat (existant pertinent, conventions)
### Solution proposée (+ alternative écartée et pourquoi)
### Plan par étapes
| # | Étape | Fichiers | Dépend de | Validation |
### Risques et points ouverts
```
Chaque étape doit pouvoir être exécutée par un développeur sans relire tout le projet. Indique des fichiers précis, pas « le backend ».
