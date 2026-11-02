# Outillage Luau (état 2026, à confirmer par `--version`)

| Outil | Rôle | Commande type |
|---|---|---|
| Rokit (1.2.0) | gestionnaire d'outils, lit `rokit.toml` | `rokit list` |
| Rojo (7.7.1) | sync fichiers ↔ jeu, `sourcemap` | `rojo sourcemap default.project.json -o sourcemap.json` |
| Wally / pesde | paquets (`wally.toml` / `pesde.toml`) | installation = ajout de dépendance : accord requis |
| StyLua (2.6.0) | format | `stylua --check src` |
| Selene (0.32.0) | lint | `selene src` |
| luau-lsp (1.70.1) | analyse de types | `luau-lsp analyze --sourcemap=sourcemap.json --definitions=<globalTypes.d.luau> src` |
| Lune (0.11.1) | exécution Luau hors du jeu, tests de logique pure | `lune run <script>` |

- `run-in-roblox` est abandonné : ne pas l'utiliser, passer par le playtest MCP.
- Les définitions de types Roblox pour luau-lsp sont téléchargées par l'outil ou fournies par le projet : ne les télécharge pas sans accord.
- Rokit installé sans outils : `rokit.toml` absent ou vide = aucun outil de vérification disponible ; rapporte-le.
- Vibe Starter : plugin de sync dérivé de Rojo, aucune doc publique ; ne suppose aucune API, travaille sur les fichiers du dossier de projet.
