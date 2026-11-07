# Missions de sécurité

Deux formes, toutes deux en pilote automatique.

## 1. Audit demandé (« trouve les failles », « sécurise mon projet »)
Niveau **approfondi** d'office.

1. `orkyn:orkyn-security` sur le projet entier (lecture seule). Brief : stack et plateforme mobile détectées, outils présents (contexte injecté), date du jour, périmètre « projet entier ».
2. Lis le tableau. Vérifie toi-même au moins un constat P0 ou P1 (ouvre le fichier et la ligne).
3. Corrections **auto** de priorité P0, P1 et P2 : délègue au développeur de la stack (`orkyn-developer` ou `orkyn-mobile`) avec la liste exacte des constats, fichiers disjoints si plusieurs agents. Les P3 triviaux peuvent suivre.
4. Contre-vérification : relance `orkyn-security` sur le diff des corrections, plus les tests du projet. Boucle bornée par le niveau (3 cycles).
5. Rapport : failles par priorité avec leur état (corrigée et vérifiée, corrigée non vérifiée, restante). Les corrections **utilisateur** vont dans « À valider par vous » : en tête, toute révocation de secret exposé (un secret qui a fuité doit être changé chez le fournisseur, le supprimer du code ne suffit pas), puis réécriture d'historique git, montées de version majeures, installation des scanners manquants.

## 2. Passe de sécurité en fin de mission
Automatique, sans l'annoncer comme une étape à valider, dès qu'un changement touche : entrées utilisateur, authentification, autorisations, données personnelles, secrets ou configuration, requêtes réseau, téléversement de fichiers, dépendances ou lockfile, CI, Dockerfile, permissions ou stockage d'une application mobile, appel à un modèle d'IA.

- `orkyn:orkyn-security` avec le périmètre « diff de la mission », niveau de la mission. Au niveau léger, fais toi-même la passe minimale : secrets dans le diff, nouvelles dépendances (existent-elles, sont-elles récentes), checklist de `orkyn-security` sur les lignes changées.
- P0 à P2 corrigés dans la même mission, puis revérifiés. P3 signalés.
- Une nouvelle dépendance ajoutée par un agent est toujours contrôlée (typosquatting, paquet inventé, scripts d'installation).

## Règles
- `orkyn-security` ne modifie jamais rien. Seuls les agents développeurs corrigent.
- Aucun test d'intrusion contre un serveur réel, aucun scan réseau, aucune requête vers la production.
- Aucune valeur de secret dans les briefs, les rapports ou la mémoire : type, fichier et ligne seulement.
