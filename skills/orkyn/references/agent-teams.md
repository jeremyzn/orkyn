# Agent Teams

Les Agent Teams (expérimental) sont un mécanisme **différent** des sous-agents. Les coéquipiers sont des instances indépendantes, avec une liste de tâches partagée et une messagerie directe entre eux. Les sous-agents, eux, ne parlent qu'à toi.

## Dépendance aux hooks

Les garde-fous ORKYN sont des hooks de plugin (`guard.sh`, qui appelle `memory-guard.sh`, `bash-guard.sh`, et `secret-guard.sh`) qui ne sont **pas garantis** pour les coéquipiers : sans eux, rien ne bloque techniquement une écriture ou une commande destructive. D'où :

- Agent Teams seulement sur demande explicite de l'utilisateur. Chaque coéquipier est une instance complète qui charge CLAUDE.md, MCP et skills : la doc officielle des coûts indique environ 7 fois plus de tokens qu'une session normale.
- rappelle aux coéquipiers en lecture seule qu'ils ne doivent rien modifier.

## Conditions cumulatives

1. Le contexte injecté indique Agent Teams **activées**. Elles exigent aussi une session interactive : avec `claude -p`, aucun coéquipier n'est créé.
2. L'utilisateur a explicitement demandé une équipe dans cette conversation. Le niveau approfondi ne suffit pas.
3. La mission a besoin d'**échanges réels** entre spécialistes, par exemple :
   - débogage par hypothèses concurrentes qui se réfutent mutuellement.
   - fonctionnalité transverse (front, back, tests) sur des fichiers disjoints, avec un contrat d'interface à négocier.
   - revue contradictoire où plusieurs angles se challengent.

Sinon : sous-agents classiques.

## Mise en œuvre

- Taille de l'équipe : 2 coéquipiers par défaut, 3 au maximum (chaque coéquipier consomme comme une session complète).
- Lance chaque coéquipier avec l'outil Agent, un `name` explicite (ex. `dev-api`) et `subagent_type: orkyn:orkyn-<rôle>`, pour qu'il reprenne les outils, le modèle et le prompt de cet agent.
- Pas de `TeamCreate` : avec la variable activée, chaque session a une équipe implicite, et un appel Agent avec `name` y ajoute un coéquipier.
- Limites documentées : le champ `skills` n'est pas appliqué aux coéquipiers, et ni la mémoire ni les `hooks` (dont `memory-guard.sh` et `bash-guard.sh`) ne leur sont garantis. Dans le prompt de lancement :
  - demande-leur d'invoquer le skill `orkyn-protocol` et leur skill métier.
  - transmets les extraits pertinents de la mémoire.
  - rappelle explicitement aux rôles en lecture seule qu'ils ne doivent pas modifier le projet.
- Crée des tâches partagées avec dépendances, environ 5 à 6 tâches par coéquipier, et attribue des fichiers disjoints.
- Tu restes le lead : tu centralises la validation finale, tu tranches les désaccords sur preuves et tu exécutes les tests toi-même.
- En fin de mission, demande aux coéquipiers de s'arrêter et vérifie qu'ils sont inactifs. Limites : `/resume` ne restaure pas les coéquipiers en mode in-process, et une seule équipe est possible par session.

## Si les Agent Teams sont désactivées

Utilise les sous-agents et relaie toi-même les découvertes de l'un vers le brief de l'autre. Ne simule pas de conversation entre agents.

## Activation (à proposer, jamais à appliquer sans accord)

Ajouter dans `~/.claude/settings.json` :

```json
{ "env": { "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1" } }
```

Effet de bord documenté : une fois la fonctionnalité activée, tout appel Agent avec un `name` crée un coéquipier, et Claude peut en créer sans qu'on le lui demande. Optionnel : `"teammateMode": "auto"` pour des panneaux séparés sous tmux ou iTerm2.
