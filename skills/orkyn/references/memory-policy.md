# ORKYN — Politique de mémoire

La mémoire ORKYN repose sur le champ natif `memory` des sous-agents. L'« adaptation » d'ORKYN, c'est la relecture de notes persistantes. Ce n'est pas un réentraînement du modèle.

## Scopes par agent

| Agent | Scope | Emplacement | Pourquoi |
|---|---|---|---|
| orkyn-architect | `project` | `<projet>/.claude/agent-memory/orkyn-orkyn-architect/` | Décisions d'architecture validées, à versionner avec le code |
| orkyn-developer | `local` | `<projet>/.claude/agent-memory-local/orkyn-orkyn-developer/` | Conventions, pièges et corrections propres au projet, non versionnés |
| orkyn-qa | `local` | `<projet>/.claude/agent-memory-local/orkyn-orkyn-qa/` | Zones fragiles et régressions récurrentes du projet |
| orkyn-researcher | `user` | `~/.claude/agent-memory/orkyn-orkyn-researcher/` | Connaissances techniques valables d'un projet à l'autre |
| orkyn-reviewer | `user` | `~/.claude/agent-memory/orkyn-orkyn-reviewer/` | Standards de qualité et préférences de revue de l'utilisateur |

Le dossier d'un agent de plugin est `<plugin>-<agent>` (vérifié : `orkyn-orkyn-<rôle>`). Pour changer un scope, modifie le champ `memory:` du fichier de l'agent.

## Fonctionnement natif

- Les 200 premières lignes (ou 25 Ko) de `MEMORY.md` sont injectées dans le prompt de l'agent à chaque lancement.
- Read, Write et Edit sont activés automatiquement pour gérer ce dossier.
- Claude Code n'ajoute **pas** automatiquement `.claude/agent-memory-local/` au `.gitignore` (vérifié). Le garde-fou `memory-guard.sh` (appelé par `guard.sh`) crée `.claude/agent-memory-local/.gitignore` (contenu `*`) à la première écriture, et `context.sh` signale un dossier qui n'en a pas.
- Le scope `project` (architect) crée `.claude/agent-memory/orkyn-orkyn-architect/` dans le dépôt de l'utilisateur : ce dossier est fait pour être versionné. Signale-le dans le rapport quand il est créé ou modifié.
- Garde-fou : `memory-guard.sh <readonly|write> <agent>` (via `guard.sh`) n'autorise l'écriture que dans la mémoire de l'agent concerné (jamais celle d'un autre agent) et bloque les fichiers de configuration ; en readonly (architect, researcher, qa, reviewer) il bloque aussi tout hors des dossiers temporaires. C'est un filet : Bash reste techniquement capable d'écrire (la règle du prompt et `bash-guard.sh` couvrent ce cas).
- Le champ est sans effet si l'auto-mémoire est désactivée (`autoMemoryEnabled: false` ou `CLAUDE_CODE_DISABLE_AUTO_MEMORY`).
- La mémoire n'est pas garantie pour les coéquipiers d'une Agent Team : le lead leur transmet les extraits utiles.

## Règles d'écriture

Consulter, n'écrire que le durable, pas de doublon, aucun secret, fait ou hypothèse, cloisonnement par projet, format des entrées : tout est défini dans `orkyn-protocol` (section Mémoire). Ne le recopie pas ici.

## Correction par l'utilisateur

Les fichiers sont du Markdown ordinaire, modifiable à la main. L'utilisateur peut aussi demander `/orkyn corrige la mémoire de <agent> : …` : délègue alors à l'agent concerné, ou édite toi-même le fichier.
