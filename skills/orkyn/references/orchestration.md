# ORKYN — Orchestration détaillée

## Brief de délégation (obligatoire)

Un sous-agent ne voit pas la conversation. Il ne connaît que ton brief. Chaque appel Agent contient :

```
Mission ORKYN — <rôle attendu>
Objectif : <résultat concret attendu>
Contexte : <ce qui est établi : fichiers clés, décisions, résultats d'autres agents (résumés, pas recopiés)>
Périmètre : <fichiers/dossiers que tu peux modifier — ou « lecture seule »>
Hors périmètre : <ce qu'il ne faut pas toucher>
Critères de réussite : <comment on saura que c'est fait — ex. commande de test à faire passer>
Mode : <eco|balanced|deep> — <conséquence concrète, ex. « tests ciblés uniquement »>
Autorisations accordées par l'utilisateur : <aucune | liste exacte, ex. « commit local »>
Retour : format de rapport orkyn-protocol.
```

- Utilise `subagent_type: orkyn:orkyn-<rôle>`.
- **N'attribue pas de `name` à un appel Agent hors Agent Team** : quand les Agent Teams sont activées, un appel nommé crée un coéquipier au lieu d'un sous-agent.
- `model` et `effort` par appel selon le mode (voir SKILL.md §2).
- N'utilise pas de fork (appel Agent sans `subagent_type`) pour un travail de spécialiste : un fork hérite de toute ta conversation et coûte plus cher.
- Les sous-agents lancés depuis la session principale tournent en arrière-plan : tu es notifié à leur fin. Pour une tâche dépendante, attends cette notification. N'invente jamais un résultat en attente.

## Dépendances et fichiers

- Ordonne les tâches : conception → implémentation → validation. Une tâche ne démarre que si ses entrées existent.
- Avant de paralléliser des agents qui écrivent, attribue à chacun une liste de fichiers **disjointe**. Si c'est impossible, exécute en séquence.
- Une isolation en worktree (`isolation: worktree`) n'est utile que pour des développements parallèles risqués en mode deep, dans un dépôt git. Tu dois ensuite rapatrier les changements toi-même et le signaler.

## Supervision et boucle de correction

1. Lis le rapport de l'agent. Vérifie au moins une affirmation clé toi-même : relance le test, lis le diff.
2. Si QA ou Reviewer signale un problème **étayé** (fichier:ligne, reproduction, sortie de test), renvoie un brief de correction ciblé au developer avec ces éléments.
3. Si un agent contredit un autre, tranche sur les preuves techniques et non sur l'ordre d'arrivée. QA peut contredire le developer : c'est attendu.
4. Nombre de cycles maximum : voir SKILL.md §2. Au-delà, arrête et présente le blocage à l'utilisateur avec les options. Pas de boucle infinie.
5. Un agent qui atteint `maxTurns` renvoie un résultat partiel. Signale-le, et ne le considère pas comme terminé.

## Validation finale

- Tests pertinents : ceux qui couvrent le changement, puis la suite complète si elle est rapide ou si le mode est deep.
- Linter et typecheck s'ils existent dans le projet (scripts de `package.json`, `Makefile`, etc.).
- Dans le rapport, sépare **vérifié** (commande exécutée + résultat observé) et **déclaré** (ce qu'un agent affirme sans que tu l'aies revérifié).

## Agent Teams

Voir [agent-teams.md](agent-teams.md).
