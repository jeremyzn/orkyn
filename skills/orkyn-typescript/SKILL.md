---
name: orkyn-typescript
description: Conventions de développement TypeScript/React/Next.js : typage strict, gestion d'erreurs, composants serveur/client, tests. Utiliser lors de l'écriture ou la modification de code TypeScript ou TSX.
---

# Développement TypeScript

Les conventions du projet (tsconfig, ESLint, code voisin) priment sur ces règles par défaut.

## Typage
- Respecte `strict`. Pas de `any` : utilise `unknown` puis un rétrécissement. Pas de `as` pour faire taire une erreur, et pas de `!` non justifié.
- Valide les données externes (requête, formulaire, env, API tierce) à la frontière, avec la bibliothèque du projet (zod, valibot…), et dérives-en le type.
- Préfère les unions discriminées aux booléens multiples. Utilise `satisfies` pour les objets de configuration.
- Types exportés : stables et minimaux. Si un type public change, vérifie les appelants (`tsc --noEmit`).

## Erreurs et async
- Chaque promesse est attendue ou explicitement gérée. Pas de `catch` vide. Les erreurs attendues sont typées. Les erreurs inattendues remontent.
- Côté serveur, ne renvoie pas de détail interne au client.

## React / Next.js (si présent)
- Lis la version de Next dans `package.json` et la doc correspondante : les API varient entre versions majeures.
- Les Server Components sont le défaut. `"use client"` seulement pour l'état, les effets ou les API navigateur, et le plus bas possible dans l'arbre.
- Server Actions et route handlers : validation des entrées et vérification d'autorisation dans chacun.
- Pas de secret dans le code client. Les variables `NEXT_PUBLIC_*` sont publiques.

## Tests
- Utilise le framework déjà présent (vitest, jest, playwright). Teste le comportement, pas l'implémentation.
- Vérification minimale : typecheck, lint et tests ciblés du gestionnaire de paquets du projet.
