# ORKYN — Sous-commandes textuelles

Ces sous-commandes sont des arguments du skill `/orkyn`. Ce ne sont pas des commandes CLI natives de Claude Code.

## help

Affiche ceci (adapté, concis) :

```
ORKYN — orchestration multi-agents (skill Claude Code)

  /orkyn <mission>              Lance une mission dans le mode courant
  /orkyn eco: <mission>         Mission ponctuelle en mode eco (idem balanced:, deep:)
  /orkyn status                 Mode, Agent Teams, mémoire des agents, contexte projet
  /orkyn agents                 Équipe disponible (rôle, modèle, mémoire, skills)
  /orkyn inbox [consigne]       Lit la boîte mail (lecture seule) et trie/signale
  /orkyn mode                   Affiche le mode courant et sa source
  /orkyn mode eco|balanced|deep Change le mode par défaut (utilisateur)
  /orkyn mode deep project      Mode spécifique au projet courant (.claude/orkyn.json)
  /orkyn mode clear             Supprime le mode spécifique au projet
  /orkyn help                   Cette aide

Modes : eco = économie de quota · balanced = défaut · deep = analyse approfondie
Roblox : pour l'instant, uniquement dans une session Vibe Starter (automatique) ; ailleurs, fichiers seulement
Mails : fournisseur, adresse et mot de passe d'application à renseigner dans la configuration du plugin (README)
Natif : /agents (gérer les agents) · /tasks (agents en cours) · /memory
```

## status

À partir du contexte injecté (n'invente rien de plus) :

- Mode effectif et sa source.
- Agent Teams : activées ou non. Si non, indique comment les activer (voir `agent-teams.md`) sans modifier les réglages.
- Agents ORKYN installés.
- Mémoire : quels agents ont une mémoire pour ce projet ou au niveau utilisateur, et sa taille (politique : `memory-policy.md`). Si l'utilisateur le demande, résume le contenu en lisant les `MEMORY.md`.
- Contexte projet : dépôt git, branche, fichiers modifiés, stack détectée.
- Agents en cours : renvoie vers `/tasks`. Tu ne connais que les agents lancés dans **cette** session.

## agents

Construis le tableau depuis le contexte injecté (agents, modèles) et `agent-selection.md` (rôle, accès en écriture). Lis les fichiers d'agent (dossier `agents/` du plugin, chemin dans le contexte injecté ou sous `~/.claude/plugins/cache/orkyn/`) seulement si l'utilisateur demande les skills ou la mémoire d'un agent : le frontmatter fait foi. Colonnes : agent, rôle (1 ligne), modèle, écriture (oui/non). Pour `orkyn-roblox`, rappelle ses prérequis : session Vibe Starter (sinon fichiers seulement), pas de publication, garde-fou `studio-guard.sh` (filet, pas garantie). Pour `orkyn-inbox`, rappelle : lecture seule, uniquement via `/orkyn inbox`, prérequis : mails configurés dans le plugin (`inbox.md`). Pour ajouter un agent, renvoie à `agent-selection.md` (section « Ajouter un spécialiste »).

## mode

`bash ${CLAUDE_SKILL_DIR}/../../scripts/set-mode.sh [eco|balanced|deep|clear] [project]`

- Sans argument : affiche le mode courant et sa source.
- Mode sans `project` : écrit `~/.claude/orkyn/config.json` (défaut pour tous les projets).
- Mode avec `project` : écrit `<projet>/.claude/orkyn.json`, qui est prioritaire pour ce projet.
- `clear` : supprime le réglage projet.

Confirme la sortie du script telle quelle.
