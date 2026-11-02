---
name: orkyn-verification
description: Procédure de vérification des modifications - découvrir les commandes de test/lint/typecheck du projet, exécuter les vérifications pertinentes, interpréter honnêtement les résultats. Utiliser après toute modification de code ou pour valider un livrable.
---

# Vérification des modifications

## 1. Découvrir les commandes (ne pas deviner)
- Node : `scripts` de `package.json`. Utilise le gestionnaire du lockfile : `pnpm-lock.yaml` → pnpm, `yarn.lock` → yarn, `bun.lock`/`bun.lockb` → bun, sinon npm.
- Python : `pyproject.toml` (pytest, ruff, mypy). Rust : `cargo test` / `cargo clippy`. Go : `go test ./...` / `go vet ./...`.
- Sinon : `Makefile`, `CLAUDE.md`, ou le workflow CI (`.github/workflows/*`), à lire seulement.

## 2. Exécuter par cercles
1. Typecheck et lint sur les fichiers touchés, ou sur le projet si c'est rapide.
2. Les tests qui couvrent le changement (fichier de test ou filtre par nom).
3. La suite complète, si elle est raisonnablement rapide ou si le brief l'exige.
4. Le build, si le changement touche la config, les imports, les types exportés ou les dépendances.

Évite les commandes qui ont des effets externes : déploiement, migration distante, envoi de mails, tests e2e sur la production. Si le seul test disponible en a, demande l'accord au coordinateur via ton rapport.

## 3. Interpréter
- Recopie la commande et le résumé réel (ex. `42 passed, 1 failed`), pas une paraphrase.
- Un test en échec **déjà présent avant ton changement** est signalé comme préexistant. Rôles en lecture seule : signale « préexistant probable », ou compare via `git worktree add /tmp/<dossier>` sur le commit précédent. Seul le developer peut utiliser `git stash`, avec précaution (restaure ensuite avec `git stash pop`).
- Ne modifie jamais un test pour le faire passer, sauf si le test est faux et que tu le justifies.
- Une absence de tests est un constat à rapporter, pas une réussite.
