---
name: orkyn-code-review
description: Procédure de revue de code d'un diff, d'une PR ou d'un module (correction, sécurité, cas limites, conception, simplicité), avec constats vérifiés et classés par sévérité. Utiliser pour relire des modifications ou auditer du code.
---

# Revue de code

## 1. Délimiter
- Ce qui a changé : `git diff` (non indexé + indexé) ou `git diff <base>...HEAD`, ou les fichiers indiqués dans le brief.
- Lis le contexte autour de chaque changement (appelants, types, tests). Un diff seul ne suffit pas pour juger.

## 2. Examiner selon la lentille de ton rôle
**Correction** (QA en priorité) : logique, conditions aux limites (vide, null, 0, négatif, très grand, unicode), erreurs et chemins d'échec, concurrence et état partagé, async non attendu, compatibilité avec les appelants existants.

**Sécurité** : voir [security.md](security.md). À appliquer quand le changement touche des entrées utilisateur, l'authentification, des fichiers, des requêtes, du HTML ou des secrets.

**Conception** (Reviewer en priorité) : cohérence avec l'architecture et les conventions, responsabilités claires, duplication, suringénierie (abstraction prématurée, configuration inutile, couches sans valeur), lisibilité, testabilité.

## 3. Vérifier avant d'affirmer
Chaque constat doit reposer sur une preuve : une ligne précise, un scénario concret, une commande exécutée ou un test qui échoue. Ce qui ne peut pas être prouvé est classé « à confirmer ». Pas de constat stylistique si un linter du projet le couvre déjà.

## 4. Livrable
```
| Sévérité | Fichier:ligne | Constat | Scénario d'échec / preuve | Correction proposée |
```
Sévérités : **bloquant** (bug, faille, perte de données) · **important** (régression probable, dette réelle) · **mineur**. Termine par un verdict : `OK`, `OK avec réserves` ou `À corriger`. Si rien n'est trouvé, dis-le : ne fabrique pas de constats.
