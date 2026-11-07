# Orchestration détaillée

## Brief de délégation (obligatoire)

Un sous-agent ne voit pas la conversation. Il ne connaît que ton brief. Chaque appel Agent contient :

```
Mission ORKYN : <rôle attendu>
Date du jour : <AAAA-MM-JJ, depuis le contexte injecté>
Objectif : <résultat concret attendu : les 3 phrases du filtre Règle>
Contexte : <ce qui est établi : fichiers clés, décisions, résultats d'autres agents (résumés, pas recopiés)>
Périmètre : <fichiers/dossiers que tu peux modifier, ou « lecture seule »>
Hors périmètre : <ce qu'il ne faut pas toucher>
Critères de réussite : <comment on saura que c'est fait, par exemple commande de test à faire passer>
Niveau : <léger|standard|approfondi>, <conséquence concrète, ex. « tests ciblés uniquement »>
Autonomie : pilote automatique, aucune question. Cherche ce qui manque (sources web du mois courant en priorité, datées). Hypothèse prudente et réversible plutôt que blocage. Action réservée : prépare la commande et rapporte la.
Outils présents : <liste du contexte injecté, utile aux agents mobile et security>
Autorisations accordées par l'utilisateur : <aucune | liste exacte, ex. « commit local »>
Déjà fait : <ce que tu as lu ou vérifié, pour qu'il ne le refasse pas>
Retour : format de rapport orkyn-protocol, 250 mots max, sans recopier de code ni de logs.
```

Le brief est court et précis : les faits utiles, pas la conversation recopiée. Chaque chemin et chaque ligne que tu donnes est une exploration que l'agent n'a pas à refaire.

- Utilise `subagent_type: orkyn:orkyn-<rôle>`.
- **N'attribue pas de `name` à un appel Agent hors Agent Team** : quand les Agent Teams sont activées, un appel nommé crée un coéquipier au lieu d'un sous-agent.
- `model` et `effort` par appel selon le niveau choisi (voir SKILL.md §2).
- N'utilise pas de fork (appel Agent sans `subagent_type`) pour un travail de spécialiste : un fork hérite de toute ta conversation et coûte plus cher.
- Pour une correction ou une suite, continue l'agent qui a fait le travail (SendMessage avec son identifiant, sans `name`) : il garde son contexte. Un nouvel appel Agent repart de zéro.
- Les sous-agents lancés depuis la session principale tournent en arrière-plan : tu es notifié à leur fin. Pour une tâche dépendante, attends cette notification. N'invente jamais un résultat en attente.

## Dépendances et fichiers

- Ordonne les tâches : conception → implémentation → validation. Une tâche ne démarre que si ses entrées existent.
- Avant de paralléliser des agents qui écrivent, attribue à chacun une liste de fichiers **disjointe**. Si c'est impossible, exécute en séquence.
- Une isolation en worktree (`isolation: worktree`) n'est utile que pour des développements parallèles risqués au niveau approfondi, dans un dépôt git. Tu dois ensuite rapatrier les changements toi-même et le signaler.

## Supervision et boucle de correction

1. Lis le rapport de l'agent. Vérifie au moins une affirmation clé toi-même : relance le test, lis le diff.
2. Si QA ou Reviewer signale un problème **étayé** (fichier:ligne, reproduction, sortie de test), renvoie un brief de correction ciblé au developer avec ces éléments, en continuant l'agent existant si possible. Une correction d'une ou deux lignes, fais-la toi-même.
3. Si un agent contredit un autre, tranche sur les preuves techniques et non sur l'ordre d'arrivée. QA peut contredire le developer : c'est attendu.
4. Nombre de cycles maximum : voir SKILL.md §2. Au-delà, arrête et présente le blocage à l'utilisateur avec les options. Pas de boucle infinie.
5. Un agent qui atteint `maxTurns` renvoie un résultat marqué partiel. Ne le considère pas comme terminé : reprends-le avec SendMessage si la suite en vaut la peine, sinon signale-le.

## Validation finale

- Tests pertinents : ceux qui couvrent le changement, puis la suite complète seulement si le niveau est approfondi ou si elle tient en moins d'une minute. Ne relance pas un test qu'un agent vient de faire passer si tu as lu sa sortie et le diff : relance celui qui porte l'affirmation clé.
- Linter et typecheck s'ils existent dans le projet (scripts de `package.json`, `Makefile`, etc.).
- Dans le rapport, sépare **vérifié** (commande exécutée + résultat observé) et **déclaré** (ce qu'un agent affirme sans que tu l'aies revérifié).

## Agent Teams

Voir [agent-teams.md](agent-teams.md).
