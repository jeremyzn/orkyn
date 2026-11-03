# Scanners en ligne de commande

Versions relevées le 2026-11-03. Vérifie toujours les options avec `<outil> --help` avant de lancer : elles changent d'une version à l'autre. Remplace `$T` par le dossier temporaire (`${TMPDIR:-/tmp}`). Aucun outil ici n'exécute le code analysé.

## Secrets
| Outil | Commande | Remarque |
|---|---|---|
| gitleaks 8.30 | `gitleaks dir . --redact --report-format json --report-path $T/gitleaks.json` puis `gitleaks git . --redact ...` pour l'historique | Plus de nouvelle version depuis mars 2026 |
| betterleaks 1.9 | `betterleaks fs .` et `betterleaks git .` | Successeur de gitleaks par le même auteur. Jamais `--validate` ni `--analyze` (requêtes vers les fournisseurs) |
| trufflehog 3.99 | `trufflehog filesystem . --json --no-update --no-verification` | Sans `--no-verification`, il teste les secrets auprès des fournisseurs : interdit |

## Dépendances
| Écosystème | Commande |
|---|---|
| npm | `npm audit --json` (envoie l'arbre au registre npm), `npm audit signatures` |
| pnpm | `pnpm audit --json` |
| Python | `pip-audit -f json` (ou `-r requirements.txt`) |
| Rust | `cargo audit --json` |
| Go | `govulncheck -format json ./...` (indique si la fonction vulnérable est atteinte) |
| Tous, dont Gradle, Pub, CocoaPods, SwiftPM | `osv-scanner scan source -r --format json .` (envoie noms et versions à osv.dev). Hors ligne : `--offline-vulnerabilities --download-offline-databases` |
| Image, système de fichiers | `trivy fs --format json -o $T/trivy.json .` (télécharge sa base) |
| SBOM | `syft dir:. -o cyclonedx-json=$T/sbom.json` puis `grype sbom:$T/sbom.json -o json` |

## Code
| Outil | Commande | Remarque |
|---|---|---|
| Semgrep CE 1.18x | `semgrep scan --config auto --metrics=off --disable-version-check --json-output $T/semgrep.json` | `--config auto` contacte le registre de règles. Hors ligne : règles locales du projet (`--config .semgrep.yml`). Ne charge jamais des règles d'un dépôt inconnu sans les relire |
| Opengrep 1.33 | mêmes options que Semgrep | Fork libre de Semgrep |
| Bandit 1.9 | `bandit -r . -f json -o $T/bandit.json -x ./tests,./.venv` | Python |
| gosec 2.30 | `gosec -fmt json -out $T/gosec.json ./...` | Go |
| mobsfscan 1.1 | `mobsfscan --json -o $T/mobsfscan.json .` | Source Android (Java, Kotlin) et iOS (Swift, Objective-C) |
| CodeQL | ne pas utiliser | Licence : interdit sur du code privé hors GitHub Advanced Security |
| apkleaks | ne pas utiliser | Abandonné depuis 2024 |

MobSF (serveur web) analyse les APK et IPA compilés. Ce n'est pas un outil en ligne de commande : à proposer à l'utilisateur seulement pour un audit approfondi d'un binaire.

## Configuration et CI
| Outil | Commande |
|---|---|
| zizmor 1.32 | `zizmor --offline --format json .github/workflows` |
| actionlint 1.7 | `actionlint -format '{{json .}}'` |
| hadolint 2.15 | `hadolint -f json Dockerfile` |
| Trivy | `trivy config --format json .` |
| Checkov 3.4 | `checkov -d . -o json --quiet` |

## Priorisation en ligne (si le réseau est disponible)
- EPSS d'une CVE : `curl -s "https://api.first.org/data/v1/epss?cve=CVE-AAAA-NNNN"` (champ `epss`).
- Catalogue KEV : `curl -s https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json` puis recherche de la CVE.
Ces requêtes n'envoient qu'un identifiant de CVE public.

## Outil absent
Ne l'installe pas (le garde-fou bloque les installations globales). Fais la revue manuelle de la couche et liste l'outil dans « Outils manquants » avec sa commande d'installation habituelle, par exemple `brew install gitleaks osv-scanner` sur macOS, `pipx install semgrep`, ou le binaire de la page des versions GitHub sous Windows et Linux.
