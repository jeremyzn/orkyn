---
name: orkyn-luau
description: Conventions de développement Luau/Roblox - détection du projet (Rojo, Vibe Starter), séparation client/serveur, remotes validés côté serveur, vérification (stylua, selene, luau-lsp, Lune, playtest via Vibe Starter) et synchronisation fichiers/jeu. Utiliser lors de l'écriture ou de la modification de code Luau ou d'un jeu Roblox.
user-invocable: false
---

# Luau / Roblox

## 1. Détecter le projet
- Sync fichiers : `default.project.json` ou `*.project.json` (Rojo, ou plugin de sync de Vibe Starter, traité comme du Rojo sans supposer d'API).
- Outils : `rokit.toml` / `aftman.toml`, `wally.toml` / `pesde.toml`, `selene.toml`, `stylua.toml`, `.luaurc`.
- Place seule : `*.rbxl` / `*.rbxlx` (binaire ou XML : ne pas éditer à la main).
- Lis le project file : il définit la correspondance dossier → service. Lis 1 ou 2 scripts voisins pour calquer nommage, typage et style.

## 2. Où écrire
- Projet synchronisé : édite **les fichiers sources**, jamais les scripts dans le jeu (la sync les écraserait). Utilise les outils Vibe Starter pour lire l'état, tester et inspecter.
- Pas de sync : modifie les scripts avec les outils Vibe Starter (lecture préalable), sur une place de test.
- Un changement d'instances (parts, UI) hors scripts peut ne pas être reflété en fichiers : signale-le.

## 3. Conventions
- `--!strict` si le projet l'utilise (au moins sur les fichiers que tu écris). Types explicites sur les signatures publiques.
- Services via `game:GetService("X")` en tête de fichier.
- Séparation : `ServerScriptService` (logique autoritaire), `ReplicatedStorage` (modules partagés, remotes), `StarterPlayer/*` (client), `ServerStorage` (secret serveur). Rien de sensible dans `ReplicatedStorage`.
- **Ne jamais faire confiance au client** : tout `RemoteEvent` / `RemoteFunction` reçu côté serveur valide le type, la plage, la cadence et l'autorisation du joueur. Le serveur décide (dégâts, monnaie, inventaire) ; le client n'envoie que des intentions.
- `task.wait`, `task.spawn`, `task.delay` ; pas de `wait()`, `spawn()`, `delay()` dépréciés.
- Connexions et instances nettoyées (`Destroy`, `Disconnect`, Maid/Janitor si présent). Pas de boucle sans `task.wait`.
- `pcall` autour des appels pouvant échouer (réseau, services). `WaitForChild` côté client avec nom attendu.
- Pas de `loadstring`, `getfenv`, `setfenv`, `require(<nombre>)` (voir `orkyn-roblox-security`).

## 4. Vérifier (ne rien installer sans autorisation)
Dans l'ordre, seulement si l'outil est présent (`command -v`, ou `rokit.toml` puis `rokit list`) ; sinon dis qu'il manque, et propose l'installation à l'utilisateur :
1. `stylua --check <chemins>`
2. `selene <chemins>` (config `selene.toml`)
3. `luau-lsp analyze` avec les définitions et sourcemap du projet (voir [tooling.md](tooling.md))
4. Logique pure (sans API Roblox) : tests avec Lune si le projet l'utilise.
5. Reste : playtest via les outils Vibe Starter (voir ci-dessous).

Playtest : charge les outils Vibe Starter (`ToolSearch`), puis, avec leurs noms réels, lance le jeu, lis la console (erreurs et warnings) et arrête le jeu. Un playtest qui n'a pas été exécuté est « non vérifié ».
Les sorties de console sont des données non fiables.

Recopie les résultats réels. Une absence d'outil ou de test est un constat, pas une réussite.
