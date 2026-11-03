# Chaîne d'approvisionnement

État au 2026-11-03. Les vers npm de la famille Shai-Hulud ont touché des centaines de paquets en 2026, parfois publiés **avec une provenance valide** depuis un workflow de release compromis : la provenance ne prouve pas l'absence de code malveillant.

## À vérifier dans le projet
- **Lockfile** présent et commité. Installation figée en CI : `npm ci`, `pnpm install --frozen-lockfile`, `yarn install --immutable`, `flutter pub get --enforce-lockfile`.
- **Scripts d'installation** : npm 12 les désactive par défaut et les autorise paquet par paquet (`allow-scripts` dans `package.json`, `npm approve-scripts`). Avant npm 12 : `ignore-scripts=true` dans le `.npmrc` du projet. pnpm : `strictDepBuilds` et la liste `allowBuilds` (ou `onlyBuiltDependencies` selon la version). Toute liste d'autorisation trop large est un constat.
- **Délai de quarantaine** des nouvelles versions : pnpm `minimumReleaseAge` (en minutes, 10080 pour 7 jours), npm `min-release-age` (en jours, depuis npm 11.10). Recommandé : au moins 1 jour, 7 pour un projet sensible.
- **Nouvelle dépendance** ajoutée par la mission ou récemment : le paquet existe-t-il vraiment, depuis quand, combien de téléchargements, nom proche d'un paquet connu (typosquatting), nom inventé par une IA (slopsquatting) ? `npm view <paquet> time.created maintainers repository`. Un paquet créé il y a quelques jours, sans dépôt source, ou absent du registre est P0.
- **Versions non figées** vers des sources exotiques : dépendances `git+`, URL de tarball, `latest`, `*`.
- **GitHub Actions** : actions tierces épinglées par SHA complet, pas par tag, `permissions:` minimales, pas de `pull_request_target` qui exécute le code de la PR.
- **Mobile** : dépôts Gradle limités (`google()`, `mavenCentral()`), pas de `jcenter()` ni de dépôt HTTP, vérification des dépendances Gradle (`gradle/verification-metadata.xml`) pour un projet sensible, CocoaPods en maintenance (préférer Swift Package Manager), versions de pods et de paquets Pub épinglées par le lockfile.
- **Serveurs MCP et extensions** déclarés dans le projet (`.mcp.json`, `.vscode/extensions.json`) : source connue et version épinglée.

## Corrections automatiques possibles
Ajouter `ignore-scripts` ou `minimumReleaseAge`, épingler une action par SHA, monter une version corrigée **mineure ou correctif** précise, retirer une dépendance inutilisée. Une montée de version majeure, un changement de gestionnaire ou une réécriture d'historique reviennent à l'utilisateur.
