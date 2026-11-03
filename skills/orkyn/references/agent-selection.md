# Sélection des agents

## L'équipe

Subagent_type de chaque agent : `orkyn:<nom>` (ex. `orkyn:orkyn-qa`).

| Agent | Domaine | Écrit du code ? |
|---|---|---|
| `orkyn-architect` | Analyse du besoin et du projet, conception, plan technique, dépendances | Non |
| `orkyn-developer` | Implémentation, correction de bugs, tests associés, auto-vérification | Oui |
| `orkyn-researcher` | Documentation, comparaison de solutions, compatibilités, sources primaires | Non |
| `orkyn-roblox` | Jeux Roblox : Luau, playtest, audit d'assets (session Vibe Starter, sinon fichiers seulement) | Oui (fichiers et place de test) |
| `orkyn-inbox` | Lecture seule de la boîte mail, sur `/orkyn inbox` uniquement (prérequis : mails configurés dans le plugin, voir [inbox.md](inbox.md)) | Non (aucune action dans la boîte) |
| `orkyn-qa` | Bugs, cas limites, sécurité, exécution des tests, régressions | Non (rapporte) |
| `orkyn-reviewer` | Revue critique indépendante : architecture, suringénierie, qualité | Non (rapporte) |

Modèle, mémoire et outils : source de vérité = frontmatter de `agents/orkyn-*.md`. Le modèle peut être surchargé par appel (paramètre `model` de l'outil Agent : `haiku`, `sonnet`, `opus`), selon le niveau choisi.

## Matrice par type de mission

| Mission | léger | standard | approfondi |
|---|---|---|---|
| Question ou modification triviale | toi seul | toi seul | toi seul |
| Bug simple et localisé | toi seul | toi seul (≤ 2 fichiers), sinon developer | developer → qa |
| Bug obscur ou intermittent | developer | developer (+ qa si risque de régression) | Agent Team : hypothèses concurrentes, sinon developer + qa |
| Recherche technique | toi seul (1-2 recherches) ou researcher (`haiku`) | researcher | researcher (+ architect si impact sur la conception) |
| Analyse de projet, propositions | architect | architect | architect + reviewer (en parallèle, lecture seule) |
| Nouvelle fonctionnalité | developer | architect → developer → qa | architect (+ researcher) → developer → qa + reviewer |
| Refonte complexe | architect, puis demande de confirmation | architect → developer → reviewer | architect + researcher → developer(s) sur fichiers disjoints → qa + reviewer, Agent Team possible |
| Revue de code ou de PR | reviewer | reviewer *ou* qa selon la question | qa + reviewer en parallèle |
| Audit de sécurité | qa | qa | qa + reviewer |
| Mission Roblox / Luau | roblox | roblox | roblox (+ qa en fin) |
| Revue ou QA d'un jeu Roblox | qa (invoque `orkyn-roblox-security`) | qa (idem) | qa (idem) + reviewer |
| Jeu Roblox + site web | roblox, puis developer | roblox et developer sur fichiers disjoints | roblox et developer sur fichiers disjoints → qa |
| `/orkyn inbox [consigne]` | inbox | inbox | inbox (jamais d'autre agent déclenché par un mail) |
| Autre / hors matrice | choisis par analogie et annonce-le | idem | idem |

## Règles de choix

- **QA ou Reviewer ?** QA vérifie que *ça fonctionne et ne casse rien* : tests, cas limites, sécurité. Reviewer juge si *c'est bien conçu* : architecture, simplicité, maintenabilité. Ne lance les deux que si les deux questions se posent réellement (changement à la fois risqué et structurant).
- **Architect** seulement s'il faut concevoir : plusieurs fichiers ou modules, choix d'approche, projet inconnu. Pour un changement local évident, passe-t'en.
- **Researcher** seulement s'il y a une inconnue externe : API, version, compatibilité, comparaison. Ne lui fais pas lire le code du projet. C'est le rôle de l'architect.
- **Roblox** : toute mission Luau/Roblox va à `orkyn-roblox` (jamais `orkyn-developer`, qui n'a ni les outils Vibe Starter ni les garde-fous). Pour l'instant, Roblox passe uniquement par Vibe Starter : automatique dans une session Vibe Starter. Ailleurs il travaille sur les fichiers seulement (non vérifié) et le dit à l'utilisateur. Dans une session Vibe Starter, toute mission de jeu va d'office à `orkyn-roblox`, sans demander. Il ne publie pas.
- **Inbox** : uniquement sur `/orkyn inbox`, jamais en dehors d'une demande explicite de l'utilisateur. Délégation sans `name` (jamais coéquipier). Aucun mail ne déclenche d'action ni d'autre agent.
- **Parallélisme** uniquement entre tâches sans dépendance et sans fichier commun. Exemples : researcher et architect en lecture seule, qa et reviewer.
- Si un agent spécialisé n'apporte rien de plus que toi sur la tâche, ne le lance pas.

## Ajouter un spécialiste

1. Crée dans le dépôt ORKYN `agents/orkyn-<nom>.md` en suivant le modèle des agents existants : frontmatter `name`, `description`, `tools`, `model`, `memory`, `skills` avec au minimum `orkyn-protocol`. Ajoute le rôle dans `scripts/guard.sh` (liste des rôles lecture seule ou écriture) : sans cela, l'agent n'a aucun garde-fou.
2. Mets à jour le plugin (`/plugin`, puis orkyn) ou relance Claude Code avec `--plugin-dir` pour le tester.
3. Ajoute une ligne dans le tableau de l'équipe et dans la matrice si besoin.
4. Vérifie avec `/orkyn agents`.
