---
name: orkyn-security
description: Procédure ORKYN interne : audit de sécurité (secrets, dépendances, code, mobile, IA, CI) et corrections.
user-invocable: false
---

# Audit de sécurité

Tout se fait sans poser de question. Ce qui manque (outil, information) est contourné et signalé, jamais demandé.

## 1. Délimiter
- **Diff** (passe de sécurité en fin de mission) : `git diff` et `git diff --cached`, plus les manifestes et lockfiles modifiés. Rapide : secrets du diff, dépendances ajoutées, revue manuelle des lignes changées.
- **Projet entier** (audit demandé) : toutes les couches de la section 2.
- Stack et outils présents : contexte injecté par le coordinateur, sinon `command -v <outil>`. Ne lance que les couches qui concernent la stack.

## 2. Couches, dans cet ordre
Pour chaque couche : l'outil s'il est présent (commandes dans [references/tools.md](references/tools.md)), sinon la revue manuelle indiquée. Rapports dans le dossier temporaire, jamais dans le dépôt.

1. **Secrets** : gitleaks, betterleaks ou trufflehog avec masquage, sur les fichiers puis sur l'historique git. À défaut : `git ls-files` des fichiers sensibles (`.env`, `*.pem`, `*.jks`, `key.properties`, `*.p8`, `google-services.json` avec clés serveur), vérification du `.gitignore`, recherche par motifs (`AKIA`, `sk_live_`, `ghp_`, `xox`, `-----BEGIN`, `AIza`) avec `grep -rnoE` qui n'affiche que le motif, jamais la ligne entière. Côté client : variables `NEXT_PUBLIC_`, `EXPO_PUBLIC_`, `VITE_`, constantes dans le code mobile.
2. **Dépendances** : audit natif du gestionnaire (`npm audit --json`, `pnpm audit --json`, `pip-audit`, `cargo audit`, `govulncheck`), osv-scanner pour tout le reste (Gradle, Pub, CocoaPods, SwiftPM). Puis la chaîne d'approvisionnement : [references/supply-chain.md](references/supply-chain.md).
3. **Code** : Semgrep ou Opengrep (`--metrics=off`, règles du registre seulement si l'outil est déjà configuré, sinon règles par défaut), Bandit pour Python, gosec pour Go, mobsfscan pour Android et iOS. Puis **toujours** une revue manuelle des zones sensibles avec [references/standards.md](references/standards.md) : un scanner ne voit pas un contrôle d'accès manquant.
4. **Mobile** (si détecté) : checklist MASVS de [references/standards.md](references/standards.md).
5. **IA et agents** (si le projet appelle un modèle, expose des outils ou un serveur MCP) : checklist LLM et agents de [references/standards.md](references/standards.md).
6. **Configuration et CI** : Trivy config ou Checkov (IaC, Kubernetes), hadolint (Dockerfile), zizmor et actionlint (`.github/workflows`). À défaut, revue manuelle : `pull_request_target`, `${{ github.event.* }}` dans un `run:`, actions non épinglées par SHA, permissions trop larges, secrets dans les logs.

## 3. Valider chaque constat
- Ouvre le fichier et la ligne. Un résultat de scanner non relu n'est pas un constat.
- Faux positif (code de test, donnée factice, chemin inatteignable) : écarte-le et note la raison en mémoire.
- Une dépendance vulnérable compte si la fonction vulnérable est utilisée ou atteignable (govulncheck le dit pour Go). Sinon, P3.
- Paquet malveillant (identifiant `MAL-` d'OSV) ou secret réel dans l'historique : toujours P0, même sans preuve d'exploitation.

## 4. Prioriser
| Priorité | Critère | Traitement par le coordinateur |
|---|---|---|
| **P0** | Secret réel exposé, paquet malveillant, faille au catalogue CISA KEV, contrôle d'accès ou injection exploitable sans authentification | Correction immédiate et automatique. La révocation d'un secret est une action de l'utilisateur, à signaler en tête du rapport. |
| **P1** | EPSS ≥ 0,1, CVSS 4.0 critique ou élevé avec chemin atteignable, faille exploitable par un utilisateur authentifié | Correction automatique dans la mission |
| **P2** | Faille réelle mais exploitation difficile, durcissement important (en-têtes, cookies, CORS, ATS, `cleartextTraffic`) | Correction automatique si le changement est local et réversible |
| **P3** | Défense en profondeur, dépendance vulnérable non atteignable, bonne pratique | Signalé, corrigé seulement si trivial |

EPSS et KEV se consultent par CVE si le réseau est disponible (voir tools.md). Sans réseau, classe sur CVSS et atteignabilité, et note « EPSS non consulté ».

## 5. Corrections prêtes à appliquer
Pour chaque constat, la correction minimale exacte : fichier, avant et après, ou la commande (montée de version précise, pas « mettre à jour »). Indique **auto** si un agent développeur peut l'appliquer sans décision humaine, **utilisateur** sinon (révoquer une clé, réécrire l'historique git, changer de fournisseur, mise à jour majeure cassante).

## 6. Livrable
```
| Prio | Catégorie | Fichier:ligne | Faille et preuve | Correction | Auto |
```
Puis : **Outils lancés** (commande et résultat), **Outils manquants** (avec la commande d'installation pour l'utilisateur), **Données envoyées à l'extérieur** (ex. noms et versions de paquets à osv.dev) ou « aucune », **Couches non couvertes** et pourquoi, et le verdict.
