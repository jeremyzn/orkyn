#!/usr/bin/env bash
# ORKYN : écriture de fichiers (Write|Edit|NotebookEdit) des agents orkyn-*, appelé par guard.sh.
# Usage : memory-guard.sh <readonly|write> <nom-agent>   (entrée JSON du hook sur stdin)
# Le dossier de mémoire d'un agent de plugin s'appelle orkyn-<nom-agent> (ex. orkyn-orkyn-qa) ; le nom nu reste admis.
#  - tous modes : bloque (exit 2) les fichiers de configuration (settings, .mcp.json, ~/.claude.json,
#    tout ~/.claude/ hors la mémoire utilisateur de l'agent) et la mémoire des autres agents ;
#  - tous modes : une écriture dans .claude/agent-memory-local/ garantit un .gitignore ("*") ;
#  - readonly : n'autorise que la mémoire de l'agent et les dossiers temporaires ; fail-closed
#    (exit 2) si l'entrée est illisible ;
#  - write : si l'entrée est illisible, laisse passer (les permissions Claude Code décident).
# Filet de sécurité, pas une garantie : non garanti pour les coéquipiers d'Agent Team.
mode="${1:-readonly}"
agent="${2:-}"

fail() {
  [ "$mode" = "readonly" ] || exit 0
  echo "ORKYN : écriture refusée (entrée du hook illisible ou parseur absent) — rôle en lecture seule." >&2
  exit 2
}

input=$(cat)
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
raw=$(json_str "$input" tool_input file_path) || fail
[ -n "$raw" ] || raw=$(json_str "$input" tool_input notebook_path) || fail
[ -n "$raw" ] || fail
raw=$(to_unix_path "$raw")

# Chemin canonique, même si le fichier n'existe pas : résout liens et « .. » composant par composant.
norm() {
  local p="$1" cur="" c cand link
  case "$p" in "~/"*) p="$HOME/${p#\~/}";; /*) ;; *) p="$PWD/$p";; esac
  set -f
  local IFS=/
  for c in $p; do
    case "$c" in
      ""|.) ;;
      ..) cur="${cur%/*}" ;;
      *)
        cand="$cur/$c"
        if [ -d "$cand" ]; then cur=$(cd "$cand" && pwd -P)
        elif [ -L "$cand" ]; then
          link=$(readlink "$cand"); case "$link" in /*) ;; *) link="$cur/$link";; esac
          cur=$(norm "$link")
        else cur="$cand"; fi ;;
    esac
  done
  printf '%s\n' "${cur:-/}"
}

target=$(norm "$raw")
home=$(cd "$HOME" 2>/dev/null && pwd -P || printf '%s' "$HOME")
# Windows : système de fichiers insensible à la casse, on compare tout en minuscules.
if is_windows; then
  target=$(printf '%s' "$target" | tr '[:upper:]' '[:lower:]')
  home=$(printf '%s' "$home" | tr '[:upper:]' '[:lower:]')
fi
lower=$(printf '%s' "$target" | tr '[:upper:]' '[:lower:]')
homel=$(printf '%s' "$home" | tr '[:upper:]' '[:lower:]')

block_config() {
  echo "ORKYN : écriture refusée sur $target — fichier de configuration : action réservée au coordinateur après accord de l'utilisateur." >&2
  exit 2
}

case "$lower" in
  */.claude/settings.json|*/.claude/settings.local.json|*/.mcp.json|"$homel/.claude.json") block_config ;;
  "$homel/.claude/"*) case "$target" in "$home/.claude/agent-memory/$agent/"*|"$home/.claude/agent-memory/orkyn-$agent/"*) ;; *) block_config ;; esac ;;
esac

case "$target" in
  */.claude/agent-memory-local/"$agent"/*|*/.claude/agent-memory-local/"orkyn-$agent"/*)
    root="${target%%/.claude/agent-memory-local/*}/.claude/agent-memory-local"
    if [ ! -f "$root/.gitignore" ]; then mkdir -p "$root" && printf '*\n' > "$root/.gitignore"; fi
    exit 0 ;;
  */.claude/agent-memory/"$agent"/*|*/.claude/agent-memory/"orkyn-$agent"/*) exit 0 ;;
  */.claude/agent-memory/*|*/.claude/agent-memory-local/*)
    echo "ORKYN : écriture refusée sur $target — mémoire d'un autre agent." >&2
    exit 2 ;;
esac

[ "$mode" = "readonly" ] || exit 0

case "$target" in
  /tmp/*|/var/tmp/*|/private/tmp/*|/private/var/folders/*|/var/folders/*|*/appdata/local/temp/*) exit 0 ;;
esac
for t in "${TMPDIR:-}" "${TEMP:-}" "${TMP:-}"; do
  [ -n "$t" ] || continue
  t=$(norm "$(to_unix_path "$t")")
  is_windows && t=$(printf '%s' "$t" | tr '[:upper:]' '[:lower:]')
  [ "$t" != "/" ] && [ "$t" != "$home" ] || continue
  case "$target" in "$t"/*) exit 0 ;; esac
done
echo "ORKYN : écriture refusée sur $target — cet agent est en lecture seule sur le projet (seule sa mémoire d'agent ou un dossier temporaire est autorisé). Décris la modification dans ton rapport." >&2
exit 2
