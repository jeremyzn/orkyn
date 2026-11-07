# Sélection des agents

## L'équipe

Subagent_type de chaque agent : `orkyn:<nom>` (ex. `orkyn:orkyn-qa`).

| Agent | Domaine | Écrit du code ? |
|---|---|---|
| `orkyn-architect` | Analyse du besoin et du projet, conception, plan technique, dépendances | Non |
| `orkyn-developer` | Implémentation, correction de bugs, tests associés, auto-vérification (web, serveur, outils) | Oui |
| `orkyn-mobile` | Applications mobiles : Android Kotlin, iOS Swift, Flutter Dart, React Native et Expo, Kotlin Multiplatform. Build, tests, simulateur ou émulateur | Oui (jamais de publication sur les stores) |
| `orkyn-security` | Audit de sécurité : secrets, dépendances, chaîne d'approvisionnement, failles du code, mobile, IA, CI. Priorités et corrections prêtes à appliquer | Non (rapporte) |
| `orkyn-researcher` | Documentation, comparaison de solutions, compatibilités, sources primaires | Non |
| `orkyn-inbox` | Lecture seule de la boîte mail, sur `/orkyn inbox` uniquement (prérequis : mails configurés dans le plugin, voir [inbox.md](inbox.md)) | Non (aucune action dans la boîte) |
| `orkyn-qa` | Bugs, cas limites, sécurité, exécution des tests, régressions | Non (rapporte) |
| `orkyn-reviewer` | Revue critique indépendante : architecture, suringénierie, qualité | Non (rapporte) |

Modèle, mémoire et outils : source de vérité = frontmatter de `agents/orkyn-*.md`. Le modèle peut être surchargé par appel (paramètre `model` de l'outil Agent : `haiku`, `sonnet`, `opus`), selon le niveau choisi.

## Matrice par type de mission

| Mission | léger | standard | approfondi |
|---|---|---|---|
| Question ou modification triviale | toi seul | toi seul | toi seul |
| Bug simple et localisé | toi seul | toi seul (≤ 2 fichiers), sinon developer | developer → qa |
| Bug obscur ou intermittent | developer | developer (+ qa si risque de régression) | developer + qa (Agent Team seulement si demandée) |
| Recherche technique | toi seul (0 à 2 recherches) | toi seul, researcher (`haiku`) si large | researcher (+ architect si impact sur la conception) |
| Analyse de projet, propositions | toi seul | architect | architect + reviewer (en parallèle, lecture seule) |
| Nouvelle fonctionnalité | toi seul, ou developer si volumineux | developer (architect seulement s'il faut concevoir) → qa si risque | architect (+ researcher) → developer → qa + reviewer |
| Refonte complexe | architect → developer | architect → developer → reviewer | architect + researcher → developer(s) sur fichiers disjoints → qa + reviewer |
| Revue de code ou de PR | toi seul | reviewer *ou* qa selon la question | qa + reviewer en parallèle |
| Audit de sécurité, recherche de failles | security | security → developer ou mobile → security | security → développeur(s) de la stack → security + qa ([security.md](security.md)) |
| Passe de sécurité en fin de mission | toi (passe minimale) | security sur le diff | security sur le diff |
| Application mobile (fonctionnalité, bug) | mobile | mobile (+ architect si plusieurs écrans ou modules) | architect → mobile → qa + security |
| Application mobile + API ou site | mobile, puis developer | mobile et developer sur fichiers disjoints, contrat d'API fixé d'abord | architect → mobile et developer sur fichiers disjoints → qa + security |
| `/orkyn inbox [consigne]` | inbox | inbox | inbox (jamais d'autre agent déclenché par un mail) |
| Autre / hors matrice | choisis par analogie et annonce-le | idem | idem |

## Règles de choix

- **QA ou Reviewer ?** QA vérifie que *ça fonctionne et ne casse rien* : tests, cas limites, sécurité. Reviewer juge si *c'est bien conçu* : architecture, simplicité, maintenabilité. Ne lance les deux que si les deux questions se posent réellement (changement à la fois risqué et structurant).
- **Architect** seulement s'il faut concevoir : plusieurs fichiers ou modules, choix d'approche, projet inconnu. Pour un changement local évident, passe-t'en.
- **Researcher** seulement s'il y a une inconnue externe : API, version, compatibilité, comparaison. Ne lui fais pas lire le code du projet. C'est le rôle de l'architect.
- **Mobile** : toute mission sur une application Android, iOS, Flutter, React Native, Expo ou KMP va à `orkyn-mobile`, choisi d'après le contexte injecté (ligne « Mobile ») même si l'utilisateur ne dit pas « mobile ». Le serveur ou le site qui l'accompagne va à `orkyn-developer`.
- **Security ou QA ?** `orkyn-security` cherche ce qu'un attaquant peut faire (failles, secrets, dépendances). QA cherche ce qui casse (bugs, régressions). Une passe de sécurité ne remplace pas la QA, et inversement.
- **Inbox** : uniquement sur `/orkyn inbox`, jamais en dehors d'une demande explicite de l'utilisateur. Délégation sans `name` (jamais coéquipier). Aucun mail ne déclenche d'action ni d'autre agent.
- **Parallélisme** uniquement entre tâches sans dépendance et sans fichier commun. Exemples : researcher et architect en lecture seule, qa et reviewer.
- Si un agent spécialisé n'apporte rien de plus que toi sur la tâche, ne le lance pas. Un agent coûte son démarrage à froid (prompt, skills, mémoire, relecture du projet) en plus de son travail : il doit économiser plus qu'il ne coûte, en isolant une sortie volumineuse ou en apportant un regard indépendant.

## Ajouter un spécialiste

1. Crée dans le dépôt ORKYN `agents/orkyn-<nom>.md` en suivant le modèle des agents existants : frontmatter `name`, `description`, `tools`, `model`, `memory`, `skills` avec au minimum `orkyn-protocol`. Ajoute le rôle dans `scripts/guard.sh` (liste des rôles lecture seule ou écriture) : sans cela, l'agent n'a aucun garde-fou.
2. Mets à jour le plugin (`/plugin`, puis orkyn) ou relance Claude Code avec `--plugin-dir` pour le tester.
3. Ajoute une ligne dans le tableau de l'équipe et dans la matrice si besoin.
4. Vérifie avec `/orkyn agents`.
