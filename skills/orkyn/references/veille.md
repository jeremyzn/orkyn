# Veille du projet

Intention : « veille », « quoi de neuf », « vérifie les mises à jour », « surveille mes dépendances ». Niveau standard. But : savoir ce qui a changé autour du projet depuis la dernière fois, et préparer les corrections, sans rien casser.

## Ce que la veille vérifie (dans cet ordre, en shell, sorties tronquées)

1. **Failles dans les dépendances** : audit natif du gestionnaire (`npm audit --json`, `pnpm audit --json`, `pip-audit`, `cargo audit`, `govulncheck ./...`), sinon `osv-scanner` s'il est présent. Une faille listée au catalogue KEV de la CISA ou un paquet malveillant (`MAL-`) est P0.
2. **Versions majeures en retard** : `npm outdated --json`, `pnpm outdated`, `pip list --outdated`, `cargo outdated` si présent, `flutter pub outdated`. Rien n'est mis à jour à ce stade.
3. **État de la CI** : `gh run list --limit 5` si `gh` est connecté.
4. **Règles des stores** (projet mobile seulement) : une recherche web datée du mois courant sur les nouvelles exigences App Store et Google Play.
5. **Mémoire** : la date et le résumé de la dernière veille sont dans la mémoire de `orkyn-security` si elle existe. Ne refais pas ce qui n'a pas bougé.

## Ce que la veille fait ensuite

- Failles P0 à P2 avec correctif sans rupture (version de correctif ou mineure) : correction appliquée dans le projet par le développeur de la stack, tests ciblés, puis passe de sécurité sur le diff. C'est une corvée.
- Versions majeures, changements cassants, ajout ou retrait de dépendance : rien n'est appliqué. Une ligne par mise à jour dans « À valider par vous », avec le lien du changelog et le risque.
- Rapport court : ce qui a changé, ce qui est corrigé, ce qui attend l'utilisateur.

## Veille automatique chaque semaine (filtre R✓)

Si l'utilisateur demande une veille régulière (« chaque semaine », « automatise la veille »), ou si une veille révèle des problèmes deux fois de suite, prépare la planification. Elle s'installe hors du projet, donc elle va dans « À valider par vous », jamais appliquée seule :

- **Dans le cloud** (machine éteinte possible, dépôt GitHub requis, clone neuf à chaque fois) : l'utilisateur tape `/schedule chaque lundi à 9h : /orkyn veille du dépôt <owner/repo>, corrige les failles sans rupture sur une branche orkyn/veille et ouvre une PR en brouillon`.
- **Sur sa machine** (app Claude Desktop, fichiers locaux) : Planification, nouvelle tâche hebdomadaire, dossier du projet, invite `/orkyn veille`.

Une commande intégrée comme `/schedule` se tape par l'utilisateur : tu donnes la ligne exacte, tu ne prétends pas l'avoir lancée.
