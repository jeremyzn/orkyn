#!/usr/bin/env bash
# ORKYN : lectures de fichiers (Read, Grep) des agents orkyn-*, appelé par guard.sh.
# Usage : secret-guard.sh   (entrée JSON du hook sur stdin)
# Bloque (exit 2) la lecture d'un fichier de secrets (voir is_secret_path dans lib.sh) : un agent n'a jamais
# besoin de la valeur d'un secret. Pour savoir quelles variables existent, il lit le modèle (.env.example)
# ou liste les noms avec une commande qui masque les valeurs.
# Entrée illisible : laisse passer (une lecture ne modifie rien, et les permissions Claude Code s'appliquent).
# FILET DE SÉCURITÉ, PAS UNE GARANTIE : Bash reste capable de lire un fichier (bash-guard.sh couvre les
# lecteurs courants). Non garanti pour les coéquipiers d'Agent Team.
input=$(cat)
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
for k in file_path path notebook_path; do
  p=$(json_str "$input" tool_input "$k") || exit 0
  [ -n "$p" ] || continue
  if is_secret_path "$p"; then
    echo "ORKYN : lecture refusée sur $p (fichier de secrets). Lis le modèle (.env.example) ou seulement les noms des variables, jamais les valeurs." >&2
    exit 2
  fi
done
exit 0
