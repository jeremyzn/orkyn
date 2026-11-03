# Sous-commandes textuelles

Ces sous-commandes sont des arguments du skill `/orkyn`. Ce ne sont pas des commandes CLI natives de Claude Code.

## help

Affiche ceci (adapté, concis) :

```
ORKYN, orchestration multi-agents (skill Claude Code)

Une seule commande : /orkyn suivi de ce que vous voulez, avec vos mots.

  /orkyn ajoute la connexion avec Google        Code, bug, fonctionnalité, question
  /orkyn trouve les failles de mon projet       Audit de sécurité et corrections
  /orkyn ajoute un écran de profil à mon appli  Android, iOS, Flutter, React Native, Expo
  /orkyn fais un jeu d'obby                     Jeu Roblox
  /orkyn lis mes mails                          Boîte mail en lecture seule
  /orkyn état                                   Équipe, mémoire, projet détecté
  /orkyn aide                                   Cette aide

Pilote automatique : aucune question pendant le travail. Les actions importantes
(mettre en ligne, publier, supprimer, dépenser) sont préparées et regroupées à la fin
pour votre accord.
Sécurité : passe automatique à chaque changement sensible
Niveau : léger, standard ou approfondi, choisi automatiquement pour chaque mission
Roblox : pour l'instant, uniquement dans une session Vibe Starter (automatique). Ailleurs, fichiers seulement
Mails : fournisseur, adresse et mot de passe d'application à renseigner dans la configuration du plugin (README)
Natif : /agents (gérer les agents) · /tasks (agents en cours) · /memory
```

## status

À partir du contexte injecté (n'invente rien de plus) :

- Agent Teams : activées ou non. Si non, indique comment les activer (voir `agent-teams.md`) sans modifier les réglages.
- Agents ORKYN installés.
- Mémoire : quels agents ont une mémoire pour ce projet ou au niveau utilisateur, et sa taille (politique : `memory-policy.md`). Si l'utilisateur le demande, résume le contenu en lisant les `MEMORY.md`.
- Contexte projet : dépôt git, branche, fichiers modifiés, stack et plateforme mobile détectées, outils présents (et scanners de sécurité manquants utiles pour cette stack).
- Agents en cours : renvoie vers `/tasks`. Tu ne connais que les agents lancés dans **cette** session.

## agents

Construis le tableau depuis le contexte injecté (agents, modèles) et `agent-selection.md` (rôle, accès en écriture). Lis les fichiers d'agent (dossier `agents/` du plugin, chemin dans le contexte injecté ou sous `~/.claude/plugins/cache/orkyn/`) seulement si l'utilisateur demande les skills ou la mémoire d'un agent : le frontmatter fait foi. Colonnes : agent, rôle (1 ligne), modèle, écriture (oui/non). Pour `orkyn-mobile`, rappelle : jamais de publication sur les stores, build iOS seulement sur macOS, émulateur seulement si un AVD existe. Pour `orkyn-security`, rappelle : lecture seule, n'installe aucun scanner, ne lit jamais la valeur d'un secret. Pour `orkyn-roblox`, rappelle ses prérequis : session Vibe Starter (sinon fichiers seulement), pas de publication, garde-fou `studio-guard.sh` (filet, pas garantie). Pour `orkyn-inbox`, rappelle : lecture seule, uniquement via `/orkyn inbox`, prérequis : mails configurés dans le plugin (`inbox.md`). Pour ajouter un agent, renvoie à `agent-selection.md` (section « Ajouter un spécialiste »).
